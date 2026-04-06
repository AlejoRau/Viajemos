-- Separate trips_driven / trips_taken counters (replaces the single trip_count
-- that couldn't distinguish driver from passenger), plus bio and social fields
-- for the profile screen.

alter table public.profiles
  add column if not exists trips_driven  int  not null default 0,
  add column if not exists trips_taken   int  not null default 0,
  add column if not exists bio_driver    text,
  add column if not exists bio_passenger text,
  add column if not exists instagram     text,
  add column if not exists facebook      text;

-- Update the existing trigger so each completed trip increments the right counter.
-- trip_count is also kept in sync for backward compatibility.
-- SECURITY DEFINER: reads trip_requests to find accepted passengers, then writes
-- only to the trips_driven / trips_taken / trip_count columns of participants.
-- No other user data is accessed or exposed.
create or replace function public.update_trip_count_on_completed()
returns trigger language plpgsql security definer
set search_path = public
as $$
declare
  r record;
begin
  if new.status = 'completed' and old.status != 'completed' then
    -- Driver gets a trips_driven increment
    update public.profiles
      set trips_driven = trips_driven + 1,
          trip_count   = trip_count + 1
      where id = new.owner_id;

    -- Each accepted passenger gets a trips_taken increment
    for r in
      select passenger_id
      from public.trip_requests
      where trip_id = new.id and status = 'accepted'
    loop
      update public.profiles
        set trips_taken = trips_taken + 1,
            trip_count  = trip_count + 1
        where id = r.passenger_id;
    end loop;
  end if;
  return new;
end;
$$;
