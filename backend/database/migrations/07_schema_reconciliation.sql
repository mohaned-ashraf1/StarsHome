-- ============================================================
-- Issue 4: Supabase PostgreSQL Schema Reconciliation (REVISED)
-- Apply manually via Supabase SQL Editor (Dashboard → SQL Editor)
-- Version: 2026-10-27 (Pre-Production Review)
--
-- SAFETY:
--   All statements use IF NOT EXISTS / ADD COLUMN IF NOT EXISTS.
--   No DROP, no TRUNCATE, no data-destroying operations.
--   Safe to run multiple times (idempotent).
--
-- ROLLBACK PLAN (documented per section):
--   If any section fails, the ROLLBACK statements at the bottom
--   can undo the structural changes.
--   Data changes (UPDATE) cannot be automatically rolled back —
--   a database backup before applying is MANDATORY.
--
-- PRE-REQUISITE:
--   Create a full Supabase backup via:
--   Dashboard → Settings → Backups → Create Backup
--   OR use pg_dump:
--   pg_dump -h [host] -U postgres -d postgres --schema=public > backup_before_migration07.sql
-- ============================================================

-- ── KNOWN INCOMPATIBILITIES BETWEEN MIGRATION 07 AND EXISTING SCHEMA ──
-- 1. PostgreSQL uses UUID PRIMARY KEY (uuid_generate_v4()) in migration 01.
--    Flutter sends TEXT UUIDs (e.g. 'a1b2c3d4-...').
--    PostgreSQL UUID type accepts TEXT-formatted UUIDs — compatible.
--    FIX IN 07: We do NOT change existing UUID columns. Flutter TEXT UUIDs
--    are cast-compatible with PostgreSQL UUID columns.
--
-- 2. Migration 02 (02_rls_and_security.sql) already defines:
--    - is_factory_authorized() function
--    - is_factory_owner() function
--    - RLS policies for purchases, incomes, workers, etc.
--    Migration 08 should NOT recreate these — it should ADD to them.
--    FIX IN 08: See is_factory_authorized() reference in UPDATE policy.
--
-- 3. purchases.is_reversed: migration 01 uses BOOLEAN DEFAULT FALSE.
--    Flutter sends INTEGER 0/1. PostgreSQL BOOLEAN accepts 0/1 — compatible.
--    The ADD COLUMN IF NOT EXISTS will be a no-op since column exists.
--
-- 4. debts_advances and debt_advance_payments do NOT exist in migrations 01-06.
--    These tables are net-new additions.
-- ============================================================

-- ── SECTION 1: purchases — add missing columns ─────────────
-- These columns already exist in PostgreSQL (migration 01); the
-- ADD COLUMN IF NOT EXISTS will be no-ops. Safe to run.
ALTER TABLE public.purchases
  ADD COLUMN IF NOT EXISTS sync_status TEXT DEFAULT 'synced',
  ADD COLUMN IF NOT EXISTS source_type TEXT DEFAULT 'direct',
  ADD COLUMN IF NOT EXISTS source_id TEXT;
-- Note: quantity, unit_price, is_reversed already defined in migration 01.
-- Note: sync_status is SQLite-side only; safe to add for sync tracking.

-- ── SECTION 2: incomes — add missing columns ───────────────
ALTER TABLE public.incomes
  ADD COLUMN IF NOT EXISTS sync_status TEXT DEFAULT 'synced';
-- Note: is_reversed already defined in migration 01 as BOOLEAN.

-- ── SECTION 3: debts_advances — create if not exists ───────
-- This table is NOT present in migrations 01-06 — genuine new addition.
CREATE TABLE IF NOT EXISTS public.debts_advances (
  id TEXT PRIMARY KEY,              -- TEXT to match Flutter UUID generation
  person_name TEXT NOT NULL,
  phone TEXT,
  type TEXT NOT NULL CHECK (type IN ('advance', 'debt_receivable', 'debt_payable')),
  amount NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
  paid_amount NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (paid_amount >= 0),
  transaction_date DATE NOT NULL,
  due_date DATE,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'settled')),
  notes TEXT,
  created_by TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── SECTION 4: debt_advance_payments — create if not exists ─
CREATE TABLE IF NOT EXISTS public.debt_advance_payments (
  id TEXT PRIMARY KEY,
  debt_advance_id TEXT NOT NULL,    -- FK declared separately for deferred enforcement
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  payment_date DATE NOT NULL,
  notes TEXT,
  created_by TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Add FK constraint separately (only if not already present)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'fk_debt_payment_parent'
      AND table_name = 'debt_advance_payments'
  ) THEN
    ALTER TABLE public.debt_advance_payments
      ADD CONSTRAINT fk_debt_payment_parent
      FOREIGN KEY (debt_advance_id) REFERENCES public.debts_advances(id) ON DELETE CASCADE;
  END IF;
END;
$$;

