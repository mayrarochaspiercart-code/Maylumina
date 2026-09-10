-- ═══════════════════════════════════════════════════════════════════
-- MayLumina — RÉPLICA DE ENSAIO
--
-- Isto NÃO roda em produção. Serve para testar a 001-auth-e-rls.sql
-- num Postgres descartável antes de ela encostar no banco real.
--
-- Monta o estado que produção tinha em 2026-09-10: as quatro tabelas
-- com as colunas observadas, os papéis anon/authenticated/service_role,
-- o schema auth com users e auth.uid(), os "grant all" padrão do
-- Supabase, e uma policy permissiva sobrando de propósito, com nome
-- que a migration não conhece — para provar que a seção 0 dela derruba
-- policies antigas de verdade.
--
-- Como usar (precisa de postgresql-16 instalado):
--
--   initdb -D /tmp/ensaio -U postgres --auth=trust
--   pg_ctl -D /tmp/ensaio -o '-p 54329' -l /tmp/ensaio/log start
--   psql -p 54329 -U postgres -f docs/supabase/000-replica-de-ensaio.sql
--   psql -p 54329 -U postgres -f docs/supabase/001-auth-e-rls.sql
--
-- Depois é só criar um usuário em auth.users, registrá-lo em
-- public.admins e testar com "set local role" + "set local
-- request.jwt.claims".
-- ═══════════════════════════════════════════════════════════════════


create role anon          nologin noinherit;
create role authenticated nologin noinherit;
create role service_role  nologin noinherit bypassrls;
create role authenticator login noinherit;
grant anon, authenticated, service_role to authenticator;

create schema if not exists auth;
create table auth.users (
  id    uuid primary key default gen_random_uuid(),
  email text unique
);

-- auth.uid() do Supabase: lê o "sub" do JWT que o PostgREST injeta.
create or replace function auth.uid() returns uuid
language sql stable as $$
  select nullif(current_setting('request.jwt.claims', true)::json->>'sub','')::uuid
$$;
grant usage on schema auth to anon, authenticated, service_role;
grant execute on function auth.uid() to anon, authenticated, service_role;
grant select on auth.users to service_role;

-- ── tabelas do projeto, com as colunas observadas em produção ──
create table public.produtos (
  id          uuid primary key default gen_random_uuid(),
  nome        text not null,
  descricao   text,
  preco       numeric,
  categoria   text,
  imagem_url  text,
  video_url   text,
  ativo       boolean default true,
  destaque    boolean default false,
  ordem       int default 0,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

create table public.pedidos (
  id         uuid primary key default gen_random_uuid(),
  cliente    text,
  telefone   text,
  status     text default 'novo',
  total      numeric,
  created_at timestamptz default now()
);

create table public.pedido_itens (
  id         uuid primary key default gen_random_uuid(),
  pedido_id  uuid references public.pedidos(id) on delete cascade,
  produto_id uuid references public.produtos(id),
  quantidade int,
  preco      numeric
);

create table public.admin_config (
  id         int primary key,
  senha_hash text,
  created_at timestamptz default now()
);

-- ── dados iguais aos de produção (2 produtos ativos, resto vazio) ──
insert into public.produtos (nome, descricao, categoria, preco, ativo)
values ('Doce Noir',      'descricao 1', 'body-care', 59.90, true),
       ('Doce Autêntica', 'descricao 2', 'body-care', 54.90, true);
insert into public.admin_config (id, senha_hash) values (1, 'SENHA_ANTIGA_COMPROMETIDA');

-- ── privilégios padrão do Supabase: é isto que hoje deixa tudo aberto ──
grant usage on schema public to anon, authenticated, service_role;
grant all on all tables in schema public to anon, authenticated, service_role;
grant all on all sequences in schema public to anon, authenticated, service_role;

-- ── ARMADILHA DE PROPÓSITO ──
-- Uma policy permissiva sobrando, com nome que a migration não conhece.
-- Se a seção 0 não derrubar isto, o RLS liga e continua tudo aberto.
alter table public.produtos enable row level security;
create policy "Enable all access for all users" on public.produtos
  for all to anon, authenticated using (true) with check (true);
alter table public.produtos disable row level security;
