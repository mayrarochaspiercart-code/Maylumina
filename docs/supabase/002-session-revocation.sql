-- ═══════════════════════════════════════════════════════════════════
-- MayLumina — 002 · Revogação imediata de sessão administrativa
--
-- NÃO edita a 001. A 001 já foi aplicada e continua valendo: esta
-- migration só endurece a função public.e_admin() e a policy de leitura
-- de public.admins. Nenhum dado é lido, alterado ou apagado.
--
-- ───────────────────────────────────────────────────────────────────
-- MOTIVO (medido em produção em 2026-09-12, sem alterar nada)
-- ───────────────────────────────────────────────────────────────────
-- Depois de POST /auth/v1/logout (inclusive com ?scope=global), o
-- access token JWT já emitido continuou funcionando:
--
--   POST /auth/v1/logout                      -> 204
--   PATCH /rest/v1/produtos  (token antigo)   -> 204   ← deveria negar
--   GET   /rest/v1/pedidos   (token antigo)   -> 200   ← deveria negar
--   GET   /rest/v1/admin_config (token antigo)-> 200   ← deveria negar
--   POST  /auth/v1/token?grant_type=refresh   -> 400 refresh_token_not_found
--
-- O JWT medido tem exp - iat = 3600s e traz o claim session_id. Ou
-- seja: quem tivesse copiado o token do navegador da May mantinha poder
-- administrativo por até uma hora depois de ela sair.
--
-- ───────────────────────────────────────────────────────────────────
-- COMPORTAMENTO DO SUPABASE (não é bug do projeto)
-- ───────────────────────────────────────────────────────────────────
-- O access token do Supabase é um JWT stateless: o PostgREST valida a
-- assinatura e o exp, e não pergunta ao banco se a sessão ainda existe.
-- signOut apaga a linha de auth.sessions e revoga os refresh tokens,
-- mas não tem como "desassinar" um token já emitido. Baixar o JWT
-- expiry encurta a janela; não a fecha.
--
-- ───────────────────────────────────────────────────────────────────
-- COMPORTAMENTO ANTERIOR  →  POSTERIOR
-- ───────────────────────────────────────────────────────────────────
-- ANTES : e_admin() = "auth.uid() está em public.admins".
--         Um token válido e não expirado bastava.
-- DEPOIS: e_admin() = "auth.uid() está em public.admins  E  o
--         session_id do JWT ainda é uma linha viva de auth.sessions
--         desse mesmo usuário".
--         Quando signOut apaga a sessão, a policy deixa de ser
--         satisfeita na requisição seguinte — sem esperar o exp.
--
-- Nada muda para o visitante: a policy "vitrine pública" não chama
-- e_admin(), então anon continua lendo produtos ativos igual.
--
-- ───────────────────────────────────────────────────────────────────
-- PRÉ-REQUISITO — LER ANTES DE APLICAR
-- ───────────────────────────────────────────────────────────────────
-- e_admin() é SECURITY DEFINER: ela roda com os privilégios do DONO da
-- função. E "create or replace function" NÃO troca o dono — ele fica
-- sendo quem criou a função na 001. Portanto o papel que interessa NÃO
-- é quem executa este arquivo: é pg_proc.proowner.
--
-- Esse dono precisa de duas coisas:
--
--   1. Ler auth.sessions (a tabela pertence a supabase_auth_admin). Sem
--      isso a função lança "permission denied for table sessions" e TODA
--      requisição administrativa vira erro: o painel tranca.
--
--   2. Escapar do RLS de public.admins, que e_admin() lê por dentro.
--      Se o dono estiver sujeito ao RLS dessa tabela há dois desfechos,
--      os dois fatais e os dois reproduzidos em ensaio:
--        * nenhuma policy de admins alcança o papel do dono (é o caso
--          aqui: a policy é TO authenticated e o dono não é
--          authenticated) → a leitura volta zero linhas e e_admin()
--          devolve false para sempre; o painel morre em silêncio;
--        * alguma policy alcança o papel do dono → ela chama e_admin(),
--          que lê admins de novo, e o Postgres aborta com "stack depth
--          limit exceeded".
--      O escape vale por superuser, por BYPASSRLS, ou por ter os
--      privilégios do dono da tabela com FORCE ROW LEVEL SECURITY
--      desligado.
--
-- E quem EXECUTA precisa de uma terceira: ter os direitos do dono, senão
-- o próprio "create or replace function" é recusado pelo Postgres.
--
-- A seção 0 confere as três coisas nos papéis certos e aborta a transação
-- inteira antes de qualquer alteração. A seção 3 vai além e EXECUTA a
-- função já com a policy nova no lugar, ainda dentro da transação — é a
-- prova que introspecção de catálogo não dá.
--
-- Para ver o diagnóstico sem aplicar nada, rode só isto no SQL Editor:
--
--   select r.rolname                                     as dono_da_funcao,
--          current_user                                  as quem_executa,
--          has_schema_privilege(r.rolname,'auth','USAGE')            as usa_auth,
--          has_table_privilege(r.rolname,'auth.sessions','SELECT')   as le_sessions,
--          ro.rolsuper                                   as dono_superuser,
--          ro.rolbypassrls                               as dono_bypassrls,
--          (select rr.rolname from pg_class c join pg_roles rr on rr.oid=c.relowner
--            where c.oid='public.admins'::regclass)      as dono_admins,
--          (select c.relforcerowsecurity from pg_class c
--            where c.oid='public.admins'::regclass)      as admins_force_rls,
--          pg_has_role(current_user, r.rolname, 'USAGE') as posso_substituir
--     from pg_proc p
--     join pg_namespace n on n.oid = p.pronamespace
--     join pg_roles     r on r.oid = p.proowner
--     join pg_roles    ro on ro.rolname = r.rolname
--    where n.nspname = 'public'
--      and p.proname = 'e_admin'
--      and pg_get_function_identity_arguments(p.oid) = '';
--
--   -- precisam voltar true: usa_auth, le_sessions, posso_substituir, e
--   -- pelo menos um entre (dono_superuser, dono_bypassrls, dono_admins =
--   -- dono_da_funcao com admins_force_rls = false).
--   -- Num projeto Supabase comum tudo isso e postgres e todas voltam true.
-- ═══════════════════════════════════════════════════════════════════

