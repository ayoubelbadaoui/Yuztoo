-- Meta App Review: data deletion + deauthorize callbacks.
-- Meta identifies the person by their app-scoped user id (ASID), so we keep
-- the ASID of whoever connected each channel, and log every request so the
-- public status page can answer « where is my deletion? » by confirmation code.

alter table public.meta_channel_credentials
  add column if not exists meta_user_id text;

create index if not exists meta_channel_credentials_meta_user_id_idx
  on public.meta_channel_credentials (meta_user_id)
  where meta_user_id is not null;

create table if not exists public.meta_data_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  confirmation_code text not null unique,
  meta_user_id text not null,
  kind text not null check (kind in ('deletion', 'deauthorize')),
  status text not null default 'received'
    check (status in ('received', 'completed', 'no_data', 'failed')),
  channels_affected integer not null default 0,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create index if not exists meta_data_deletion_requests_meta_user_id_idx
  on public.meta_data_deletion_requests (meta_user_id);

-- Edge (service role) only: RLS on, deny-all client policies, no grants to API roles.
alter table public.meta_data_deletion_requests enable row level security;
revoke all on public.meta_data_deletion_requests from anon, authenticated;

-- Explicit deny so advisors do not flag "RLS enabled, no policy".
-- Service role bypasses RLS; anon/authenticated already have zero grants.
drop policy if exists meta_data_deletion_requests_deny_all on public.meta_data_deletion_requests;
create policy meta_data_deletion_requests_deny_all
  on public.meta_data_deletion_requests
  for all
  to anon, authenticated
  using (false)
  with check (false);
