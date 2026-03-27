-- Agrega boarding_stop_id: dónde quiere SUBIRSE el pasajero (null = origen del viaje).
-- Complementa stop_id que indica dónde quiere BAJARSE (null = destino final).
alter table public.trip_requests
  add column boarding_stop_id uuid references public.trip_stops(id) on delete set null;

create index trip_requests_boarding_stop_id_idx on public.trip_requests(boarding_stop_id);

-- Valida que stop_id y boarding_stop_id pertenezcan al mismo viaje del request.
-- Sin esto un pasajero podría mandar un stop_id de otro viaje completamente distinto.
create or replace function public.check_trip_request_stop_ownership()
returns trigger
language plpgsql
as $$
begin
  if new.stop_id is not null then
    if not exists (
      select 1 from public.trip_stops
      where id = new.stop_id and trip_id = new.trip_id
    ) then
      raise exception 'stop_id % no pertenece al viaje %', new.stop_id, new.trip_id;
    end if;
  end if;

  if new.boarding_stop_id is not null then
    if not exists (
      select 1 from public.trip_stops
      where id = new.boarding_stop_id and trip_id = new.trip_id
    ) then
      raise exception 'boarding_stop_id % no pertenece al viaje %', new.boarding_stop_id, new.trip_id;
    end if;
  end if;

  return new;
end;
$$;

create trigger check_trip_request_stop_ownership
  before insert or update on public.trip_requests
  for each row execute function public.check_trip_request_stop_ownership();