begin;

-- ───────────────────────────────────────────────────────────────────
-- 0. TRAVA DE SEGURANÇA — OLHANDO O PAPEL CERTO
--
--    create or replace function PRESERVA O DONO. Então quem executa
--    esta migration (current_user) não é necessariamente quem vai rodar
--    a e_admin() endurecida: SECURITY DEFINER roda como o DONO. Checar
--    current_user aqui seria checar o papel errado — e passar quando
--    devia abortar.
--
--    O dono real sai de pg_proc.proowner. Se a função ainda não existir
--    (instalação limpa), o dono será current_user, porque é ele que o
--    create vai registrar.
--
--    Quatro condições, todas sobre o DONO REAL:
--      a) USAGE no schema auth;
--      b) SELECT em auth.sessions;
--      c) escapar do RLS de public.admins. e_admin() lê essa tabela por
--         dentro; se o dono estiver sujeito ao RLS dela, quebra de um de
--         dois jeitos, ambos fatais: sem policy que alcance o papel do
--         dono, a leitura volta zero linhas e e_admin() fica false para
--         sempre (painel morto em silêncio); com policy que alcance, ela
--         chama e_admin() de novo e vira recursão. O escape vale por ser
--         superuser, por ter BYPASSRLS, ou por ter os privilégios do dono
--         da tabela COM force row level security desligado;
--      d) a leitura de verdade, provada na seção 3 depois que função e
--         policy já estão no lugar — introspecção pode mentir, executar
--         não.
-- ───────────────────────────────────────────────────────────────────
do $$
declare
  dono_fn    name;
  dono_tab   name;
  force_rls  boolean;
  eh_super   boolean;
  tem_bypass boolean;
  usa_auth   boolean;
  le_sessoes boolean;
  escapa_rls boolean;
  herda_dono boolean;
  nova       boolean := false;
