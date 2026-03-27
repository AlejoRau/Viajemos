-- trip_stops le faltaba updated_at (convención del proyecto: todas las tablas lo tienen).
alter table public.trip_stops
  add column updated_at timestamptz not null default now();

create trigger set_trip_stops_updated_at
  before update on public.trip_stops
  for each row execute function public.set_updated_at();
