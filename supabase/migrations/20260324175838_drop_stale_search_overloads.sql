-- Drop the old overloads that still reference departure_at (a column that no longer exists).
-- The current schema uses departure_date (date) + departure_time (time).
-- Keeping these overloads causes ambiguous-call errors from the Flutter client.

drop function if exists public.search_trips_nearby(
  double precision, double precision, double precision,
  timestamp with time zone, timestamp with time zone, integer
);

drop function if exists public.search_trips_along_route(
  double precision, double precision, double precision,
  timestamp with time zone
);