begin
  -- (1) dono REAL de public.e_admin(), sem argumentos
  select r.rolname
    into dono_fn
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    join pg_roles     r on r.oid = p.proowner
   where n.nspname = 'public'
     and p.proname = 'e_admin'
     and pg_get_function_identity_arguments(p.oid) = '';

  if dono_fn is null then
    dono_fn := current_user;
    nova := true;
  end if;

  -- (2) dono de public.admins  e  (3) force row level security
  select r.rolname, c.relforcerowsecurity
    into dono_tab, force_rls
    from pg_class c
    join pg_roles r on r.oid = c.relowner
   where c.oid = 'public.admins'::regclass;

  -- (4) o que o DONO DA FUNÇÃO consegue
  select rolsuper, rolbypassrls
    into eh_super, tem_bypass
    from pg_roles where rolname = dono_fn;

  usa_auth   := has_schema_privilege(dono_fn, 'auth', 'USAGE');
  le_sessoes := has_table_privilege(dono_fn, 'auth.sessions', 'SELECT');
  herda_dono := pg_has_role(dono_fn, dono_tab, 'USAGE');
  escapa_rls := eh_super or tem_bypass or (not force_rls and herda_dono);

  raise notice '── PRE-CHECK 002 ──────────────────────────────────';
  raise notice 'quem executa (current_user) . : %', current_user;
  raise notice 'DONO de public.e_admin() .... : % %',
        dono_fn, case when nova then '(funcao ainda nao existe; sera este)' else '' end;
  raise notice 'dono de public.admins ...... : %', dono_tab;
  raise notice 'admins FORCE ROW LEVEL SEC . : %', force_rls;
  raise notice 'dono e superuser ........... : %', eh_super;
  raise notice 'dono tem BYPASSRLS ......... : %', tem_bypass;
  raise notice 'dono herda o dono da tabela  : %', herda_dono;
  raise notice 'dono tem USAGE em auth ..... : %', usa_auth;
  raise notice 'dono tem SELECT em sessions  : %', le_sessoes;
  raise notice 'dono escapa do RLS de admins : %', escapa_rls;
  raise notice '───────────────────────────────────────────────────';

  if not usa_auth then
    raise exception
      'ABORTADO: o DONO da funcao (%) nao tem USAGE no schema auth. '
      'A e_admin() endurecida nao conseguiria nem enxergar auth.sessions '
      'e toda requisicao administrativa viraria erro. Nada foi alterado. '
      '(quem executa esta migration e %, que nao e o papel que importa aqui)',
      dono_fn, current_user;
  end if;

  if not le_sessoes then
    raise exception
      'ABORTADO: o DONO da funcao (%) nao tem SELECT em auth.sessions. '
      'Como SECURITY DEFINER roda com os privilegios do dono, a e_admin() '
      'endurecida lancaria "permission denied for table sessions" em toda '
      'requisicao e o painel travaria. Nada foi alterado. '
      '(quem executa esta migration e %; checar ELE seria checar o papel errado)',
      dono_fn, current_user;
  end if;

  -- quem executa precisa dos direitos de dono para poder substituir a
  -- funcao; senao o create or replace falha com "must be owner of
  -- function e_admin" no meio do arquivo, em vez de recusar aqui com
  -- uma mensagem que explica o que fazer.
  if not pg_has_role(current_user, dono_fn, 'USAGE') then
    raise exception
      'ABORTADO: % nao tem os direitos de %, o dono de public.e_admin(), '
      'entao nao pode substitui-la. Rode esta migration como % (no SQL '
      'Editor do Supabase isso costuma ser o papel postgres) ou conceda '
      'a participacao: grant % to %. Nada foi alterado.',
      current_user, dono_fn, dono_fn, dono_fn, current_user;
  end if;

  if not escapa_rls then
    raise exception
      'ABORTADO: o DONO da funcao (%) esta sujeito ao RLS de public.admins '
      '(dono da tabela: %, force_rls: %, bypassrls: %, superuser: %). '
      'e_admin() le public.admins por dentro, entao isso quebra de um de '
      'dois jeitos, ambos fatais e ambos reproduzidos em ensaio: se '
      'nenhuma policy de admins alcancar o papel do dono, a leitura volta '
      'ZERO LINHAS e e_admin() passa a devolver false para sempre — o '
      'painel morre em silencio; se alguma policy alcancar (por exemplo '
      'uma policy TO public), ela chama e_admin(), que le admins de novo, '
      'e o Postgres aborta com "stack depth limit exceeded". '
      'Nada foi alterado.',
      dono_fn, dono_tab, force_rls, tem_bypass, eh_super;
  end if;
end
$$;

