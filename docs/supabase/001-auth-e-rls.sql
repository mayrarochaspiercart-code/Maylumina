-- ═══════════════════════════════════════════════════════════════════
-- MayLumina — Autenticação real + Row Level Security
--
-- ESTADO ANTES DESTA MIGRATION (verificado por sondagem em 2026-09-10,
-- com a chave anon pública, sem alterar nenhum dado):
--
--   GET  admin_config?select=senha_hash  -> 200  {"senha_hash":"maylumina2026"}
--   PATCH  produtos (filtro vazio)       -> 204  (autorizado)
--   DELETE produtos (filtro vazio)       -> 204  (autorizado)
--   POST   produtos (payload inválido)   -> 400 PGRST204 (erro de schema,
--                                           não de autorização: o INSERT
--                                           passaria)
--   GET/PATCH pedidos                    -> 200 / 204 (autorizado)
--   GET  pedido_itens                    -> 200  (autorizado)
--   GET  admins                          -> 404  (tabela ainda nao existe)
--   GET  /auth/v1/settings               -> "disable_signup": false
--                                           (qualquer pessoa pode se cadastrar
--                                            no projeto — ver 6.3)
--
-- Ou seja: qualquer pessoa na internet lê a senha do painel e cria, edita
-- ou apaga produtos e pedidos. Esta migration fecha isso.
--
-- COMO APLICAR: Supabase Dashboard -> SQL Editor -> colar e executar.
-- Requer permissão de owner/service_role. Não pode ser aplicada pelo
-- navegador nem pela chave anon.
-- ═══════════════════════════════════════════════════════════════════

begin;

-- ───────────────────────────────────────────────────────────────────
-- 1. QUEM É ADMINISTRADOR
--    A identidade passa a vir do Supabase Auth. Esta tabela apenas diz
--    quais usuários autenticados têm poder administrativo.
-- ───────────────────────────────────────────────────────────────────
create table if not exists public.admins (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  criado_em  timestamptz not null default now()
);

alter table public.admins enable row level security;

-- Ninguém lê a lista de admins pelo cliente; só o próprio usuário se vê.
drop policy if exists "admin vê a si mesmo" on public.admins;
create policy "admin vê a si mesmo"
  on public.admins for select
  to authenticated
  using (user_id = auth.uid());

-- Função auxiliar: é admin? (security definer para poder ler a tabela)
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
grant execute on function public.e_admin() to authenticated;

-- ───────────────────────────────────────────────────────────────────
-- 2. PRODUTOS
--    anon: lê SOMENTE a vitrine pública (produtos ativos).
--    admin autenticado: tudo.
-- ───────────────────────────────────────────────────────────────────
alter table public.produtos enable row level security;

drop policy if exists "vitrine pública"        on public.produtos;
drop policy if exists "admin gerencia produtos" on public.produtos;

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
-- 3. PEDIDOS
--    anon: pode CRIAR um pedido (o site precisa disso), mas nunca ler,
--          editar ou apagar — inclusive os próprios.
--    admin autenticado: tudo.
-- ───────────────────────────────────────────────────────────────────
alter table public.pedidos enable row level security;

drop policy if exists "anon cria pedido"       on public.pedidos;
drop policy if exists "admin gerencia pedidos" on public.pedidos;

create policy "anon cria pedido"
  on public.pedidos for insert
  to anon, authenticated
  with check (true);

create policy "admin gerencia pedidos"
  on public.pedidos for all
  to authenticated
  using (public.e_admin())
  with check (public.e_admin());

-- ───────────────────────────────────────────────────────────────────
-- 3b. PEDIDO_ITENS
--     Mesmas regras de pedidos: anon cria junto com o pedido, nunca lê.
-- ───────────────────────────────────────────────────────────────────
alter table public.pedido_itens enable row level security;

drop policy if exists "anon cria item"          on public.pedido_itens;
drop policy if exists "admin gerencia itens"    on public.pedido_itens;

create policy "anon cria item"
  on public.pedido_itens for insert
  to anon, authenticated
  with check (true);

create policy "admin gerencia itens"
  on public.pedido_itens for all
  to authenticated
  using (public.e_admin())
  with check (public.e_admin());

-- ───────────────────────────────────────────────────────────────────
-- 4. ADMIN_CONFIG
--    Nenhum acesso anônimo. E a coluna de senha deixa de existir: a
--    autenticação passa a ser do Supabase Auth, então guardar senha
--    aqui é só superfície de ataque.
-- ───────────────────────────────────────────────────────────────────
alter table public.admin_config enable row level security;

drop policy if exists "admin lê config"    on public.admin_config;
drop policy if exists "admin edita config" on public.admin_config;

create policy "admin lê config"
  on public.admin_config for select
  to authenticated
  using (public.e_admin());

create policy "admin edita config"
  on public.admin_config for all
  to authenticated
  using (public.e_admin())
  with check (public.e_admin());

alter table public.admin_config drop column if exists senha_hash;

-- ───────────────────────────────────────────────────────────────────
-- 5. REVOGAR O QUE A CHAVE ANON NÃO DEVE ALCANÇAR
-- ───────────────────────────────────────────────────────────────────
revoke all on public.admin_config from anon;
revoke all on public.admins       from anon;
revoke insert, update, delete on public.produtos from anon;
revoke select, update, delete on public.pedidos      from anon;
revoke select, update, delete on public.pedido_itens from anon;

commit;

-- ═══════════════════════════════════════════════════════════════════
-- 6. DEPOIS DE APLICAR — passos manuais no Dashboard
-- ═══════════════════════════════════════════════════════════════════
--
-- 6.1  Authentication -> Users -> Add user
--      Criar o usuário da May com e-mail e uma senha NOVA.
--      A senha antiga ("maylumina2026") esteve publicamente legível e
--      não pode ser reaproveitada em lugar nenhum.
--
-- 6.2  Registrar esse usuário como admin (SQL Editor):
--        insert into public.admins (user_id)
--        select id from auth.users where email = 'EMAIL_DA_MAY';
--
-- 6.3  Authentication -> Providers -> Email:
--      desligar "Enable email signups". Hoje /auth/v1/settings devolve
--      "disable_signup": false, ou seja: qualquer pessoa pode criar conta
--      no projeto. Um usuário assim não é admin (as policies exigem
--      public.e_admin()), mas não há motivo para deixar a porta aberta.
--
-- 6.4  Conferir o resultado (as duas primeiras devem falhar):
--        curl -s -o /dev/null -w '%{http_code}\n' \
--          "$URL/rest/v1/admin_config?select=*" -H "apikey: $ANON"
--        # esperado: 401 ou 403
--
--        curl -s -o /dev/null -w '%{http_code}\n' -X DELETE \
--          "$URL/rest/v1/produtos?id=eq.00000000-0000-0000-0000-000000000000" \
--          -H "apikey: $ANON" -H "Authorization: Bearer $ANON"
--        # esperado: 401 ou 403   (hoje devolve 204)
--
--        curl -s -o /dev/null -w '%{http_code}\n' \
--          "$URL/rest/v1/pedidos?select=*&limit=1" -H "apikey: $ANON"
--        # esperado: 401 ou 403   (hoje devolve 200)
--
--        curl -s -o /dev/null -w '%{http_code}\n' \
--          "$URL/rest/v1/produtos?select=id&limit=1" -H "apikey: $ANON"
--        # esperado: 200  (a vitrine continua pública)
--
-- 6.5  Entrar em /admin com o e-mail e a senha novos e confirmar que
--      criar, editar e apagar produto continuam funcionando — agora
--      autorizados pelo token do usuário, não pela chave anon.
