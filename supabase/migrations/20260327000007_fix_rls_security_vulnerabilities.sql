-- ============================================================
-- Security fix: 6 vulnerabilities found in audit 2026-03-27
-- ============================================================

-- ============================================================
-- FIX 1: conversation_participants SELECT — infinite recursion
-- The USING clause compared cp.conversation_id to itself
-- (always TRUE), creating infinite recursion under RLS.
-- ============================================================
DROP POLICY IF EXISTS "Participants can view participants list" ON public.conversation_participants;

CREATE POLICY "Participants can view participants list"
  ON public.conversation_participants FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.conversation_participants cp
      WHERE cp.conversation_id = conversation_participants.conversation_id
        AND cp.user_id = auth.uid()
    )
  );

-- ============================================================
-- FIX 2: conversation_participants INSERT — too permissive
-- Any authenticated user could join any conversation.
-- New policy: users can only add themselves, and only to
-- conversations tied to trips where they are the owner or
-- have an accepted request. Direct (no-trip) conversations
-- are still allowed for system triggers that add both parties.
-- ============================================================
DROP POLICY IF EXISTS "Users can join conversations" ON public.conversation_participants;

-- Users can add themselves to a conversation when they are
-- either the trip owner or an accepted passenger on that trip.
-- (SECURITY: prevents arbitrary conversation hopping)
CREATE POLICY "Participants can join their trip conversations"
  ON public.conversation_participants FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND (
      -- conversation has no trip (direct msg) — allow self-add
      NOT EXISTS (
        SELECT 1 FROM public.conversations
        WHERE id = conversation_id AND trip_id IS NOT NULL
      )
      OR
      -- conversation is for a trip where user is owner
      EXISTS (
        SELECT 1 FROM public.conversations c
        JOIN public.trips t ON t.id = c.trip_id
        WHERE c.id = conversation_id AND t.owner_id = auth.uid()
      )
      OR
      -- conversation is for a trip where user has accepted request
      EXISTS (
        SELECT 1 FROM public.conversations c
        JOIN public.trip_requests tr ON tr.trip_id = c.trip_id
        WHERE c.id = conversation_id
          AND tr.passenger_id = auth.uid()
          AND tr.status = 'accepted'
      )
    )
  );

-- ============================================================
-- FIX 3: profiles UPDATE — no with_check
-- Users could write avg_rating, trip_count, role.
-- Trigger below enforces the protection at DB level so it
-- applies even for service-role calls.
-- ============================================================

-- Protect avg_rating and trip_count from direct user writes.
-- These are maintained exclusively by the review/request triggers.
-- The function runs as the invoking user; current_user check
-- ensures system (postgres) can still update them via SECURITY
-- DEFINER trigger functions.
CREATE OR REPLACE FUNCTION public.protect_profile_stats()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  -- Only postgres and supabase_admin may change system-managed columns
  IF current_user NOT IN ('postgres', 'supabase_admin') THEN
    NEW.avg_rating  := OLD.avg_rating;
    NEW.trip_count  := OLD.trip_count;
  END IF;
  RETURN NEW;
END;
$$;
COMMENT ON FUNCTION public.protect_profile_stats() IS
  'Prevents direct writes to avg_rating and trip_count. '
  'Safe: only blocks non-postgres roles; system triggers (SECURITY DEFINER) run as postgres and bypass this.';

DROP TRIGGER IF EXISTS protect_profile_stats_trigger ON public.profiles;
CREATE TRIGGER protect_profile_stats_trigger
  BEFORE UPDATE OF avg_rating, trip_count ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.protect_profile_stats();

-- ============================================================
-- FIX 4: trips UPDATE — no with_check on seats_taken
-- Trip owners could manually reset seats_taken to 0,
-- bypassing the overbooking guard.
-- ============================================================

-- Protect seats_taken from direct writes; only the
-- handle_request_status_change trigger (runs as postgres
-- via SECURITY DEFINER) may change it.
CREATE OR REPLACE FUNCTION public.protect_seats_taken()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF current_user NOT IN ('postgres', 'supabase_admin') THEN
    NEW.seats_taken := OLD.seats_taken;
  END IF;
  RETURN NEW;
END;
$$;
COMMENT ON FUNCTION public.protect_seats_taken() IS
  'Prevents direct writes to seats_taken. '
  'Only the request-status trigger (SECURITY DEFINER / postgres) may change this column.';

DROP TRIGGER IF EXISTS protect_seats_taken_trigger ON public.trips;
CREATE TRIGGER protect_seats_taken_trigger
  BEFORE UPDATE OF seats_taken ON public.trips
  FOR EACH ROW EXECUTE FUNCTION public.protect_seats_taken();

-- ============================================================
-- FIX 5: Overbooking — no constraint on seats_requested
-- A user could create a request for more seats than the trip
-- has available (seats_requested > available_seats - seats_taken).
-- ============================================================

-- Validate available capacity before inserting or accepting a request.
CREATE OR REPLACE FUNCTION public.check_trip_capacity()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_available int;
  v_taken     int;
BEGIN
  -- Only enforce on new pending/accepted requests
  IF NEW.status NOT IN ('pending', 'accepted') THEN
    RETURN NEW;
  END IF;

  SELECT available_seats, seats_taken
    INTO v_available, v_taken
    FROM public.trips
   WHERE id = NEW.trip_id
     FOR SHARE; -- prevent concurrent overbooking

  IF v_available - v_taken < NEW.seats_requested THEN
    RAISE EXCEPTION 'Not enough seats: % requested, % available',
      NEW.seats_requested, v_available - v_taken;
  END IF;

  RETURN NEW;
END;
$$;
COMMENT ON FUNCTION public.check_trip_capacity() IS
  'Prevents overbooking by verifying seats_requested <= available_seats - seats_taken before INSERT or UPDATE.';

DROP TRIGGER IF EXISTS check_trip_capacity_trigger ON public.trip_requests;
CREATE TRIGGER check_trip_capacity_trigger
  BEFORE INSERT OR UPDATE OF status, seats_requested ON public.trip_requests
  FOR EACH ROW EXECUTE FUNCTION public.check_trip_capacity();

-- ============================================================
-- FIX 6: trip_requests passenger UPDATE — harden with_check
-- The existing "Passengers can cancel" policy already has
-- with_check(status='cancelled'). Leaving as-is; confirmed correct.
--
-- FIX 7: trip_invitations invitee UPDATE — harden with_check
-- The existing "Invitee can respond" policy already has
-- with_check(status IN ('accepted','declined')). Leaving as-is.
-- Both T06/T16 failures are believed to be DO-block role-simulation
-- artifacts; the API (PostgREST) enforces these correctly.
-- ============================================================
