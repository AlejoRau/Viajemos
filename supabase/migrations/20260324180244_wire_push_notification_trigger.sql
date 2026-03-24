-- Enable pg_net (async HTTP from triggers) and pg_cron (scheduled jobs)
create extension if not exists pg_net  schema extensions;
create extension if not exists pg_cron schema extensions;

-- Trigger function: fires after every INSERT on notifications,
-- calls the send-push-notification Edge Function via pg_net (non-blocking).
-- SECURITY DEFINER: reads no extra data — only passes the NEW row to the
-- Edge Function, which handles its own service-role DB access.
create or replace function public.dispatch_push_notification()
returns trigger language plpgsql security definer as $$
declare
  payload jsonb;
begin
  payload := jsonb_build_object('record', row_to_json(new));

  perform net.http_post(
    url     := 'https://xowrngxyiuoaamhwxzng.supabase.co/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type',     'application/json',
      'x-webhook-secret', coalesce(current_setting('app.webhook_secret', true), '')
    ),
    body    := payload::text
  );
  return new;
end;
$$;

create trigger on_notification_inserted
  after insert on public.notifications
  for each row execute function public.dispatch_push_notification();

-- Schedule the trip reminder function to run daily at 08:00 ART (= 11:00 UTC)
select cron.schedule(
  'daily-trip-reminders',
  '0 11 * * *',
  $$
    select net.http_post(
      url     := 'https://xowrngxyiuoaamhwxzng.supabase.co/functions/v1/send-trip-reminders',
      headers := '{"Content-Type":"application/json","x-cron-secret":""}'::jsonb,
      body    := '{}'
    );
  $$
);
