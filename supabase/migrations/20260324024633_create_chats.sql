-- Conversations: one per trip (or per direct pair before group chat).
-- conversation_participants links users to conversations.
-- messages belong to a conversation and are sent by a participant.

create table public.conversations (
  id         uuid primary key default uuid_generate_v4(),
  trip_id    uuid references public.trips(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.conversation_participants (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id         uuid not null references public.profiles(id) on delete cascade,
  last_read_at    timestamptz,
  created_at      timestamptz not null default now(),
  primary key (conversation_id, user_id)
);

create index conversation_participants_user_id_idx
  on public.conversation_participants(user_id);

create table public.messages (
  id              uuid primary key default uuid_generate_v4(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id       uuid not null references public.profiles(id) on delete cascade,
  content         text not null,
  created_at      timestamptz not null default now()
);

create index messages_conversation_id_idx on public.messages(conversation_id);
create index messages_created_at_idx on public.messages(created_at desc);

-- RLS
alter table public.conversations enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.messages enable row level security;

-- conversations: only visible to participants
create policy "Participants can view their conversations"
  on public.conversations for select
  using (
    exists (
      select 1 from public.conversation_participants
      where conversation_id = conversations.id
        and user_id = auth.uid()
    )
  );

create policy "Authenticated users can create conversations"
  on public.conversations for insert
  with check (auth.role() = 'authenticated');

-- conversation_participants
create policy "Participants can view participants list"
  on public.conversation_participants for select
  using (
    exists (
      select 1 from public.conversation_participants cp
      where cp.conversation_id = conversation_participants.conversation_id
        and cp.user_id = auth.uid()
    )
  );

create policy "Users can join conversations"
  on public.conversation_participants for insert
  with check (auth.role() = 'authenticated');

create policy "Users can update their own participant row"
  on public.conversation_participants for update
  using (auth.uid() = user_id);

-- messages
create policy "Participants can view messages"
  on public.messages for select
  using (
    exists (
      select 1 from public.conversation_participants
      where conversation_id = messages.conversation_id
        and user_id = auth.uid()
    )
  );

create policy "Participants can send messages"
  on public.messages for insert
  with check (
    auth.uid() = sender_id
    and exists (
      select 1 from public.conversation_participants
      where conversation_id = messages.conversation_id
        and user_id = auth.uid()
    )
  );
