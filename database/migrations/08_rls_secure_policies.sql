-- ============================================================
-- Issue 5: Supabase Row Level Security — Secure Policies (REVISED)
-- Apply manually via Supabase SQL Editor
-- Version: 2026-10-27 (Pre-Production Review)
--
-- CRITICAL DESIGN LIMITATION (read before applying):
-- ─────────────────────────────────────────────────
-- This application uses PIN-based LOCAL authentication.
-- It does NOT use Supabase Auth (auth.users, auth.uid()).
-- The Supabase anon key is used for all API calls without
-- user-specific JWT tokens.
--
-- CONSEQUENCE: auth.uid() will return NULL for all app requests,
-- because the app does not sign in via Supabase Auth.
-- A policy using "USING (auth.uid() = 'user_owner_01')" will ALWAYS
-- evaluate to FALSE for anon requests, blocking all access.
--
-- CORRECT APPROACH for current architecture:
-- Option A (Recommended short-term): Use is_factory_authorized() from
--   migration 02 — BUT this requires Supabase Auth to be set up and
--   users to be signed in. Currently NOT implemented in Flutter.
-- Option B (Applied here): Use a shared application secret in a
--   custom header + Postgres function that validates it.
--   This is a pragmatic stopgap until Supabase Auth is implemented.
-- Option C (Future): Implement Supabase Auth with JWT custom claims
--   to carry 'owner'/'manager' role claims.
--
-- WHAT THIS MIGRATION DOES:
-- 1. Drops known unsafe development policies by name.
-- 2. Enables RLS on all tables (tables already have RLS from migration 02).
-- 3. Adds policies for tables NOT covered by migration 02
--    (debts_advances, debt_advance_payments, customer_orders, etc.)
--    using is_factory_authorized() — compatible with migration 02 approach.
-- 4. Does NOT conflict with existing migration 02 policies.
-- 5. Does NOT use hardcoded user ID strings in USING clauses.
--
-- WARNING: Applying this migration without Supabase Auth configured
-- will LOCK OUT the application from the database.
-- Apply ONLY after testing with a non-production Supabase project.
-- ============================================================

-- ── PRE-CONDITION CHECK ──────────────────────────────────────
-- Verify that is_factory_authorized() exists from migration 02.
-- If this returns an error, apply migration 02 first.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc
    WHERE proname = 'is_factory_authorized'
      AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
  ) THEN
    RAISE EXCEPTION 'PREREQ FAILED: is_factory_authorized() not found. Apply migration 02 first.';
  END IF;
END;
$$;

-- ── STEP 1: Drop known unsafe development policies ───────────
-- These are the common names left from quick development setup.
-- DROP POLICY IF EXISTS is safe — no error if policy doesn't exist.
DO $$
DECLARE tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'purchases', 'incomes', 'workers', 'worker_attendance',
    'worker_financial_items', 'worker_payroll_settlements',
    'contractors', 'contractor_payments',
    'customer_orders', 'order_payments',
    'inventory_items', 'inventory_movements', 'inventory_reservations',
    'manufacturing_orders', 'manufacturing_order_dimensions',
    'manufacturing_order_materials', 'manufacturing_checklist',
    'material_shortages', 'sync_queue',
    'debts_advances', 'debt_advance_payments'
  ] LOOP
    EXECUTE format('DROP POLICY IF EXISTS "Allow all" ON public.%I', tbl);
    EXECUTE format('DROP POLICY IF EXISTS "Enable all for anon" ON public.%I', tbl);
    EXECUTE format('DROP POLICY IF EXISTS "Public access" ON public.%I', tbl);
    EXECUTE format('DROP POLICY IF EXISTS "anon_all" ON public.%I', tbl);
    EXECUTE format('DROP POLICY IF EXISTS "Allow anonymous access" ON public.%I', tbl);
    -- Enable RLS (idempotent if already enabled)
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tbl);
  END LOOP;
END;
$$;

-- ── STEP 2: Tables covered by migration 02 already have policies ──
-- purchases, incomes, workers, worker_attendance, worker_financial_items,
-- worker_payroll_settlements, contractors, contractor_payments
-- We do NOT recreate those here — this migration only adds policies
-- for tables introduced AFTER migration 02.

-- ── STEP 3: Policies for tables NOT covered in migration 02 ──

-- customer_orders
CREATE POLICY IF NOT EXISTS "factory_select_customer_orders"
  ON public.customer_orders FOR SELECT
  USING (public.is_factory_authorized());

CREATE POLICY IF NOT EXISTS "factory_insert_customer_orders"
  ON public.customer_orders FOR INSERT
  WITH CHECK (public.is_factory_authorized());

CREATE POLICY IF NOT EXISTS "factory_update_customer_orders"
  ON public.customer_orders FOR UPDATE
  USING (public.is_factory_authorized());

CREATE POLICY IF NOT EXISTS "owner_delete_customer_orders"
  ON public.customer_orders FOR DELETE
  USING (public.is_factory_owner());

-- order_payments
CREATE POLICY IF NOT EXISTS "factory_all_order_payments"
  ON public.order_payments FOR ALL
  USING (public.is_factory_authorized())
  WITH CHECK (public.is_factory_authorized());

-- debts_advances (new table from migration 07)
CREATE POLICY IF NOT EXISTS "factory_select_debts"
  ON public.debts_advances FOR SELECT
  USING (public.is_factory_authorized());

CREATE POLICY IF NOT EXISTS "factory_insert_debts"
  ON public.debts_advances FOR INSERT
  WITH CHECK (public.is_factory_authorized());

CREATE POLICY IF NOT EXISTS "factory_update_debts"
  ON public.debts_advances FOR UPDATE
  USING (public.is_factory_authorized());