-- ───────────────────────────────────────────────────────────────────
-- 1. e_admin() PASSA A EXIGIR SESSÃO VIVA
--
--    search_path = '' : a função não resolve nome nenhum por conta
--    própria, então tudo aqui é qualificado. É mais estrito do que o
--    "= public" da 001 e fecha o sequestro por schema plantado.
--
--    O join é o coração: o session_id que veio dentro do JWT tem de
--    existir em auth.sessions E pertencer ao MESMO usuário do claim
--    sub. Um token cujo session_id foi apagado pelo signOut não casa
--    com nenhuma linha, e exists() devolve false.
--
--    O claim é conferido com regex ANTES do cast para uuid. Com
--    nullif(...,'')::uuid puro, um session_id malformado faz o cast
--    lançar 22P02 e a requisição vira erro 500 em vez de negação — no
--    ensaio, session_id = 'nao-e-uuid' derrubou a função. Só um JWT
--    assinado pelo projeto pode chegar aqui, então isso não é porta de
--    ataque; é higiene: com o regex, qualquer coisa que não seja um
--    uuid vira NULL, NULL não casa com nada, e a resposta é false —
--    falha fechada e silenciosa, do jeito certo. Claim ausente ou
--    vazio cai no mesmo caminho, e é por ele que anon e service_role,
--    que não têm session_id, recebem false.
--
--    not_after : o GoTrue preenche esta coluna quando as sessões são
--    limitadas no tempo. Fica NULL na configuração atual, então a
--    condição é inofensiva hoje e já cobre o dia em que deixar de ser.
-- ───────────────────────────────────────────────────────────────────
create or replace function public.e_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.admins a
      join auth.sessions s
        on s.user_id = a.user_id
     where a.user_id = auth.uid()
       and s.id = (
             case
               when auth.jwt() ->> 'session_id' ~*
                    '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
               then (auth.jwt() ->> 'session_id')::uuid
             end
           )
       and (s.not_after is null or s.not_after > now())
  );
$$;

-- Os privilégios da 001 são reafirmados: create or replace não os
-- redefine, mas repetir aqui deixa o arquivo autossuficiente.
revoke all on function public.e_admin() from public;
revoke all on function public.e_admin() from anon;
grant execute on function public.e_admin() to authenticated;

-- ───────────────────────────────────────────────────────────────────
-- 2. public.admins TAMBÉM EXIGE SESSÃO VIVA
--
--    A policy da 001 era só "user_id = auth.uid()", então um token
--    revogado ainda enxergava a própria linha de admin — pouca coisa,
--    mas é informação administrativa e ela some de graça.
--
--    Recursão: não há. e_admin() é SECURITY DEFINER e roda como dona
--    de public.admins; RLS não se aplica ao dono da tabela (a 001 não
--    usa FORCE ROW LEVEL SECURITY), então o select de dentro da função
--    não reavalia esta policy. Ensaiado em Postgres descartável antes
--    de chegar aqui; a seção 3 executa a função de verdade antes do commit e a 4.4 confere
--    de novo depois.
--
--    Continua sem INSERT/UPDATE/DELETE pelo cliente: a 001 concede
--    apenas SELECT em public.admins para authenticated, e esta
--    migration não mexe nesses grants.
-- ───────────────────────────────────────────────────────────────────
drop policy if exists "admin vê a si mesmo" on public.admins;

create policy "admin vê a si mesmo"
  on public.admins for select
  to authenticated
  using (user_id = auth.uid() and public.e_admin());

-- ───────────────────────────────────────────────────────────────────
-- 3. PROVA DE EXECUÇÃO — dentro da mesma transação
--
--    A seção 0 lê catálogo; catálogo pode estar certo e a execução ainda
--    falhar. Aqui a função é de fato EXECUTADA, já com a policy nova no
--    lugar, e o dono é posto à prova de duas maneiras.
--
--    (a) public.e_admin() sem JWT nenhum. Isso abre auth.sessions com os
--        privilégios do DONO: se ele não puder ler, estoura aqui e a
--        transação inteira volta atrás. Também é aqui que uma recursão
--        de policy apareceria, como "stack depth limit exceeded".
--        Sem JWT o resultado correto é false — auth.jwt() é null e o
--        exists() não casa com nada.
--
--    (b) contagem de public.admins vista POR DENTRO do papel do dono.
--        Isto existe porque (a) sozinha não bastaria: se o dono estiver
--        sujeito ao RLS de admins e nenhuma policy alcançar o papel
--        dele, a leitura volta zero linhas, e_admin() devolve false —
--        e (a) veria exatamente o false que esperava, aprovando uma
--        função que na prática nunca mais deixaria ninguém administrar
--        nada. Comparar o que o dono enxerga com o que existe fecha essa
--        brecha. A seção 0 já garantiu que quem executa tem os direitos
--        do dono, então o "set local role" abaixo é sempre possível.
-- ───────────────────────────────────────────────────────────────────
do $$
declare
  dono_fn   name;
  eu        name := current_user;
  r         boolean;
  existem   bigint;
  vistas    bigint;
