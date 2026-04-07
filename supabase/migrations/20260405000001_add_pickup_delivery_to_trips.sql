-- Agrega preferencias de recogida/entrega a domicilio.
-- picks_up_at_home: el conductor pasa a buscar al pasajero por su dirección.
-- drops_at_destination: el conductor lleva al pasajero hasta su destino exacto.
-- Ambos son opt-in y defecto false para no cambiar comportamiento de viajes existentes.

alter table public.trips
  add column picks_up_at_home     boolean not null default false,
  add column drops_at_destination boolean not null default false;

comment on column public.trips.picks_up_at_home is
  'El conductor pasa a buscar al pasajero en su dirección particular.';
comment on column public.trips.drops_at_destination is
  'El conductor deja al pasajero en su dirección de destino exacta.';
