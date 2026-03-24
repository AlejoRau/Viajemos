# Viajemos — Claude Code Conventions

## 1. Security (always first)

- **RLS on every table, no exceptions.** Every new table must have `alter table enable row level security` and explicit policies before the migration is considered done.
- **SECURITY DEFINER functions must be justified.** Only use when RLS would block a legitimate trigger/function. Always add a comment explaining why it is safe (what data it accesses and what it writes).
- **Never expose raw user data in aggregate functions.** Functions that aggregate across users must return only counts/averages, never individual rows from other users.
- **Input validated at the DB level.** Use `check` constraints for enums, ranges, and mutual-exclusion logic. Do not rely solely on app-level validation.
- **No secrets in migrations or code.** Supabase keys, service role keys, and passwords stay in environment variables only.
- **Principle of least privilege on policies.** Default to the most restrictive policy that still works. Expand only when there is a concrete reason.

---

## 2. Testing (before every delivery)

- **Run `execute_sql` or `apply_migration` dry-runs** by reading back the schema with `get_table_info` or querying `information_schema` after every migration to confirm columns, constraints, and indexes were created as expected.
- **Verify RLS policies** after creation by listing them (`pg_policies`) and confirming the expected roles and commands are covered.
- **Test triggers** by checking that dependent state updates correctly (e.g. after a trip_request is accepted, assert seats_taken incremented on the trip).
- **Confirm functions exist and are callable** after creation via `pg_proc` or a test invocation with safe dummy args.
- **Never mark a task complete without verifying** the result in the database.

---

## 3. Database conventions

- **UUIDs as primary keys** with `uuid_generate_v4()` default on all tables.
- **`created_at` and `updated_at`** on every table. `updated_at` managed by the shared `set_updated_at()` trigger.
- **Geography type for all location data** — `geography(point, 4326)` for points, `geography(linestring, 4326)` for routes. Always SRID 4326 (WGS84).
- **Spatial indexes with GiST** on every geography column.
- **Snake case** for all table names, column names, and function names.
- **Explicit `not null`** on every column that should never be null. Do not rely on application defaults.
- **Check constraints for enums** — no separate enum types, use `text` + `check(col in (...))` so adding values is a simple `alter table` with no type casting.
- **Foreign keys always with `on delete cascade`** unless there is a specific reason to use `set null` or `restrict` (document why).
- **Indexes on every foreign key column** and every column used in `where` clauses in known queries.

---

## 4. Migration conventions

- One migration per logical unit of work (one table, one feature, not a dump of everything).
- Migration names in `snake_case`, descriptive: `create_trip_alerts`, not `migration_003`.
- Always backfill existing rows when adding a `not null` column before adding the constraint.
- Never drop a column in the same migration that adds its replacement — two separate migrations.

---

## 5. Flutter / Dart conventions (for when frontend work begins)

- **Riverpod** for all state management. No `setState` outside of truly local ephemeral UI state.
- **Hive** for local persistence: recent searches, own profile cache, short-lived trip detail cache (~2 min TTL).
- **Supabase Realtime** subscriptions instead of polling for: trip seat counts, notifications, chat messages, trip request status.
- **Repository pattern** — one repository class per Supabase table group. No direct Supabase calls from UI widgets.
- **Never store the Supabase service role key on the client.** Anonymous key only.
- Feature folders: `lib/features/<feature_name>/{data,domain,presentation}`.
- Models are immutable (`@freezed`). No mutable model classes.

---

## 6. General conventions

- **Explain security decisions inline** — add a comment whenever a non-obvious security choice is made (SECURITY DEFINER, a permissive policy, a public function).
- **Prefer triggers over app logic** for data integrity (seat counts, avg ratings, notification dispatch). The database is the source of truth.
- **No premature abstraction.** Only generalize when a pattern appears three or more times.
- **Supabase project:** `viajemos` (ID: `xowrngxyiuoaamhwxzng`, region: sa-east-1, org: nlollmwepnrizxequeym).