begin
  select ro.rolname
    into dono_fn
    from pg_proc p
    join pg_namespace n  on n.oid = p.pronamespace
    join pg_roles     ro on ro.oid = p.proowner
   where n.nspname = 'public'
     and p.proname = 'e_admin'
     and pg_get_function_identity_arguments(p.oid) = '';

  -- (a) executar de verdade
  select public.e_admin() into r;
  if r is distinct from false then
    raise exception
      'ABORTADO: public.e_admin() devolveu % sem nenhum JWT; o esperado '
      'e false. Nada foi alterado.', coalesce(r::text, 'null');
  end if;

  -- (b) o dono enxerga as linhas de admins?
  select count(*) into existem from public.admins;

  execute format('set local role %I', dono_fn);
  select count(*) into vistas from public.admins;
  execute format('set local role %I', eu);

  if existem > 0 and vistas = 0 then
    raise exception
      'ABORTADO: o dono da funcao (%) enxerga 0 de % linhas de '
      'public.admins. e_admin() devolveria false para sempre e ninguem '
      'conseguiria administrar o site. Nada foi alterado.',
      dono_fn, existem;
  end if;

  if existem = 0 then
    raise notice 'AVISO: public.admins esta vazia, entao a prova (b) nao '
                 'tem o que comparar. Registre o admin e confira a secao 5.';
  end if;

  raise notice 'PROVA DE EXECUCAO: e_admin() sem JWT devolveu false, leu '
               'auth.sessions, nao recursou, e o dono (%) enxerga % de % '
               'linhas de public.admins. OK.', dono_fn, vistas, existem;
end
$$;

commit;

-- ═══════════════════════════════════════════════════════════════════
-- 4. VALIDAÇÃO — rodar logo depois, no mesmo SQL Editor
-- ═══════════════════════════════════════════════════════════════════

-- 4.1 A função tem o corpo novo? (tem de conter auth.sessions)
select p.proname,
       p.prosecdef                        as security_definer,
       p.proconfig                        as search_path,
       position('auth.sessions' in pg_get_functiondef(p.oid)) > 0 as exige_sessao
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public' and p.proname = 'e_admin';

-- 4.2 Quem pode executar e_admin()? (esperado: só authenticated)
select grantee, privilege_type
  from information_schema.routine_privileges
 where routine_schema = 'public' and routine_name = 'e_admin'
 order by grantee;

-- 4.3 As policies continuam sendo exatamente 7, e a de admins mudou?
select tablename, policyname, cmd, qual
  from pg_policies
 where schemaname = 'public'
 order by tablename, policyname;

-- 4.4 Prova de que não há recursão: isto tem de responder, não travar.
--     (como postgres, e_admin() devolve false porque não há JWT — o
--     que importa é que a consulta RETORNA em vez de estourar a pilha)
select public.e_admin() as e_admin_sem_jwt;

-- 4.5 Os dados continuam intactos (esperado: 2 / 0 / 0 / 1 / 1)
select 'produtos' as tabela, count(*) from public.produtos
union all select 'pedidos',      count(*) from public.pedidos
union all select 'pedido_itens', count(*) from public.pedido_itens
union all select 'admin_config', count(*) from public.admin_config
union all select 'admins',       count(*) from public.admins;

-- 4.6 Sessões vivas agora (cada login abre uma; signOut apaga)
select s.id as session_id, u.email, s.created_at, s.not_after
  from auth.sessions s
  join auth.users u on u.id = s.user_id
  join public.admins a on a.user_id = s.user_id
 order by s.created_at desc;

