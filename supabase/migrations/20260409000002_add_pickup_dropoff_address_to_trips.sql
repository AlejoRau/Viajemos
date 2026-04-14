-- Separate city-level addresses (origin/destination) from street-level pickup/dropoff
-- addresses chosen on the map. This way the trip title always shows city names.
-- pickup_address: specific street where driver departs (from map pin, nullable)
-- dropoff_address: specific street where driver arrives (from map pin, nullable)

alter table trips
  add column if not exists pickup_address text,
  add column if not exists dropoff_address text;
