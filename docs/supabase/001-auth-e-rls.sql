-- ═══════════════════════════════════════════════════════════════════
-- MayLumina — Autenticação real + Row Level Security
--
-- Versão 2 (revisada linha a linha antes de ser aplicada; o que mudou
-- em relação à versão 1 está listado no fim, seção 8).
--
-- ESTADO ANTES DESTA MIGRATION (verificado por sondagem em 2026-09-10,
-- com a chave anon pública, sem alterar nenhum dado):
--
--   GET  admin_config?select=senha_hash  -> 200  (a senha do painel volta
--                                           em texto puro para qualquer
--                                           pessoa na internet)
--   PATCH  produtos (id inexistente)     -> 204  (autorizado)
--   DELETE produtos (id inexistente)     -> 204  (autorizado)
--   GET/PATCH pedidos                    -> 200 / 204 (autorizado)
--   GET  pedido_itens                    -> 200  (autorizado)
--   GET  admins                          -> 404  (tabela ainda não existe)
--   GET  /auth/v1/settings               -> "disable_signup": false
--
--   Linhas: produtos = 2 (ambos ativo=true, categoria body-care),
--           pedidos = 0, pedido_itens = 0, admin_config = 1.
--
-- Ou seja: qualquer pessoa na internet lê a senha do painel e cria,
-- edita ou apaga produtos e pedidos. Esta migration fecha isso.
--
-- O QUE ESTA MIGRATION NÃO FAZ: não apaga nenhuma linha, não remove
-- nenhuma tabela, não mexe em chave estrangeira e não toca em produto
-- nem em pedido. A única coisa destruída de propósito é a coluna
-- admin_config.senha_hash — ver seção 5, e é irreversível.
--
-- COMO APLICAR: Supabase Dashboard -> SQL Editor -> colar e executar.
-- Requer permissão de owner/service_role. Não pode ser aplicada pelo
-- navegador nem pela chave anon.
-- ═══════════════════════════════════════════════════════════════════

begin;

-- ───────────────────────────────────────────────────────────────────
-- 0. LIMPAR POLICIES ANTIGAS — a parte mais importante do arquivo
--
--    Policies permissivas se SOMAM: basta uma sobra antiga dizendo
--    "using (true)" para tudo o que vem abaixo virar decoração no
--    instante em que o RLS for ligado. A versão 1 desta migration só
--    derrubava policies pelo nome que ela mesma usa, o que não protege
--    contra nada que já exista com outro nome (e com a chave anon não
--    dá para listar pg_policies de fora).
--
--    Então: derruba TODAS as policies destas cinco tabelas e recria
--    apenas as declaradas aqui. Nenhuma linha de dado é tocada.
-- ───────────────────────────────────────────────────────────────────
do $$
declare
  p record;
begin
  for p in
    select schemaname, tablename, policyname
      from pg_policies
     where schemaname = 'public'
       and tablename in ('produtos', 'pedidos', 'pedido_itens',
                         'admin_config', 'admins')
  loop
    raise notice 'derrubando policy antiga: %.% -> %',
      p.schemaname, p.tablename, p.policyname;
    execute format('drop policy %I on %I.%I',
      p.policyname, p.schemaname, p.tablename);
  end loop;
end
$$;

-- ───────────────────────────────────────────────────────────────────
-- 1. QUEM É ADMINISTRADOR
--    A identidade passa a vir do Supabase Auth. Esta tabela apenas diz
--    quais usuários autenticados têm poder administrativo.
--
--    O "on delete cascade" aqui só alcança esta tabela: apagar um
--    usuário do Auth remove o crachá de admin dele, e nada mais.
--    Produto e pedido não têm relação nenhuma com ela.
-- ───────────────────────────────────────────────────────────────────
create table if not exists public.admins (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  criado_em  timestamptz not null default now()
);

alter table public.admins enable row level security;

-- Ninguém lê a lista de admins pelo cliente; só o próprio usuário se vê.
create policy "admin vê a si mesmo"
  on public.admins for select
  to authenticated
  using (user_id = auth.uid());

-- Os privilégios de tabela desta e das outras tabelas são acertados de
-- uma vez só na seção 6, que revoga tudo e devolve o mínimo.

