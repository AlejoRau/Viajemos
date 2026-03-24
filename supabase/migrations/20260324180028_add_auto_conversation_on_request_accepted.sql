-- When a trip_request is accepted, automatically create a conversation between
-- the trip owner and the passenger so they can coordinate without needing to
-- manually start a chat. Idempotent: if a conversation already exists for this
-- trip between the same two users, reuse it.
--
-- SECURITY DEFINER is justified: the function only creates a conversation + participants
-- for the exact trip/owner/passenger involved in the accepted request.
-- No cross-user data is read beyond what's needed to link participants.

create or replace function public.create_conversation_on_request_accepted()
returns trigger language plpgsql security definer as $$
declare
  v_owner_id        uuid;
  v_conversation_id uuid;
begin
  if new.status = 'accepted' and old.status != 'accepted' then
    select owner_id into v_owner_id
    from public.trips where id = new.trip_id;

    -- Check if a conversation for this trip between these two users already exists
    select cp1.conversation_id into v_conversation_id
    from public.conversation_participants cp1
    join public.conversation_participants cp2
      on cp1.conversation_id = cp2.conversation_id
    join public.conversations c
      on c.id = cp1.conversation_id
    where cp1.user_id = v_owner_id
      and cp2.user_id = new.passenger_id
      and c.trip_id   = new.trip_id
    limit 1;

    if v_conversation_id is null then
      insert into public.conversations(trip_id)
      values (new.trip_id)
      returning id into v_conversation_id;

      insert into public.conversation_participants(conversation_id, user_id)
      values
        (v_conversation_id, v_owner_id),
        (v_conversation_id, new.passenger_id);
    end if;
  end if;
  return new;
end;
$$;

create trigger on_trip_request_accepted_create_conversation
  after update on public.trip_requests
  for each row execute function public.create_conversation_on_request_accepted();
