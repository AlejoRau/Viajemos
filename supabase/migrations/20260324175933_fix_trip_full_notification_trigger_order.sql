-- TRIGGER ORDER BUG:
-- on_trip_request_status_changed fires before on_trip_request_updated (alphabetical order:
-- 's' < 'u'). This means when notify_trip_request_status_changed checks seats_taken
-- to decide if the trip is now full, handle_trip_request_update hasn't run yet —
-- so it reads the OLD seats_taken and may never send the "trip full" notification.
--
-- FIX: change the full-trip check to anticipate the pending increment by subtracting
-- new.seats_requested from available_seats before comparing. This makes the check
-- correct regardless of trigger execution order.

create or replace function public.notify_trip_request_status_changed()
returns trigger language plpgsql security definer as $$
declare
  v_trip  record;
  v_owner record;
  r       record;
begin
  select * into v_trip from public.trips where id = new.trip_id;
  select full_name into v_owner from public.profiles where id = v_trip.owner_id;

  if new.status = 'accepted' and old.status != 'accepted' then
    -- Notify the passenger their request was accepted
    insert into public.notifications(user_id, type, title, body, data)
    values (
      new.passenger_id,
      'trip_request_accepted',
      '¡Solicitud aceptada!',
      v_owner.full_name || ' aceptó tu solicitud para el viaje a ' || v_trip.destination_address,
      jsonb_build_object('trip_id', new.trip_id, 'request_id', new.id)
    );

    -- Check if this acceptance will fill the trip.
    -- Subtract new.seats_requested because handle_trip_request_update may not
    -- have run yet (it fires after us due to alphabetical trigger order).
    if (v_trip.available_seats - v_trip.seats_taken - new.seats_requested) <= 0 then
      for r in
        select passenger_id from public.trip_requests
        where trip_id = new.trip_id
          and status = 'pending'
          and id != new.id
      loop
        insert into public.notifications(user_id, type, title, body, data)
        values (
          r.passenger_id,
          'trip_full_pending',
          'El viaje se llenó',
          'El viaje a ' || v_trip.destination_address || ' se llenó antes de que tu solicitud fuera revisada.',
          jsonb_build_object('trip_id', new.trip_id, 'request_id', new.id)
        );
      end loop;
    end if;

  elsif new.status = 'declined' and old.status != 'declined' then
    insert into public.notifications(user_id, type, title, body, data)
    values (
      new.passenger_id,
      'trip_request_declined',
      'Solicitud rechazada',
      v_owner.full_name || ' no pudo aceptar tu solicitud para el viaje a ' || v_trip.destination_address,
      jsonb_build_object('trip_id', new.trip_id, 'request_id', new.id)
    );

  elsif new.status = 'cancelled' and old.status != 'cancelled' then
    insert into public.notifications(user_id, type, title, body, data)
    values (
      v_trip.owner_id,
      'trip_request_cancelled',
      'Un pasajero canceló su solicitud',
      'Un pasajero canceló su solicitud para tu viaje a ' || v_trip.destination_address,
      jsonb_build_object('trip_id', new.trip_id, 'request_id', new.id, 'passenger_id', new.passenger_id)
    );
  end if;

  return new;
end;
$$;
