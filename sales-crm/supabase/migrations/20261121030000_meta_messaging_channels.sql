-- Meta messaging channels + inbox foundation (FB Page + Instagram)
-- Tokens never exposed to authenticated clients (service role / Edge only).

create type public.meta_channel_kind as enum ('facebook-page', 'instagram');
create type public.meta_connection_status as enum ('connected', 'expiring', 'disconnected');
create type public.social_message_direction as enum ('in', 'out');
create type public.social_message_status as enum ('sent', 'delivered', 'read', 'failed');

create table public.marketing_channels (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  kind public.meta_channel_kind not null,
  name text not null,
  handle text not null default '',
  meta_page_id text,
  meta_ig_id text,
  status public.meta_connection_status not null default 'disconnected',
  token_expires_at timestamptz,
  connected_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint marketing_channels_meta_ids_chk check (
    meta_page_id is not null or meta_ig_id is not null
  )
);

create unique index marketing_channels_workspace_page_uidx
  on public.marketing_channels (workspace_id, meta_page_id)
  where kind = 'facebook-page' and meta_page_id is not null;

create unique index marketing_channels_workspace_ig_uidx
  on public.marketing_channels (workspace_id, meta_ig_id)
  where kind = 'instagram' and meta_ig_id is not null;

create index marketing_channels_workspace_id_idx
  on public.marketing_channels (workspace_id);

create table public.meta_channel_credentials (
  channel_id uuid primary key references public.marketing_channels (id) on delete cascade,
  access_token text not null,
  token_type text not null default 'page',
  scopes text[] not null default '{}',
  expires_at timestamptz,
  updated_at timestamptz not null default now()
);

create table public.meta_oauth_states (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  return_to text not null default '/',
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '15 minutes')
);

create index meta_oauth_states_expires_at_idx on public.meta_oauth_states (expires_at);

create table public.social_conversations (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  channel_id uuid not null references public.marketing_channels (id) on delete cascade,
  platform text not null check (platform in ('messenger', 'instagram')),
  peer_scoped_id text not null,
  peer_name text,
  lead_id uuid,
  unread integer not null default 0 check (unread >= 0),
  last_inbound_at timestamptz,
  last_message_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (channel_id, peer_scoped_id)
);

create index social_conversations_workspace_id_idx
  on public.social_conversations (workspace_id, last_message_at desc);

create table public.social_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.social_conversations (id) on delete cascade,
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  direction public.social_message_direction not null,
  body text,
  media_urls text[] not null default '{}',
  meta_message_id text,
  status public.social_message_status not null default 'sent',
  error text,
  sent_at timestamptz not null default now(),
  unique (meta_message_id)
);

create index social_messages_conversation_id_idx
  on public.social_messages (conversation_id, sent_at);

alter table public.marketing_channels enable row level security;
alter table public.meta_channel_credentials enable row level security;
alter table public.meta_oauth_states enable row level security;
alter table public.social_conversations enable row level security;
alter table public.social_messages enable row level security;

-- Channels: members can read; owners/admins manage
create policy marketing_channels_select on public.marketing_channels
  for select to authenticated
  using (private.is_workspace_member(workspace_id));

create policy marketing_channels_insert on public.marketing_channels
  for insert to authenticated
  with check (
    exists (
      select 1 from public.workspace_members m
      where m.workspace_id = marketing_channels.workspace_id
        and m.user_id = auth.uid()
        and m.role in ('owner', 'admin')
    )
  );

create policy marketing_channels_update on public.marketing_channels
  for update to authenticated
  using (
    exists (
      select 1 from public.workspace_members m
      where m.workspace_id = marketing_channels.workspace_id
        and m.user_id = auth.uid()
        and m.role in ('owner', 'admin')
    )
  )
  with check (
    exists (
      select 1 from public.workspace_members m
      where m.workspace_id = marketing_channels.workspace_id
        and m.user_id = auth.uid()
        and m.role in ('owner', 'admin')
    )
  );

-- Credentials: no policies for authenticated → Edge/service role only
revoke all on public.meta_channel_credentials from authenticated, anon;

-- OAuth states: insert/select own rows briefly
create policy meta_oauth_states_insert on public.meta_oauth_states
  for insert to authenticated
  with check (
    user_id = auth.uid()
    and private.is_workspace_member(workspace_id)
  );

create policy meta_oauth_states_select on public.meta_oauth_states
  for select to authenticated
  using (user_id = auth.uid());

create policy meta_oauth_states_delete on public.meta_oauth_states
  for delete to authenticated
  using (user_id = auth.uid());

create policy social_conversations_select on public.social_conversations
  for select to authenticated
  using (private.is_workspace_member(workspace_id));

create policy social_messages_select on public.social_messages
  for select to authenticated
  using (private.is_workspace_member(workspace_id));
