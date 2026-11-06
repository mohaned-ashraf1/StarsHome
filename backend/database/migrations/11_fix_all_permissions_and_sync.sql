-- ============================================================
-- STARS HOMES ERP — Migration 11: Fix All Permissions & RLS
-- For Shared Factory Multi-Device Sync (Postgres + Supabase)
-- Project: rxbepjrwowtkhonebcsp
-- ============================================================

-- 0. Drop foreign key constraint on profiles so it accepts factory users
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;

-- 1. Grant schema usage to anon and authenticated roles
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

-- 2. Grant table permissions to anon and authenticated
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated, service_role;

-- 3. Default privileges for any future tables created
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO anon, authenticated, service_role;

-- 4. Enable RLS and add permissive policies for shared factory access
DO $$
DECLARE
    tbl text;
    tables text[] := ARRAY[
        'profiles',
        'categories',
        'item_suggestions',
        'purchases',
        'incomes',
        'workers',
        'worker_attendance',
        'worker_financial_items',
        'worker_payroll_settlements',
        'contractors',
        'contractor_payments',
        'customer_orders',
        'order_payments',
        'debts_advances',
        'debt_advance_payments',
        'inventory_items',
        'inventory_movements',
        'manufacturing_orders',
        'manufacturing_order_dimensions',
        'manufacturing_order_materials',
        'manufacturing_checklist',
        'inventory_reservations',
        'material_shortages',
        'audit_logs'
    ];
BEGIN
    FOREACH tbl IN ARRAY tables LOOP
        -- Ensure table exists before applying policies
        IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = tbl) THEN
            -- Enable Row Level Security
            EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;', tbl);

            -- Drop old policies to avoid duplicate name errors
            EXECUTE format('DROP POLICY IF EXISTS "factory_anon_full_access" ON public.%I;', tbl);
            EXECUTE format('DROP POLICY IF EXISTS "factory_auth_full_access" ON public.%I;', tbl);
            EXECUTE format('DROP POLICY IF EXISTS "allow_all_factory" ON public.%I;', tbl);

            -- Create permissive policy for factory operations (anon + authenticated)
            EXECUTE format('
                CREATE POLICY "allow_all_factory" ON public.%I
                FOR ALL
                TO anon, authenticated
                USING (true)
                WITH CHECK (true);
            ', tbl);
        END IF;
    END LOOP;
END;
$$;

-- 5. Ensure default Profiles exist for Factory Owner and Manager
INSERT INTO public.profiles (id, full_name, role, is_active, created_at, updated_at)
VALUES 
    ('00000000-0000-0000-0000-000000000001', 'مالك المصنع', 'owner', TRUE, now(), now()),
    ('00000000-0000-0000-0000-000000000002', 'مدير المصنع', 'manager', TRUE, now(), now())
ON CONFLICT (id) DO UPDATE 
SET is_active = TRUE, updated_at = now();

-- 6. Grant select on all Views (المخزن, النواقص, حركات_المخزن)
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated;

-- Output confirmation
SELECT 'Permissions and RLS successfully configured for Stars Homes Factory!' AS status;

