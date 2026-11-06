-- ============================================================
-- STARS HOMES ERP — Migration 09: Supabase Auth Setup
-- For One Shared Factory Database Across Unlimited Devices
-- Version: 2026-10-27
--
-- PURPOSE:
--   Configure Supabase Auth so that:
--   1. Factory has 2 named accounts: owner + manager
--   2. Each account is linked to public.profiles with the correct role
--   3. is_factory_authorized() works for both accounts
--   4. Any authorized device can sign in using these accounts
--   5. New devices can join without rebuilding the app
--
-- APPLY ORDER:
--   01 → 02 → 03 → 04 → 05 → 06 → 07 → 09 → 08
--   (Apply 07 before 09 to ensure debts tables exist)
--   (Apply 08 LAST — only after Auth accounts exist and are tested)
--
-- PRE-REQUISITES:
--   - Supabase project exists
--   - Migrations 01-07 applied
--   - NOT applied in production without backup
--
-- STEPS REQUIRED IN SUPABASE DASHBOARD (cannot be done via SQL):
--   Step 1: Create Auth users (Dashboard → Authentication → Users → Add user)
--     - Email: owner@starshomes.factory  Password: [set securely]
--     - Email: manager@starshomes.factory Password: [set securely]
--     Note: Use ANY email domain you control. The examples above are illustrative.
--     Note: Record the auto-generated UUIDs — you need them for Step 2.
--
-- STEP 2 (SQL — run this file after Step 1):
--   Fill in the actual UUIDs from Step 1 into the variables below.
-- ============================================================

-- ── STEP 2: Insert into public.profiles ─────────────────────
-- REPLACE these placeholder UUIDs with the actual UUIDs from Supabase Auth!
-- You can find them in Dashboard → Authentication → Users

DO $$
DECLARE
  -- REPLACE with actual UUID from Supabase Auth → Users → owner account
  owner_uid UUID := '00000000-0000-0000-0000-000000000001';
  -- REPLACE with actual UUID from Supabase Auth → Users → manager account
  manager_uid UUID := '00000000-0000-0000-0000-000000000002';
BEGIN
  -- Insert owner profile (idempotent — updates if exists)
  INSERT INTO public.profiles (id, full_name, role, is_active, created_at, updated_at)
  VALUES (owner_uid, 'مالك المصنع', 'owner', TRUE, now(), now())
  ON CONFLICT (id) DO UPDATE
    SET role = 'owner',
        is_active = TRUE,
        updated_at = now();

  -- Insert manager profile
  INSERT INTO public.profiles (id, full_name, role, is_active, created_at, updated_at)
  VALUES (manager_uid, 'مدير المصنع', 'manager', TRUE, now(), now())
  ON CONFLICT (id) DO UPDATE
    SET role = 'manager',
        is_active = TRUE,
        updated_at = now();

  RAISE NOTICE 'Factory profiles created: owner=% manager=%', owner_uid, manager_uid;
END;
$$;

-- ── STEP 3: Verify the setup ────────────────────────────────
-- Run this query after applying — should return 2 rows
SELECT id, full_name, role, is_active FROM public.profiles
WHERE role IN ('owner', 'manager') AND is_active = TRUE;

-- ── STEP 4: Test is_factory_authorized() ────────────────────
-- In Supabase SQL Editor, authenticate as the owner user first, then run:
-- SELECT public.is_factory_authorized(); -- Should return TRUE
-- SELECT public.is_factory_owner();      -- Should return TRUE (for owner)

-- ── STEP 5: Update RLS policies to handle new tables ────────
-- Ensure all tables from Migration 06 and 07 have profiles-based RLS.
-- Migration 08 handles this — apply it after verifying steps 1-4.

-- ── DEVICE AUTHORIZATION FLOW ───────────────────────────────
-- For the FIRST device (factory owner's device):
--   1. Go to Settings → Supabase Configuration
--   2. Enter Supabase URL and anon key
--   3. Go to Settings → Authorize This Device → Owner
--   4. Enter email: owner@starshomes.factory + password
--   5. App verifies, saves locally, triggers initial sync

-- For ADDITIONAL devices (any phone or tablet):
--   1. Install the app
--   2. Go to Settings → Supabase Configuration → Enter URL + anon key
--   3. Go to Settings → Authorize This Device → Choose role
--   4. Enter factory account email + password for that role
--   5. App verifies against Supabase, pulls all factory data
--   NOTE: No app rebuild required. Any number of devices supported.

-- ── SECURITY NOTES ──────────────────────────────────────────
-- 1. The owner@starshomes.factory and manager@starshomes.factory accounts
--    belong to the FACTORY, not to individual people.
--    Multiple authorized devices share the same factory account.
--    This is the correct model for a shared-access ERP system.
--
-- 2. Individual user tracking: if you need to track which physical person
--    made each change, add a 'device_name' or 'operator_name' field to
--    business records. The factory account role identifies authorization level.
--
-- 3. Changing factory account password revokes access to ALL devices using
--    that role's account. To revoke a single device, use a different approach
--    (e.g., per-device accounts with same role in profiles).
--
-- 4. The Supabase anon key is shared across all devices — this is by design.
--    The anon key has limited privileges; RLS policies restrict data access.
--    The factory account password is the real secret.
--
-- 5. The service_role key must NEVER be embedded in the Flutter app.
--    It is only for server-side operations (Edge Functions, migrations).

-- ── ROLLBACK ────────────────────────────────────────────────
/*
-- To remove factory profiles (does NOT delete Auth users):
DELETE FROM public.profiles WHERE role IN ('owner', 'manager');

-- To deactivate a role without deleting:
UPDATE public.profiles SET is_active = FALSE WHERE role = 'manager';

-- To delete Auth users: use Supabase Dashboard → Authentication → Users → Delete
*/

-- ── MULTI-DEVICE TEST CHECKLIST ─────────────────────────────
-- After applying this migration and Migration 08:
--
-- Test 1: New device joins
--   [ ] Install app on new device
--   [ ] Enter Supabase URL + anon key
--   [ ] Enter factory account credentials
--   [ ] Verify app pulls all existing factory data after sync
--
-- Test 2: Insert propagation
--   [ ] Device A adds a purchase offline
--   [ ] Device A goes online → sync completes
--   [ ] Device B syncs → purchase appears on Device B
--
-- Test 3: Concurrent edits
--   [ ] Device A and Device B edit the same record offline
--   [ ] Both sync → Last-Write-Wins applied based on updated_at
--   [ ] Verify no data loss (both changes recorded in history)
--
-- Test 4: Dataset > 200 records
--   [ ] Insert 300+ purchases via seed script or manual entry
--   [ ] Sync on a fresh device
--   [ ] Verify ALL 300+ records pulled (keyset pagination test)
--
-- Test 5: Unauthorized access
--   [ ] Use REST client without auth header → should get 0 rows
--   [ ] Use wrong credentials → should get auth error
--   [ ] Sign in as owner → can delete records
--   [ ] Sign in as manager → delete attempt should be blocked by RLS
--
-- Test 6: Financial totals accuracy
--   [ ] Insert 400 purchases across devices
--   [ ] Verify dashboard total matches SQL: SELECT SUM(total_amount) FROM purchases
--
-- Test 7: Offline-to-online
--   [ ] Make 10 changes offline on Device A
--   [ ] Restore connectivity
--   [ ] All 10 changes upload successfully
--   [ ] Device B sees all changes after sync
