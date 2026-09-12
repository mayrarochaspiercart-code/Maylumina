-- ═══════════════════════════════════════════════════════════════════
-- MayLumina — RÉPLICA DE ENSAIO, PARTE B: sessões do Auth
--
-- Isto NÃO roda em produção. Complementa 000-replica-de-ensaio.sql com
-- o que a 002-session-revocation.sql precisa para ser ensaiada:
--
--   * auth.sessions, com as colunas que o GoTrue realmente cria;
--   * auth.jwt(), que é como o PostgREST entrega os claims;
--   * o claim session_id dentro do JWT — confirmado num token real de
--     produção em 2026-09-12 (o JWT do admin traz session_id e exp-iat
--     de 3600s).
--
-- Ordem de uso:
--   psql -f docs/supabase/000-replica-de-ensaio.sql
--   psql -f docs/supabase/000b-replica-sessoes.sql
--   psql -f docs/supabase/001-auth-e-rls.sql
--   psql -f docs/supabase/002-session-revocation.sql
-- ═══════════════════════════════════════════════════════════════════

-- auth.sessions na forma real do GoTrue (as colunas que importam aqui
-- são id, user_id e not_after; as demais existem para o ensaio não
-- mentir sobre o formato da tabela).
do $$ begin
  create type auth.aal_level as enum ('aal1','aal2','aal3');
exception when duplicate_object then null; end $$;

create table if not exists auth.sessions (
  id          uuid primary key,
  user_id     uuid not null references auth.users(id) on delete cascade,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now(),
  factor_id   uuid,
  aal         auth.aal_level,
  not_after   timestamptz,
  refreshed_at timestamp,
  user_agent  text,
  ip          inet,
  tag         text
);

-- auth.jwt() do Supabase: devolve o JSON inteiro de claims.
create or replace function auth.jwt() returns jsonb
language sql stable as $$
  select coalesce(
    nullif(current_setting('request.jwt.claim',  true), ''),
    nullif(current_setting('request.jwt.claims', true), '')
  )::jsonb
$$;

grant execute on function auth.jwt() to anon, authenticated, service_role;

-- Em produção auth.sessions pertence a supabase_auth_admin. Aqui o dono
-- é postgres, que é também quem vai ser dono de public.e_admin() — ou
-- seja, o ensaio reproduz a condição de que a função SECURITY DEFINER
-- precisa conseguir ler auth.sessions. NINGUÉM além do dono recebe
-- privilégio nessa tabela: anon e authenticated não podem lê-la direto.
revoke all on auth.sessions from public, anon, authenticated;
