-- Trip owners can invite other users directly, bypassing the request flow.
-- Invitee accepts/declines; acceptance auto-creates an accepted trip_request
-- (handled by the handle_invitation_accepted trigger).

create table public.trip_invitations (
  id         uuid primary key default uuid_generate_v4(),
  trip_id    uuid not null references public.trips(id) on delete cascade,
  inviter_id uuid not null references public.profiles(id) on delete cascade,
  invitee_id uuid not null references public.profiles(id) on delete cascade,
  status     text not null default 'pending'
               check (status in ('pending', 'accepted', 'declined', 'expired')),
  message    text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (trip_id, invitee_id)
);

create index trip_invitations_trip_id_idx    on public.trip_invitations(trip_id);
create index trip_invitations_inviter_id_idx on public.trip_invitations(inviter_id);
create index trip_invitations_invitee_id_idx on public.trip_invitations(invitee_id);

create trigger set_updated_at_trip_invitations
  before update on public.trip_invitations
  for each row execute function public.set_updated_at();

alter table public.trip_invitations enable row level security;

create policy "Owner and invitee can view invitations"
  on public.trip_invitations for select
  using (auth.uid() = inviter_id or auth.uid() = invitee_id);

create policy "Owner can create invitations"
  on public.trip_invitations for insert
  with check (
    auth.uid() = inviter_id
    and auth.uid() = (select owner_id from public.trips where id = trip_id)
  );

-- Invitee can only flip to accepted or declined
create policy "Invitee can respond to their invitation"
  on public.trip_invitations for update
  using (auth.uid() = invitee_id)
  with check (status in ('accepted', 'declined'));

-- Owner can expire or cancel
create policy "Owner can expire or cancel invitations"
  on public.trip_invitations for update
  using (auth.uid() = inviter_id)
  with check (status = 'expired');