-- Função auxiliar: é admin?
-- security definer para poder ler public.admins mesmo que o cliente não
-- tenha privilégio na tabela; search_path travado para a função não
-- poder ser sequestrada por um schema plantado no caminho.
create or replace function public.e_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

revoke all on function public.e_admin() from public;
revoke all on function public.e_admin() from anon;
grant execute on function public.e_admin() to authenticated;

-- ───────────────────────────────────────────────────────────────────
-- 2. PRODUTOS
--    anon: lê SOMENTE a vitrine pública (produtos ativos).
--    admin autenticado: tudo.
--
--    Hoje os 2 produtos existentes estão com ativo = true, então a
--    vitrine não perde nada. Um usuário autenticado que NÃO seja admin
--    enxerga exatamente o que o público enxerga — nem um campo a mais.
-- ───────────────────────────────────────────────────────────────────
alter table public.produtos enable row level security;

create policy "vitrine pública"
  on public.produtos for select
  to anon, authenticated
  using (ativo = true);

create policy "admin gerencia produtos"
  on public.produtos for all
  to authenticated
  using (public.e_admin())
  with check (public.e_admin());

-- ───────────────────────────────────────────────────────────────────
-- 3. PEDIDOS E PEDIDO_ITENS
--    anon: nada. Nem ler, nem criar, nem alterar, nem apagar.
--
--    A versão 1 abria INSERT para anon "porque a loja precisa disso".
--    Não precisa: o site publicado não escreve pedido nenhum. A palavra
--    "pedidos" só aparece em admin/index.html, e o botão de compra é um
--    link de WhatsApp (wa.me). As duas tabelas estão com 0 linhas.
--    Deixar INSERT aberto seria uma porta para qualquer pessoa encher o
--    banco de pedidos falsos, sem nenhum ganho.
--
--    Se um dia existir checkout de verdade no navegador, o que reabre
--    isso — e só isso — é:
--
--      create policy "checkout público cria pedido"
--        on public.pedidos for insert to anon with check (true);
--      grant insert on public.pedidos to anon;
--
--    (e o equivalente em pedido_itens). Continua sem SELECT: quem cria
--    um pedido não pode ler os pedidos dos outros.
-- ───────────────────────────────────────────────────────────────────
alter table public.pedidos      enable row level security;
alter table public.pedido_itens enable row level security;

create policy "admin gerencia pedidos"
  on public.pedidos for all
  to authenticated
  using (public.e_admin())
  with check (public.e_admin());

create policy "admin gerencia itens"
  on public.pedido_itens for all
  to authenticated
  using (public.e_admin())
  with check (public.e_admin());

-- ───────────────────────────────────────────────────────────────────
-- 4. ADMIN_CONFIG
--    Nenhum acesso anônimo.
-- ───────────────────────────────────────────────────────────────────
alter table public.admin_config enable row level security;

create policy "admin lê config"
  on public.admin_config for select
  to authenticated
  using (public.e_admin());

create policy "admin edita config"
  on public.admin_config for all
  to authenticated
  using (public.e_admin())
  with check (public.e_admin());

-- ───────────────────────────────────────────────────────────────────
-- 5. A CREDENCIAL ANTIGA  ⚠ IRREVERSÍVEL
--
--    admin_config tem exatamente três colunas: id, senha_hash e
--    created_at. Não há nada útil a preservar além do id. A senha
--    guardada aqui esteve publicamente legível, então ela é lixo
--    perigoso: some com a coluna.
--
--    Isto NÃO apaga a linha, apaga a coluna. Depois disto a senha
--    antiga não existe mais no banco. Ela continua no histórico do Git
--    e na documentação antiga — por isso ela tem de ser considerada
--    comprometida e trocada em todo lugar onde tenha sido reaproveitada.
-- ───────────────────────────────────────────────────────────────────
alter table public.admin_config drop column if exists senha_hash;

