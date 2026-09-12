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
-- função, que é quem executar este arquivo (no SQL Editor, o papel
-- postgres). Esse dono precisa conseguir ler auth.sessions — a tabela
-- pertence a supabase_auth_admin.
--
-- Se não conseguir, a função passa a lançar "permission denied for
-- table sessions" e TODA requisição administrativa vira erro: o painel
-- tranca. Por isso a seção 0 abaixo aborta a transação inteira antes de
-- qualquer alteração, em vez de deixar o projeto num estado quebrado.
--
-- Confira também, sem aplicar nada:
--   select has_table_privilege(current_user, 'auth.sessions', 'SELECT');
--   -- precisa voltar true
-- ═══════════════════════════════════════════════════════════════════

begin;

-- ───────────────────────────────────────────────────────────────────
-- 0. TRAVA DE SEGURANÇA
--    Se o dono desta migration não lê auth.sessions, nada é aplicado.
-- ───────────────────────────────────────────────────────────────────
do $$
begin
  if not has_table_privilege(current_user, 'auth.sessions', 'SELECT') then
    raise exception
      'ABORTADO: o papel % nao tem SELECT em auth.sessions. Sem isso a '
      'e_admin() endurecida travaria o painel inteiro. Nada foi alterado.',
      current_user;
  end if;
  perform 1 from auth.sessions limit 1;  -- prova de leitura de verdade
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
--    de chegar aqui; a seção 4.4 confere isso de novo depois de aplicar.
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

commit;

-- ═══════════════════════════════════════════════════════════════════
-- 3. VALIDAÇÃO — rodar logo depois, no mesmo SQL Editor
-- ═══════════════════════════════════════════════════════════════════

-- 3.1 A função tem o corpo novo? (tem de conter auth.sessions)
select p.proname,
       p.prosecdef                        as security_definer,
       p.proconfig                        as search_path,
       position('auth.sessions' in pg_get_functiondef(p.oid)) > 0 as exige_sessao
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public' and p.proname = 'e_admin';

-- 3.2 Quem pode executar e_admin()? (esperado: só authenticated)
select grantee, privilege_type
  from information_schema.routine_privileges
 where routine_schema = 'public' and routine_name = 'e_admin'
 order by grantee;

-- 3.3 As policies continuam sendo exatamente 7, e a de admins mudou?
select tablename, policyname, cmd, qual
  from pg_policies
 where schemaname = 'public'
 order by tablename, policyname;

-- 3.4 Prova de que não há recursão: isto tem de responder, não travar.
--     (como postgres, e_admin() devolve false porque não há JWT — o
--     que importa é que a consulta RETORNA em vez de estourar a pilha)
select public.e_admin() as e_admin_sem_jwt;

-- 3.5 Os dados continuam intactos (esperado: 2 / 0 / 0 / 1 / 1)
select 'produtos' as tabela, count(*) from public.produtos
union all select 'pedidos',      count(*) from public.pedidos
union all select 'pedido_itens', count(*) from public.pedido_itens
union all select 'admin_config', count(*) from public.admin_config
union all select 'admins',       count(*) from public.admins;

-- 3.6 Sessões vivas agora (cada login abre uma; signOut apaga)
select s.id as session_id, u.email, s.created_at, s.not_after
  from auth.sessions s
  join auth.users u on u.id = s.user_id
  join public.admins a on a.user_id = s.user_id
 order by s.created_at desc;

-- ═══════════════════════════════════════════════════════════════════
-- 4. VALIDAÇÃO DE FORA, COM HTTP — a que realmente importa
-- ═══════════════════════════════════════════════════════════════════
--   URL=https://SEU-PROJETO.supabase.co
--   ANON=<chave anon pública>
--
--   # 4.1 a vitrine não pode quebrar (esperado 200, 2 produtos)
--   curl -s "$URL/rest/v1/produtos?select=nome&ativo=eq.true" \
--        -H "apikey: $ANON"
--
--   # 4.2 login -> guardar o access token
--   AT=$(curl -s -X POST "$URL/auth/v1/token?grant_type=password" \
--        -H "apikey: $ANON" -H 'Content-Type: application/json' \
--        -d '{"email":"EMAIL_DA_MAY","password":"SENHA"}' \
--        | python3 -c 'import sys,json; print(json.load(sys.stdin)["access_token"])')
--
--   # 4.3 com sessão viva: tudo responde (esperado 200)
--   for t in produtos pedidos pedido_itens admin_config admins; do
--     curl -s -o /dev/null -w "$t %{http_code}\n" \
--       "$URL/rest/v1/$t?select=*&limit=1" \
--       -H "apikey: $ANON" -H "Authorization: Bearer $AT"
--   done
--
--   # 4.4 logout, e DEPOIS o MESMO token — sem esperar o exp
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
--   # 4.5 novo login volta a funcionar (sessão nova, token novo)
--
-- ═══════════════════════════════════════════════════════════════════
-- 5. ROLLBACK — volta exatamente ao estado da 001
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
-- 6. EFEITOS COLATERAIS CONHECIDOS
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
