-- profiles.trip_count exists but never updates.
-- This trigger fires when a trip transitions to 'completed' and increments
-- trip_count for the owner and every accepted passenger.
--
-- SECURITY DEFINER is justified: this function reads trip_requests (to find
-- accepted passengers) and writes to profiles (trip_count only). It does not
-- expose any user data it shouldn't — all writes are scoped to participants
-- of the completed trip.

create or replace function public.update_trip_count_on_completed()
returns trigger language plpgsql security definer as $$
declare
  r record;
begin
  if new.status = 'completed' and old.status != 'completed' then
    -- Increment for the trip owner
    update public.profiles
      set trip_count = trip_count + 1
      where id = new.owner_id;

    -- Increment for every accepted passenger
    for r in
      select passenger_id
      from public.trip_requests
      where trip_id = new.id and status = 'accepted'
    loop
      update public.profiles
        set trip_count = trip_count + 1
        where id = r.passenger_id;
    end loop;
  end if;
  return new;
end;
$$;

create trigger on_trip_completed
  after update on public.trips
  for each row execute function public.update_trip_count_on_completed();
