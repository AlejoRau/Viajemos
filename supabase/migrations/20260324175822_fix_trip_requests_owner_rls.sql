-- Trip owners need to see requests on their trips to manage them.
-- Without this policy the accept/decline flow is completely blocked for owners.

-- SELECT: owners can see all requests on trips they own
create policy "Trip owners can view requests on their trips"
  on public.trip_requests for select
  using (
    exists (
      select 1 from public.trips
      where id = trip_requests.trip_id
        and owner_id = auth.uid()
    )
  );

-- UPDATE: owners can change status to accepted or declined only
create policy "Trip owners can accept or decline requests"
  on public.trip_requests for update
  using (
    exists (
      select 1 from public.trips
      where id = trip_requests.trip_id
        and owner_id = auth.uid()
    )
  )
  with check (
    status in ('accepted', 'declined')
  );