-- ── SECTION 5: inventory_items — add missing columns ────────
-- minimum_limit exists in migration 05; minimum_stock_level is SQLite name.
-- Add both for cross-compatibility.
ALTER TABLE public.inventory_items
  ADD COLUMN IF NOT EXISTS minimum_stock_level NUMERIC(12,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS supplier_name TEXT;

-- Sync minimum_limit → minimum_stock_level (safe data update, no deletes)
UPDATE public.inventory_items
SET minimum_stock_level = COALESCE(minimum_limit, 0)
WHERE minimum_stock_level = 0 AND minimum_limit IS NOT NULL;

-- ── SECTION 6: material_shortages — add missing columns ─────
ALTER TABLE public.material_shortages
  ADD COLUMN IF NOT EXISTS quantity NUMERIC(12,2),
  ADD COLUMN IF NOT EXISTS specifications TEXT,
  ADD COLUMN IF NOT EXISTS manufacturing_order_number TEXT;

-- ── SECTION 7: manufacturing_orders — add missing columns ───
ALTER TABLE public.manufacturing_orders
  ADD COLUMN IF NOT EXISTS sections_data TEXT,
  ADD COLUMN IF NOT EXISTS customer_name TEXT,
  ADD COLUMN IF NOT EXISTS product_category TEXT DEFAULT 'أثاث خشبي',
  ADD COLUMN IF NOT EXISTS quantity INTEGER DEFAULT 1,
  ADD COLUMN IF NOT EXISTS assigned_worker_id TEXT,
  ADD COLUMN IF NOT EXISTS assigned_worker_name TEXT;

-- ── SECTION 8: manufacturing_order_dimensions ───────────────
ALTER TABLE public.manufacturing_order_dimensions
  ADD COLUMN IF NOT EXISTS additional_notes TEXT;

-- ── SECTION 9: manufacturing_order_materials ─────────────────
ALTER TABLE public.manufacturing_order_materials
  ADD COLUMN IF NOT EXISTS thickness_grade TEXT,
  ADD COLUMN IF NOT EXISTS color_code TEXT,
  ADD COLUMN IF NOT EXISTS linked_piece TEXT,
  ADD COLUMN IF NOT EXISTS specifications TEXT;

-- ── SECTION 10: sync_queue — add last_error ─────────────────
-- sync_queue may not exist in PostgreSQL (it's primarily a local SQLite table).
-- Create it for multi-device scenarios where remote queue tracking is needed.
CREATE TABLE IF NOT EXISTS public.sync_queue (
  id TEXT PRIMARY KEY,
  table_name TEXT NOT NULL,
  operation TEXT NOT NULL CHECK (operation IN ('insert', 'update', 'delete')),
  record_id TEXT NOT NULL,
  payload JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  retry_count INTEGER DEFAULT 0,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed')),
  last_error TEXT
);

ALTER TABLE public.sync_queue
  ADD COLUMN IF NOT EXISTS last_error TEXT;

-- ── SECTION 11: Performance Indexes ─────────────────────────
CREATE INDEX IF NOT EXISTS idx_purchases_date ON public.purchases (transaction_date);
CREATE INDEX IF NOT EXISTS idx_incomes_date ON public.incomes (transaction_date);
CREATE INDEX IF NOT EXISTS idx_debt_payments_parent ON public.debt_advance_payments (debt_advance_id);
CREATE INDEX IF NOT EXISTS idx_debts_status ON public.debts_advances (status);
CREATE INDEX IF NOT EXISTS idx_debts_type ON public.debts_advances (type);
CREATE INDEX IF NOT EXISTS idx_mfg_orders_status ON public.manufacturing_orders (status);
CREATE INDEX IF NOT EXISTS idx_shortages_status ON public.material_shortages (status);

-- ── SECTION 12: updated_at triggers ─────────────────────────
-- Only creates/replaces triggers. Does NOT modify data.
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'purchases', 'incomes', 'workers', 'contractors',
    'customer_orders', 'manufacturing_orders',
    'debts_advances', 'inventory_items', 'material_shortages'
  ] LOOP
    EXECUTE format(
      'DROP TRIGGER IF EXISTS trg_%I_updated_at ON public.%I;
       CREATE TRIGGER trg_%I_updated_at
         BEFORE UPDATE ON public.%I
         FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();',
      t, t, t, t
    );
  END LOOP;
END;
$$;

-- ══════════════════════════════════════════════════════════════
-- ROLLBACK PLAN
-- Execute this block ONLY if migration causes problems.
-- WARNING: DROP COLUMN permanently destroys data in that column.
-- Only run after confirming a backup was taken.
-- ══════════════════════════════════════════════════════════════
/*
-- Rollback Section 1 (purchases new columns):
ALTER TABLE public.purchases DROP COLUMN IF EXISTS sync_status;

-- Rollback Section 2 (incomes new columns):
ALTER TABLE public.incomes DROP COLUMN IF EXISTS sync_status;

-- Rollback Section 3 (debts_advances): WARNING — deletes all debt records
DROP TABLE IF EXISTS public.debt_advance_payments;
DROP TABLE IF EXISTS public.debts_advances;

-- Rollback Section 5 (inventory):
ALTER TABLE public.inventory_items DROP COLUMN IF EXISTS minimum_stock_level;
ALTER TABLE public.inventory_items DROP COLUMN IF EXISTS supplier_name;

-- Rollback Section 7 (manufacturing_orders):
ALTER TABLE public.manufacturing_orders DROP COLUMN IF EXISTS sections_data;
ALTER TABLE public.manufacturing_orders DROP COLUMN IF EXISTS customer_name;
ALTER TABLE public.manufacturing_orders DROP COLUMN IF EXISTS product_category;
ALTER TABLE public.manufacturing_orders DROP COLUMN IF EXISTS quantity;
ALTER TABLE public.manufacturing_orders DROP COLUMN IF EXISTS assigned_worker_id;
ALTER TABLE public.manufacturing_orders DROP COLUMN IF EXISTS assigned_worker_name;

-- Rollback triggers:
DROP TRIGGER IF EXISTS trg_purchases_updated_at ON public.purchases;
DROP TRIGGER IF EXISTS trg_incomes_updated_at ON public.incomes;
-- (etc. for remaining tables)
*/
