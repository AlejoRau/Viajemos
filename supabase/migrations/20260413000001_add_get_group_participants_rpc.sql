-- RPC function used by the Flutter app to load group chat participants.
-- Returns user_id, full_name, avatar_url, and is_driver for every participant
-- of the given conversation.  Only accessible to users who are themselves
-- participants of that conversation (enforced inside the function body so the
-- SECURITY DEFINER can safely bypass RLS on profiles/trips).

create or replace function public.get_group_participants(p_conversation_id uuid)
returns table(
  user_id    uuid,
  full_name  text,
  avatar_url text,
  is_driver  boolean
)
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Guard: caller must be a participant of this conversation
  if not exists (
    select 1 from public.conversation_participants
    where conversation_id = p_conversation_id
      and user_id = auth.uid()
  ) then
    raise exception 'not a participant';
  end if;

  return query
    select
      cp.user_id,
      p.full_name,
      p.avatar_url,
      -- The driver is the owner of the trip linked to this conversation
      (t.owner_id = cp.user_id) as is_driver
    from public.conversation_participants cp
    join public.profiles p on p.id = cp.user_id
    left join public.conversations c on c.id = cp.conversation_id
    left join public.trips t on t.id = c.trip_id
    where cp.conversation_id = p_conversation_id
    order by is_driver desc, p.full_name;
end;
$$;
