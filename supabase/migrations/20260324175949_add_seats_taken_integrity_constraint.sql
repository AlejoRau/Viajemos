-- DB-level overbooking guard.
-- The trigger handles seat counts in the normal flow, but a check constraint
-- ensures no row can ever be written with seats_taken out of bounds,
-- regardless of how the update reaches the database.
alter table public.trips
  add constraint trips_seats_taken_valid
  check (seats_taken >= 0 and seats_taken <= available_seats);