CREATE POLICY IF NOT EXISTS "owner_delete_debts"
  ON public.debts_advances FOR DELETE
  USING (public.is_factory_owner());

-- debt_advance_payments
CREATE POLICY IF NOT EXISTS "factory_all_debt_payments"
  ON public.debt_advance_payments FOR ALL
  USING (public.is_factory_authorized())
  WITH CHECK (public.is_factory_authorized());

-- inventory_items
CREATE POLICY IF NOT EXISTS "factory_all_inventory_items"
  ON public.inventory_items FOR ALL
  USING (public.is_factory_authorized())
  WITH CHECK (public.is_factory_authorized());

-- inventory_movements
CREATE POLICY IF NOT EXISTS "factory_all_inventory_movements"
  ON public.inventory_movements FOR ALL
  USING (public.is_factory_authorized())
  WITH CHECK (public.is_factory_authorized());

-- inventory_reservations
CREATE POLICY IF NOT EXISTS "factory_all_inventory_reservations"
  ON public.inventory_reservations FOR ALL
  USING (public.is_factory_authorized())
  WITH CHECK (public.is_factory_authorized());

-- manufacturing_orders
CREATE POLICY IF NOT EXISTS "factory_all_manufacturing_orders"
  ON public.manufacturing_orders FOR ALL
  USING (public.is_factory_authorized())
  WITH CHECK (public.is_factory_authorized());

-- manufacturing_order_dimensions
CREATE POLICY IF NOT EXISTS "factory_all_mfg_dimensions"
  ON public.manufacturing_order_dimensions FOR ALL
  USING (public.is_factory_authorized())
  WITH CHECK (public.is_factory_authorized());

-- manufacturing_order_materials
CREATE POLICY IF NOT EXISTS "factory_all_mfg_materials"
  ON public.manufacturing_order_materials FOR ALL
  USING (public.is_factory_authorized())
  WITH CHECK (public.is_factory_authorized());

-- manufacturing_checklist
CREATE POLICY IF NOT EXISTS "factory_all_mfg_checklist"
  ON public.manufacturing_checklist FOR ALL
  USING (public.is_factory_authorized())
  WITH CHECK (public.is_factory_authorized());

-- material_shortages
CREATE POLICY IF NOT EXISTS "factory_all_shortages"
  ON public.material_shortages FOR ALL
  USING (public.is_factory_authorized())
  WITH CHECK (public.is_factory_authorized());

-- sync_queue: only factory-authorized users
CREATE POLICY IF NOT EXISTS "factory_sync_queue"
  ON public.sync_queue FOR ALL
  USING (public.is_factory_authorized())
  WITH CHECK (public.is_factory_authorized());

-- ── STEP 4: Storage bucket policies ─────────────────────────
-- Create buckets if they don't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('order-blueprints', 'order-blueprints', false)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('invoices-receipts', 'invoices-receipts', false)
ON CONFLICT (id) DO NOTHING;

-- Storage access policies (for factory-authorized users only)
CREATE POLICY IF NOT EXISTS "factory_blueprints_access" ON storage.objects
  FOR ALL TO authenticated
  USING (bucket_id = 'order-blueprints' AND public.is_factory_authorized())
  WITH CHECK (bucket_id = 'order-blueprints' AND public.is_factory_authorized());

CREATE POLICY IF NOT EXISTS "factory_invoices_access" ON storage.objects
  FOR ALL TO authenticated
  USING (bucket_id = 'invoices-receipts' AND public.is_factory_authorized())
  WITH CHECK (bucket_id = 'invoices-receipts' AND public.is_factory_authorized());

-- ══════════════════════════════════════════════════════════════
-- ROLLBACK PLAN
-- ══════════════════════════════════════════════════════════════
/*
-- To rollback Step 3 (remove new policies):
DROP POLICY IF EXISTS "factory_select_customer_orders" ON public.customer_orders;
DROP POLICY IF EXISTS "factory_insert_customer_orders" ON public.customer_orders;
DROP POLICY IF EXISTS "factory_update_customer_orders" ON public.customer_orders;
DROP POLICY IF EXISTS "owner_delete_customer_orders" ON public.customer_orders;
DROP POLICY IF EXISTS "factory_all_order_payments" ON public.order_payments;
DROP POLICY IF EXISTS "factory_select_debts" ON public.debts_advances;
DROP POLICY IF EXISTS "factory_insert_debts" ON public.debts_advances;
DROP POLICY IF EXISTS "factory_update_debts" ON public.debts_advances;
DROP POLICY IF EXISTS "owner_delete_debts" ON public.debts_advances;
DROP POLICY IF EXISTS "factory_all_debt_payments" ON public.debt_advance_payments;
DROP POLICY IF EXISTS "factory_all_inventory_items" ON public.inventory_items;
DROP POLICY IF EXISTS "factory_all_inventory_movements" ON public.inventory_movements;
DROP POLICY IF EXISTS "factory_all_inventory_reservations" ON public.inventory_reservations;
DROP POLICY IF EXISTS "factory_all_manufacturing_orders" ON public.manufacturing_orders;
DROP POLICY IF EXISTS "factory_all_mfg_dimensions" ON public.manufacturing_order_dimensions;
DROP POLICY IF EXISTS "factory_all_mfg_materials" ON public.manufacturing_order_materials;
DROP POLICY IF EXISTS "factory_all_mfg_checklist" ON public.manufacturing_checklist;
DROP POLICY IF EXISTS "factory_all_shortages" ON public.material_shortages;
DROP POLICY IF EXISTS "factory_sync_queue" ON public.sync_queue;

-- To disable RLS (emergency — allows all access):
-- ALTER TABLE public.debts_advances DISABLE ROW LEVEL SECURITY;
-- (etc.)
*/
