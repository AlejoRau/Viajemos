-- BUG 1: handle_invitation_accepted inserts a trip_request with status='accepted',
-- but handle_trip_request_update only fires on UPDATE — so seats_taken never increments.
-- FIX: inline the seat update directly in this function.
--
-- BUG 2: notify_trip_request_received fires on every INSERT into trip_requests,
-- including ones inserted programmatically with status='accepted' (from invitations).
-- This sends a spurious "someone wants to join your trip" to the owner who already
-- invited that person. FIX: skip the notification if the request is already accepted.

-- Fix handle_invitation_accepted to also update seat counts
create or replace function public.handle_invitation_accepted()
returns trigger language plpgsql security definer as $$
declare
  v_trip record;
begin
  if new.status = 'accepted' and old.status = 'pending' then
    select * into v_trip from public.trips where id = new.trip_id;

    -- Check trip still has room
    if v_trip.available_seats - v_trip.seats_taken < 1 then
      update public.trip_invitations set status = 'expired' where id = new.id;
      insert into public.notifications(user_id, type, title, body, data)
      values (
        new.invitee_id,
        'trip_invitation_full',
        'El viaje ya está lleno',
        'El viaje al que fuiste invitado a ' || v_trip.destination_address || ' ya no tiene lugares disponibles.',
        jsonb_build_object('trip_id', new.trip_id, 'invitation_id', new.id)
      );
      return new;
    end if;

    -- Insert an already-accepted trip_request (owner pre-approved via invitation)
    insert into public.trip_requests(trip_id, passenger_id, status, seats_requested, message)
    values (new.trip_id, new.invitee_id, 'accepted', 1, 'Invitación aceptada')
    on conflict (trip_id, passenger_id) do nothing;

    -- The INSERT trigger for trip_requests only fires notify_trip_request_received,
    -- not the seat-count update (which is an UPDATE trigger). Update seats here directly.
    -- SECURITY DEFINER is justified: this function only writes to trips rows that
    -- belong to the trip in question, after validating room is available above.
    update public.trips
    set
      seats_taken = seats_taken + 1,
      status = case
        when seats_taken + 1 >= available_seats then 'full'
        else status
      end
    where id = new.trip_id
      and status not in ('cancelled', 'completed');

  end if;
  return new;
end;
$$;

-- Fix notify_trip_request_received to skip requests that are already accepted
-- (those come from the invitation flow — owner already said yes, no need to notify them)
create or replace function public.notify_trip_request_received()
returns trigger language plpgsql security definer as $$
declare
  v_trip      record;
  v_passenger record;
begin
  -- Skip if request was inserted already accepted (via invitation acceptance)
  if new.status = 'accepted' then
    return new;
  end if;

  select * into v_trip from public.trips where id = new.trip_id;
  select full_name into v_passenger from public.profiles where id = new.passenger_id;

  insert into public.notifications(user_id, type, title, body, data)
  values (
    v_trip.owner_id,
    'trip_request_received',
    'Nueva solicitud de viaje',
    v_passenger.full_name || ' quiere unirse a tu viaje a ' || v_trip.destination_address,
    jsonb_build_object('trip_id', new.trip_id, 'request_id', new.id, 'passenger_id', new.passenger_id)
  );
  return new;
end;
$$;
