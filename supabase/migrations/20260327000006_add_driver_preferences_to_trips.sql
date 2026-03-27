-- Driver preferences: allow drivers to communicate their comfort rules to
-- passengers before they request a seat. Defaults are conservative (no pets,
-- no smoking) so existing trips aren't silently opted in to permissive behaviour.

alter table public.trips
  add column allows_pets     boolean not null default false,
  add column allows_smoking  boolean not null default false;
