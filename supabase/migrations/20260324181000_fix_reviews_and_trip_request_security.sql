-- =========================================================
-- FIX 1: Reviews INSERT policy was checking only that
-- auth.uid() = reviewer_id — it did NOT verify the trip is
-- completed or that the reviewer actually participated.
-- Anyone could leave a review for any trip they never took.
-- =========================================================
drop policy if exists "Users can create reviews for completed trips they participated " on public.reviews;

create policy "Users can create reviews for completed trips they participated in"
  on public.reviews for insert
  with check (
    auth.uid() = reviewer_id
    -- Can't review yourself
    and reviewer_id != reviewed_id
    -- Trip must be completed
    and exists (
      select 1 from public.trips t
      where t.id = reviews.trip_id
        and t.status = 'completed'
    )
    -- Reviewer must have participated: either as owner or accepted passenger
    and (
      exists (
        select 1 from public.trips t
        where t.id = reviews.trip_id
          and t.owner_id = auth.uid()
      )
      or exists (
        select 1 from public.trip_requests tr
        where tr.trip_id = reviews.trip_id
          and tr.passenger_id = auth.uid()
          and tr.status = 'accepted'
      )
    )
    -- Reviewed person must also have participated in the same trip
    and (
      exists (
        select 1 from public.trips t
        where t.id = reviews.trip_id
          and t.owner_id = reviews.reviewed_id
      )
      or exists (
        select 1 from public.trip_requests tr
        where tr.trip_id = reviews.trip_id
          and tr.passenger_id = reviews.reviewed_id
          and tr.status = 'accepted'
      )
    )
  );

-- =========================================================
-- FIX 2: DB-level self-review guard (belt-and-suspenders
-- alongside the policy above).
-- =========================================================
alter table public.reviews
  add constraint reviews_no_self_review
  check (reviewer_id != reviewed_id);

-- =========================================================
-- FIX 3: "Passengers can cancel their own requests" had no
-- with_check, so a passenger could set status to anything
-- (including 'accepted' — approving their own request).
-- Restrict to 'cancelled' only.
-- =========================================================
drop policy if exists "Passengers can cancel their own requests" on public.trip_requests;

create policy "Passengers can cancel their own requests"
  on public.trip_requests for update
  using  (auth.uid() = passenger_id)
  with check (status = 'cancelled');

-- =========================================================
-- FIX 4: An owner could request to join their own trip.
-- Prevent it at the DB level.
-- =========================================================
drop policy if exists "Passengers can create requests" on public.trip_requests;

create policy "Passengers can create requests"
  on public.trip_requests for insert
  with check (
    auth.uid() = passenger_id
    -- Cannot request your own trip
    and not exists (
      select 1 from public.trips t
      where t.id = trip_requests.trip_id
        and t.owner_id = auth.uid()
    )
  );