-- ───────────────────────────────────────────────────────────────────
-- 6. PRIVILÉGIOS DE TABELA — a tranca que o RLS não dá
--
--    ⚠ TRUNCATE IGNORA ROW LEVEL SECURITY. Isto não é teoria: no
--    ensaio desta migration, um usuário comum recém-cadastrado (nem
--    admin era) rodou "truncate public.pedidos cascade" e apagou
--    pedidos e pedido_itens inteiros. Nenhuma policy foi consultada.
--    O padrão do Supabase é "grant all", e "all" inclui TRUNCATE,
--    TRIGGER e REFERENCES.
--
--    Como o site permite cadastro aberto hoje, isso significa que
--    qualquer pessoa da internet poderia zerar as tabelas.
--
--    Por isso aqui não se revoga verbo por verbo: revoga-se TUDO e
--    devolve-se apenas o estritamente necessário. RLS decide QUAIS
--    linhas; o grant decide SE a operação existe.
-- ───────────────────────────────────────────────────────────────────
revoke all on public.produtos     from anon, authenticated, public;
revoke all on public.pedidos      from anon, authenticated, public;
revoke all on public.pedido_itens from anon, authenticated, public;
revoke all on public.admin_config from anon, authenticated, public;
revoke all on public.admins       from anon, authenticated, public;

-- anon: só a vitrine, e só para ler.
grant select on public.produtos to anon;

-- authenticated: os quatro verbos comuns; quem filtra é o RLS.
-- Nada de TRUNCATE, TRIGGER ou REFERENCES para ninguém.
grant select, insert, update, delete on public.produtos     to authenticated;
grant select, insert, update, delete on public.pedidos      to authenticated;
grant select, insert, update, delete on public.pedido_itens to authenticated;
grant select, insert, update, delete on public.admin_config to authenticated;
grant select                          on public.admins      to authenticated;

commit;

-- ───────────────────────────────────────────────────────────────────
-- 7. CONFERÊNCIA IMEDIATA (rodar logo depois, no mesmo SQL Editor)
-- ───────────────────────────────────────────────────────────────────

-- 7.1 RLS ligado nas cinco tabelas? (rowsecurity tem de ser true em todas)
select relname as tabela, relrowsecurity as rls_ligado
  from pg_class
 where relnamespace = 'public'::regnamespace
   and relname in ('produtos','pedidos','pedido_itens','admin_config','admins')
 order by relname;

-- 7.2 Quais policies existem agora? (esperado: exatamente as 6 abaixo)
--     admins       -> admin vê a si mesmo
--     admin_config -> admin lê config, admin edita config
--     pedido_itens -> admin gerencia itens
--     pedidos      -> admin gerencia pedidos
--     produtos     -> vitrine pública, admin gerencia produtos
select tablename, policyname, cmd, roles
  from pg_policies
 where schemaname = 'public'
 order by tablename, policyname;

-- 7.3 A senha antiga sumiu? (esperado: 0 linhas)
select column_name
  from information_schema.columns
 where table_schema = 'public'
   and table_name = 'admin_config'
   and column_name = 'senha_hash';

-- 7.4 Os dados continuam lá? (esperado: produtos = 2, os outros = 0)
select 'produtos' as tabela, count(*) from public.produtos
union all select 'pedidos',      count(*) from public.pedidos
union all select 'pedido_itens', count(*) from public.pedido_itens
union all select 'admin_config', count(*) from public.admin_config;

-- 7.6 Ninguém além do dono pode TRUNCATE? (esperado: nenhuma linha
--     com TRUNCATE, TRIGGER ou REFERENCES para anon/authenticated)
select grantee, table_name, privilege_type
  from information_schema.role_table_grants
 where table_schema = 'public'
   and grantee in ('anon','authenticated')
   and privilege_type in ('TRUNCATE','TRIGGER','REFERENCES')
 order by grantee, table_name;

-- 7.5 Já existe algum admin? (logo depois de aplicar, esperado: 0 —
--     o passo 8.2 abaixo é que resolve isso. Enquanto for 0, NINGUÉM
--     consegue administrar o site, nem a May.)
select count(*) as admins_registrados from public.admins;

