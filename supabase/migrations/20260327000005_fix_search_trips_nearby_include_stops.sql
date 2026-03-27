-- Reemplaza la función anterior que solo buscaba por origen del viaje.
-- Ahora también devuelve viajes que tienen una parada cerca del punto buscado.
-- boarding_stop_id: null = el pasajero sube en el origen; uuid = sube en esa parada.
-- SECURITY DEFINER: igual que la versión anterior, para que usuarios sin acceso
-- directo a trips puedan buscar. Solo devuelve viajes con status='open'.
drop function if exists public.search_trips_nearby(double precision, double precision, double precision, date, date, integer);

create or replace function public.search_trips_nearby(
  center_lng      double precision,
  center_lat      double precision,
  radius_meters   double precision,
  departure_from  date    default current_date,
  departure_to    date    default null,
  min_seats       integer default 1
)
returns table (
  id                   uuid,
  owner_id             uuid,
  origin_address       text,
  origin_location      geography,
  destination_address  text,
  destination_location geography,
  route                geography,
  available_seats      integer,
  seats_taken          integer,
  price_per_seat       numeric,
  status               text,
  description          text,
  vehicle_description  text,
  created_at           timestamptz,
  updated_at           timestamptz,
  departure_date       date,
  departure_time       time,
  coordinate_time      boolean,
  boarding_stop_id     uuid
)
language sql
stable
security definer
set search_path = 'public'
as $$
  -- Viajes cuyo ORIGEN está cerca del punto buscado (boarding_stop_id = null).
  select
    t.id, t.owner_id, t.origin_address, t.origin_location,
    t.destination_address, t.destination_location, t.route,
    t.available_seats, t.seats_taken, t.price_per_seat, t.status,
    t.description, t.vehicle_description, t.created_at, t.updated_at,
    t.departure_date, t.departure_time, t.coordinate_time,
    null::uuid as boarding_stop_id
  from public.trips t
  where
    t.status = 'open'
    and t.available_seats - t.seats_taken >= min_seats
    and t.departure_date >= departure_from
    and (departure_to is null or t.departure_date <= departure_to)
    and st_dwithin(
      t.origin_location,
      st_makepoint(center_lng, center_lat)::geography,
      radius_meters
    )

  union all

  -- Viajes que pasan por una PARADA cerca del punto buscado.
  -- Solo incluye el viaje si el origen NO está ya en el radio (evita duplicados).
  -- boarding_stop_id indica exactamente en qué parada sube el pasajero.
  select
    t.id, t.owner_id, t.origin_address, t.origin_location,
    t.destination_address, t.destination_location, t.route,
    t.available_seats, t.seats_taken, t.price_per_seat, t.status,
    t.description, t.vehicle_description, t.created_at, t.updated_at,
    t.departure_date, t.departure_time, t.coordinate_time,
    s.id as boarding_stop_id
  from public.trips t
  join public.trip_stops s on s.trip_id = t.id
  where
    t.status = 'open'
    and t.available_seats - t.seats_taken >= min_seats
    and t.departure_date >= departure_from
    and (departure_to is null or t.departure_date <= departure_to)
    and st_dwithin(
      s.location,
      st_makepoint(center_lng, center_lat)::geography,
      radius_meters
    )
    and not st_dwithin(
      t.origin_location,
      st_makepoint(center_lng, center_lat)::geography,
      radius_meters
    )

  order by departure_date asc, departure_time asc nulls last;
$$;
