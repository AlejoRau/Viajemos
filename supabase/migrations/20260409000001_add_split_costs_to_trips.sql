-- Add split_costs column to trips table.
-- When true, the price_per_seat represents each passenger's share of total trip expenses
-- rather than a fixed fare set by the driver.

alter table trips
  add column if not exists split_costs boolean not null default false;
