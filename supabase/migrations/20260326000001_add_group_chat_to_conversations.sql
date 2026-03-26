-- Add name column to conversations for group chat display
alter table public.conversations
  add column name text;
