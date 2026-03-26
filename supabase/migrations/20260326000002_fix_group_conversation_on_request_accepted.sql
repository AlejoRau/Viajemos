-- Replace the 1-on-1 conversation logic with a single group conversation per trip.
--
-- Behaviour:
-- 1. First accepted passenger → create the group conversation named
--    "Viaje ORIGIN - DESTINATION DD/MM/YYYY", add owner + passenger.
-- 2. Every subsequent accepted passenger → reuse the existing trip conversation,
--    just add the new passenger as a participant (if not already there).
--
-- SECURITY DEFINER is justified: reads trips (to get name/owner) and writes to
-- conversations + conversation_participants, all scoped to the single trip.

create or replace function public.create_conversation_on_request_accepted()
returns trigger language plpgsql security definer as $$
declare
  v_trip            record;
  v_conversation_id uuid;
begin
  if new.status = 'accepted' and old.status != 'accepted' then
    select * into v_trip from public.trips where id = new.trip_id;

    -- Check if the group conversation for this trip already exists
    select id into v_conversation_id
    from public.conversations
    where trip_id = new.trip_id
    limit 1;

    if v_conversation_id is null then
      -- First accepted passenger — create the group conversation
      insert into public.conversations(trip_id, name)
      values (
        new.trip_id,
        'Viaje ' || v_trip.origin_address
                 || ' - ' || v_trip.destination_address
                 || ' ' || to_char(v_trip.departure_date, 'DD/MM/YYYY')
      )
      returning id into v_conversation_id;

      -- Add the trip owner as the first participant
      insert into public.conversation_participants(conversation_id, user_id)
      values (v_conversation_id, v_trip.owner_id);
    end if;

    -- Add the newly accepted passenger (ignore if already a participant)
    insert into public.conversation_participants(conversation_id, user_id)
    values (v_conversation_id, new.passenger_id)
    on conflict (conversation_id, user_id) do nothing;

  end if;
  return new;
end;
$$;
