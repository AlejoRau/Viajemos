-- ─── trip_stops ───────────────────────────────────────────────────────────────
-- Stores ordered waypoints along a trip route (cities and gas stations).
-- Passengers can request to ride only up to a specific stop via trip_requests.stop_id.
create table public.trip_stops (
  id          uuid        primary key default extensions.uuid_generate_v4(),
  trip_id     uuid        not null references public.trips(id) on delete cascade,
  name        text        not null,
  address     text        not null,
  location    geography(point, 4326) not null,
  stop_order  integer     not null check (stop_order >= 1),
  stop_type   text        not null check (stop_type in ('city', 'gas_station')),
  created_at  timestamptz not null default now(),
  constraint trip_stops_order_unique unique (trip_id, stop_order)
);

create index trip_stops_trip_id_idx  on public.trip_stops(trip_id);
create index trip_stops_location_idx on public.trip_stops using gist(location);

alter table public.trip_stops enable row level security;

-- Any authenticated user can read stops (needed to browse trip details).
create policy "trip_stops_select"
  on public.trip_stops for select
  to authenticated
  using (true);

-- Only the trip owner can add stops.
-- SECURITY: the with check re-queries trips so the inserting user must own the trip.
create policy "trip_stops_insert"
  on public.trip_stops for insert
  to authenticated
  with check (
    exists (
      select 1 from public.trips
      where trips.id = trip_id
        and trips.owner_id = auth.uid()
    )
  );

-- Only the trip owner can modify stops.
create policy "trip_stops_update"
  on public.trip_stops for update
  to authenticated
  using (
    exists (
      select 1 from public.trips
      where trips.id = trip_id
        and trips.owner_id = auth.uid()
    )
  );

-- Only the trip owner can delete stops.
create policy "trip_stops_delete"
  on public.trip_stops for delete
  to authenticated
  using (
    exists (
      select 1 from public.trips
      where trips.id = trip_id
        and trips.owner_id = auth.uid()
    )
  );

-- ─── trip_requests: add stop_id ──────────────────────────────────────────────
-- NULL  → passenger wants to travel to the trip's final destination.
-- non-NULL → passenger wants to travel only up to this stop.
-- ON DELETE SET NULL so deleting a stop does not orphan existing requests.
alter table public.trip_requests
  add column stop_id uuid references public.trip_stops(id) on delete set null;

create index trip_requests_stop_id_idx on public.trip_requests(stop_id);