-- ═══════════════════════════════════════════════════════════════════
-- 8. DEPOIS DE APLICAR — passos manuais no Dashboard
--    Sem eles o painel fica trancado para todo mundo. Não pule.
-- ═══════════════════════════════════════════════════════════════════
--
-- 8.1  Authentication -> Users -> Add user
--      Criar o usuário da May com e-mail e uma senha NOVA.
--      A senha antiga ("a que estava em admin_config") esteve
--      publicamente legível e não pode ser reaproveitada em lugar
--      nenhum. Marcar "Auto Confirm User".
--
-- 8.2  Registrar esse usuário como admin (SQL Editor):
--        insert into public.admins (user_id)
--        select id from auth.users where email = 'EMAIL_DA_MAY'
--        on conflict (user_id) do nothing;
--
--        -- conferir (tem de voltar 1 linha):
--        select count(*) from public.admins;
--
-- 8.3  Authentication -> Providers -> Email:
--      desligar "Enable email signups". Hoje /auth/v1/settings devolve
--      "disable_signup": false, ou seja: qualquer pessoa pode criar
--      conta no projeto. Um usuário assim não vira admin (as policies
--      exigem public.e_admin()), mas não há motivo para deixar a porta
--      aberta.
--
-- 8.4  Conferir de fora, com a chave anon — as cinco primeiras têm de
--      passar a FALHAR e a última tem de continuar respondendo 200:
--
--        URL=https://SEU-PROJETO.supabase.co
--        ANON=<a chave anon pública>
--
--        curl -s -o /dev/null -w '%{http_code}\n' \
--          "$URL/rest/v1/admin_config?select=*" -H "apikey: $ANON"
--        # esperado: 401 ou 403          (hoje: 200)
--
--        curl -s -o /dev/null -w '%{http_code}\n' \
--          "$URL/rest/v1/pedidos?select=*" -H "apikey: $ANON"
--        # esperado: 401 ou 403          (hoje: 200)
--
--        curl -s -o /dev/null -w '%{http_code}\n' \
--          "$URL/rest/v1/pedido_itens?select=*" -H "apikey: $ANON"
--        # esperado: 401 ou 403          (hoje: 200)
--
--        curl -s -o /dev/null -w '%{http_code}\n' -X DELETE \
--          "$URL/rest/v1/produtos?id=eq.00000000-0000-0000-0000-000000000000" \
--          -H "apikey: $ANON" -H "Authorization: Bearer $ANON"
--        # esperado: 401 ou 403          (hoje: 204)
--
--        curl -s -o /dev/null -w '%{http_code}\n' \
--          "$URL/rest/v1/admins?select=*" -H "apikey: $ANON"
--        # esperado: 401 ou 403
--
--        curl -s -o /dev/null -w '%{http_code}\n' \
--          "$URL/rest/v1/produtos?select=id&limit=1" -H "apikey: $ANON"
--        # esperado: 200  (a vitrine continua pública)
--
-- 8.5  Entrar em /admin com o e-mail e a senha novos e confirmar que
--      listar, criar, editar e apagar produto continuam funcionando —
--      agora autorizados pelo token do usuário, não pela chave anon.
--      Usar um produto claramente descartável para o teste, por exemplo
--      "__TESTE_SEGURANCA_MAYLUMINA__", e apagá-lo no fim.
--
-- ═══════════════════════════════════════════════════════════════════
-- 9. O QUE MUDOU DA VERSÃO 1 PARA ESTA
-- ═══════════════════════════════════════════════════════════════════
--   * Seção 0 nova: derruba TODAS as policies das cinco tabelas antes
--     de recriar. Antes só derrubava as de nome conhecido, e qualquer
--     sobra permissiva anularia a migration inteira.
--   * Removidas as policies de INSERT anônimo em pedidos e
--     pedido_itens: o site não cria pedido nenhum pelo navegador, e
--     "with check (true)" era porta aberta sem uso.
--   * revoke all em pedidos e pedido_itens para anon (antes sobrava
--     INSERT), e revoke também do papel PUBLIC nas tabelas sensíveis.
--   * grant select em public.admins para authenticated, senão a policy
--     "admin vê a si mesmo" nunca funcionaria.
--   * revoke execute de e_admin() também para anon, não só para PUBLIC.
--   * Seção 6 refeita: em vez de revogar verbo por verbo, revoga TUDO
--     de anon, authenticated e PUBLIC nas cinco tabelas e devolve só o
--     necessário. Motivo: TRUNCATE ignora RLS, vinha no "grant all"
--     padrão do Supabase, e no ensaio um usuário comum apagou pedidos
--     e pedido_itens inteiros com um único comando. A versão 1 (e a
--     primeira revisão desta) deixavam essa porta aberta.
--   * Seção 7 nova: consultas de conferência logo após aplicar,
--     incluindo a contagem de linhas antes/depois e o aviso de que
--     ninguém administra nada enquanto public.admins estiver vazia.