-- ═══════════════════════════════════════════════════════════════════
-- 5. VALIDAÇÃO DE FORA, COM HTTP — a que realmente importa
-- ═══════════════════════════════════════════════════════════════════
--   URL=https://SEU-PROJETO.supabase.co
--   ANON=<chave anon pública>
--
--   # 5.1 a vitrine não pode quebrar (esperado 200, 2 produtos)
--   curl -s "$URL/rest/v1/produtos?select=nome&ativo=eq.true" \
--        -H "apikey: $ANON"
--
--   # 5.2 login -> guardar o access token
--   AT=$(curl -s -X POST "$URL/auth/v1/token?grant_type=password" \
--        -H "apikey: $ANON" -H 'Content-Type: application/json' \
--        -d '{"email":"EMAIL_DA_MAY","password":"SENHA"}' \
--        | python3 -c 'import sys,json; print(json.load(sys.stdin)["access_token"])')
--
--   # 5.3 com sessão viva: tudo responde (esperado 200)
--   for t in produtos pedidos pedido_itens admin_config admins; do
--     curl -s -o /dev/null -w "$t %{http_code}\n" \
--       "$URL/rest/v1/$t?select=*&limit=1" \
--       -H "apikey: $ANON" -H "Authorization: Bearer $AT"
--   done
--
--   # 5.4 logout, e DEPOIS o MESMO token — sem esperar o exp
--   curl -s -o /dev/null -w "logout %{http_code}\n" -X POST \
--     "$URL/auth/v1/logout" -H "apikey: $ANON" -H "Authorization: Bearer $AT"
--
--   for t in pedidos pedido_itens admin_config admins; do
--     curl -s -w " <- $t %{http_code}\n" \
--       "$URL/rest/v1/$t?select=*&limit=1" \
--       -H "apikey: $ANON" -H "Authorization: Bearer $AT"
--   done
--   # esperado: HTTP 200 com corpo [] em todas — RLS filtra tudo,
--   # nenhuma linha volta. Não é 403 porque o grant de tabela continua
--   # existindo para o papel authenticated; quem nega é a policy.
--
--   curl -s -o /dev/null -w "patch %{http_code}\n" -X PATCH \
--     "$URL/rest/v1/produtos?id=eq.00000000-0000-0000-0000-000000000000" \
--     -H "apikey: $ANON" -H "Authorization: Bearer $AT" \
--     -H 'Content-Type: application/json' -d '{"ativo":true}'
--   # 204 sem linha afetada é o esperado aqui (o filtro não casa com
--   # nada); a prova de verdade é o PATCH sem filtro:
--
--   curl -s -w "\n" -X PATCH "$URL/rest/v1/produtos?nome=neq.zzz" \
--     -H "apikey: $ANON" -H "Authorization: Bearer $AT" \
--     -H 'Content-Type: application/json' -H 'Prefer: return=representation' \
--     -d '{"ordem":0}'
--   # esperado: []  (nenhuma linha alterada)  — ANTES da 002 isto
--   # devolvia os 2 produtos.
--
--   # 5.5 novo login volta a funcionar (sessão nova, token novo)
--
-- ═══════════════════════════════════════════════════════════════════
-- 6. ROLLBACK — volta exatamente ao estado da 001
--    Nenhum dado é tocado nem na ida nem na volta.
-- ═══════════════════════════════════════════════════════════════════
--
--   begin;
--
--   create or replace function public.e_admin()
--   returns boolean
--   language sql
--   stable
--   security definer
--   set search_path = public
--   as $$
--     select exists (select 1 from public.admins where user_id = auth.uid());
--   $$;
--
--   revoke all on function public.e_admin() from public;
--   revoke all on function public.e_admin() from anon;
--   grant execute on function public.e_admin() to authenticated;
--
--   drop policy if exists "admin vê a si mesmo" on public.admins;
--   create policy "admin vê a si mesmo"
--     on public.admins for select
--     to authenticated
--     using (user_id = auth.uid());
--
--   commit;
--
-- ═══════════════════════════════════════════════════════════════════
-- 7. EFEITOS COLATERAIS CONHECIDOS
-- ═══════════════════════════════════════════════════════════════════
--   * Sessão trocada = poder perdido. Logout em qualquer aba, "sair de
--     todos os dispositivos" ou expiração de sessão derrubam o token na
--     hora. O /admin já trata 401/403 chamando encerrarSessao(), então
--     a tela de login reaparece sozinha — nenhuma mudança de UI foi
--     necessária.
--   * Token de service_role continua ignorando RLS por definição. Ele
--     não está no navegador e não pode estar: só no servidor.
--   * A chave anon não tem session_id e não tem execute em e_admin():
--     nada muda para ela.
--   * Custo: um join por verificação, pela chave primária de
--     auth.sessions. Irrelevante no volume deste projeto.
