-- Push token storage for mobile push notifications.
-- Each row represents one device registration. A user can have multiple devices.
-- Tokens are unique per device (unique constraint on token column).

create table public.push_tokens (
  id         uuid        primary key default extensions.uuid_generate_v4(),
  user_id    uuid        not null references public.profiles(id) on delete cascade,
  token      text        not null,
  platform   text        not null check (platform in ('ios', 'android')),
  created_at timestamptz not null default now(),
  unique (token)
);

alter table public.push_tokens enable row level security;

-- Users can only read and manage their own tokens
create policy "Users can manage their own push tokens"
  on public.push_tokens for all
  using  (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Index for fast lookup when delivering notifications
create index push_tokens_user_id_idx on public.push_tokens(user_id);

-- Enable realtime so the app can react to token changes if needed
alter publication supabase_realtime add table public.push_tokens;
