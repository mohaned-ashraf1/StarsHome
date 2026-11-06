-- ============================================================
-- STARS HOMES ERP — Master Database Schema Initialisation
-- For Supabase PostgreSQL (Fresh Database Setup)
-- Version: 2026-10-27
--
-- This single script creates the entire database structure:
-- 1. Extensions (uuid-ossp, pgcrypto)
-- 2. All 23 business tables with complete columns (sync, offline, multi-device)
-- 3. High-performance indexes
-- 4. Automatic updated_at triggers
-- 5. Authorization helper functions (is_factory_authorized, is_factory_owner)
-- 6. Initial RLS policies
-- 7. Seed data (categories, suggestions, default contractors)
-- ============================================================

-- ── 1. EXTENSIONS ───────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── 2. PROFILES & AUTH ROLES ────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('owner', 'manager')),
    phone TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 3. CATEGORIES & SUGGESTIONS ─────────────────────────────
CREATE TABLE IF NOT EXISTS public.categories (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    name TEXT NOT NULL UNIQUE,
    type TEXT NOT NULL DEFAULT 'expense' CHECK (type IN ('expense', 'income')),
    is_reusable BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.item_suggestions (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    item_name TEXT NOT NULL UNIQUE,
    default_category TEXT,
    last_unit_price NUMERIC(12, 2) DEFAULT 0,
    times_used INTEGER DEFAULT 1,
    last_used_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 4. PURCHASES & EXPENSES (المشتريات والمصروفات) ────────────
CREATE TABLE IF NOT EXISTS public.purchases (
    id TEXT PRIMARY KEY,
    item_name TEXT NOT NULL,
    category TEXT NOT NULL,
    quantity NUMERIC(12, 2),
    unit_price NUMERIC(12, 2),
    total_amount NUMERIC(12, 2) NOT NULL,
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT,
    source_type TEXT DEFAULT 'direct',
    source_id TEXT,
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_reversed BOOLEAN DEFAULT FALSE,
    reversed_at TIMESTAMPTZ,
    reversed_by TEXT,
    sync_status TEXT DEFAULT 'synced',
    device_id TEXT
);

-- ── 5. FACTORY INCOMES (الدخل والإيرادات) ─────────────────────
CREATE TABLE IF NOT EXISTS public.incomes (
    id TEXT PRIMARY KEY,
    source_name TEXT NOT NULL,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT,
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_reversed BOOLEAN DEFAULT FALSE,
    reversed_at TIMESTAMPTZ,
    reversed_by TEXT,
    sync_status TEXT DEFAULT 'synced',
    device_id TEXT
);

-- ── 6. WORKERS & PAYROLL (العمال والرواتب) ───────────────────
CREATE TABLE IF NOT EXISTS public.workers (
    id TEXT PRIMARY KEY,
    full_name TEXT NOT NULL,
    daily_wage NUMERIC(12, 2) NOT NULL DEFAULT 0,
    standard_start_time TEXT NOT NULL DEFAULT '08:00',
    standard_end_time TEXT NOT NULL DEFAULT '19:00',
    overtime_hourly_rate NUMERIC(12, 2) NOT NULL DEFAULT 0,
    phone TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    device_id TEXT
);

CREATE TABLE IF NOT EXISTS public.worker_attendance (
    id TEXT PRIMARY KEY,
    worker_id TEXT NOT NULL REFERENCES public.workers(id) ON DELETE CASCADE,
    attendance_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status TEXT NOT NULL CHECK (status IN ('present', 'absent', 'leave')),
    arrival_time TEXT,
    departure_time TEXT,
    total_duration_minutes INTEGER DEFAULT 0,
    overtime_duration_minutes INTEGER DEFAULT 0,
    overtime_pay NUMERIC(12, 2) DEFAULT 0,
    daily_wage_applied NUMERIC(12, 2) NOT NULL DEFAULT 0,
    notes TEXT,
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    device_id TEXT,
    CONSTRAINT unique_worker_date UNIQUE (worker_id, attendance_date)
);

CREATE TABLE IF NOT EXISTS public.worker_financial_items (
    id TEXT PRIMARY KEY,
    worker_id TEXT NOT NULL REFERENCES public.workers(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('advance', 'bonus', 'deduction')),
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    reason_notes TEXT,
    is_settled_in_payroll BOOLEAN DEFAULT FALSE,
    payroll_settlement_id TEXT,
    linked_expense_id TEXT,
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    device_id TEXT
);

CREATE TABLE IF NOT EXISTS public.worker_payroll_settlements (
    id TEXT PRIMARY KEY,
    worker_id TEXT NOT NULL REFERENCES public.workers(id) ON DELETE CASCADE,
    week_start_date DATE NOT NULL,
    week_end_date DATE NOT NULL,
    days_attended INTEGER DEFAULT 0,
    daily_wages_total NUMERIC(12, 2) DEFAULT 0,
    overtime_hours_total NUMERIC(12, 2) DEFAULT 0,
    overtime_pay_total NUMERIC(12, 2) DEFAULT 0,
    bonuses_total NUMERIC(12, 2) DEFAULT 0,
    advances_total NUMERIC(12, 2) DEFAULT 0,
    deductions_total NUMERIC(12, 2) DEFAULT 0,
    gross_earnings NUMERIC(12, 2) NOT NULL DEFAULT 0,
    net_due NUMERIC(12, 2) NOT NULL DEFAULT 0,
    amount_paid NUMERIC(12, 2) NOT NULL DEFAULT 0,
    remaining_balance NUMERIC(12, 2) NOT NULL DEFAULT 0,
    payment_date DATE,
    payment_method TEXT DEFAULT 'cash',
    notes TEXT,
    is_settled BOOLEAN DEFAULT FALSE,
    linked_expense_id TEXT,
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    device_id TEXT
);

-- ── 7. CONTRACTORS (الورش والاشتراكات الخارجية) ─────────────
CREATE TABLE IF NOT EXISTS public.contractors (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    service_type TEXT NOT NULL,
    phone TEXT,
    notes TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    device_id TEXT
);

CREATE TABLE IF NOT EXISTS public.contractor_payments (
    id TEXT PRIMARY KEY,
    contractor_id TEXT NOT NULL REFERENCES public.contractors(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    related_order TEXT,
    notes TEXT,
    linked_expense_id TEXT,
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    device_id TEXT
);

-- ── 8. CUSTOMERS & ORDERS (العملاء والطلبيات) ────────────────
CREATE TABLE IF NOT EXISTS public.customer_orders (
    id TEXT PRIMARY KEY,
    customer_name TEXT NOT NULL,
    phone TEXT,
    order_description TEXT NOT NULL,
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    delivery_date DATE,
    total_amount NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
    status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'ready', 'delivered', 'cancelled')),
    notes TEXT,
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    device_id TEXT
);

CREATE TABLE IF NOT EXISTS public.order_payments (
    id TEXT PRIMARY KEY,
    order_id TEXT NOT NULL REFERENCES public.customer_orders(id) ON DELETE CASCADE,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    payment_method TEXT DEFAULT 'نقدي',
    notes TEXT,
    linked_income_id TEXT,
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    device_id TEXT
);

-- ── 9. DEBTS & ADVANCES (الديون والأمانات الخارجية) ─────────
CREATE TABLE IF NOT EXISTS public.debts_advances (
    id TEXT PRIMARY KEY,
    person_name TEXT NOT NULL,
    phone TEXT,
    type TEXT NOT NULL CHECK (type IN ('advance', 'debt_receivable', 'debt_payable')),
    amount NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
    paid_amount NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (paid_amount >= 0),
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'settled')),
    notes TEXT,
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    device_id TEXT
);

CREATE TABLE IF NOT EXISTS public.debt_advance_payments (
    id TEXT PRIMARY KEY,
    debt_advance_id TEXT NOT NULL REFERENCES public.debts_advances(id) ON DELETE CASCADE,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT,
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    device_id TEXT
);

-- ── 10. INVENTORY (المخزون والمواد الخام) ────────────────────
CREATE TABLE IF NOT EXISTS public.inventory_items (
    id TEXT PRIMARY KEY,
    material_name TEXT NOT NULL UNIQUE,
    category TEXT NOT NULL,
    unit TEXT NOT NULL DEFAULT 'لوح',
    current_stock NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (current_stock >= 0),
    reserved_stock NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (reserved_stock >= 0),
    minimum_stock_level NUMERIC(12, 2) NOT NULL DEFAULT 0,
    unit_cost NUMERIC(12, 2) DEFAULT 0,
    supplier_name TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    device_id TEXT
);

CREATE TABLE IF NOT EXISTS public.inventory_movements (
    id TEXT PRIMARY KEY,
    inventory_item_id TEXT NOT NULL REFERENCES public.inventory_items(id) ON DELETE CASCADE,
    movement_type TEXT NOT NULL CHECK (movement_type IN ('receipt', 'issue', 'adjustment', 'reservation', 'reservation_release', 'return')),
    quantity NUMERIC(12, 2) NOT NULL,
    reference_type TEXT,
    reference_id TEXT,
    reason_notes TEXT,
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    device_id TEXT
);

-- ── 11. MANUFACTURING ORDERS (أوامر التصنيع والورشة) ─────────
CREATE TABLE IF NOT EXISTS public.manufacturing_orders (
    id TEXT PRIMARY KEY,
    order_number TEXT NOT NULL UNIQUE,
    customer_order_id TEXT REFERENCES public.customer_orders(id) ON DELETE SET NULL,
    customer_name TEXT,
    product_name TEXT NOT NULL,
    product_category TEXT NOT NULL DEFAULT 'أثاث خشبي',
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    manufacturing_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expected_completion_date DATE,
    assigned_worker_id TEXT REFERENCES public.workers(id) ON DELETE SET NULL,
    assigned_worker_name TEXT,
    status TEXT NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'awaiting_materials', 'ready_to_build', 'in_progress', 'completed', 'cancelled')),
    notes TEXT,
    sections_data JSONB,
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    device_id TEXT
);

CREATE TABLE IF NOT EXISTS public.manufacturing_order_dimensions (
    id TEXT PRIMARY KEY,
    manufacturing_order_id TEXT NOT NULL REFERENCES public.manufacturing_orders(id) ON DELETE CASCADE,
    height NUMERIC(8, 2),
    width NUMERIC(8, 2),
    depth NUMERIC(8, 2),
    unit TEXT NOT NULL DEFAULT 'سم',
    additional_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    device_id TEXT
);

CREATE TABLE IF NOT EXISTS public.manufacturing_order_materials (
    id TEXT PRIMARY KEY,
    manufacturing_order_id TEXT NOT NULL REFERENCES public.manufacturing_orders(id) ON DELETE CASCADE,
    inventory_item_id TEXT REFERENCES public.inventory_items(id) ON DELETE SET NULL,
    material_name TEXT NOT NULL,
    required_quantity NUMERIC(12, 2) NOT NULL CHECK (required_quantity > 0),
    unit TEXT NOT NULL,
    specifications TEXT,
    notes TEXT,
    thickness_grade TEXT,
    color_code TEXT,
    linked_piece TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    device_id TEXT
);

CREATE TABLE IF NOT EXISTS public.manufacturing_checklist (
    id TEXT PRIMARY KEY,
    manufacturing_order_id TEXT NOT NULL REFERENCES public.manufacturing_orders(id) ON DELETE CASCADE,
    material_name TEXT NOT NULL,
    required_quantity NUMERIC(12, 2) NOT NULL,
    unit TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'required' CHECK (status IN ('required', 'ordered', 'received', 'prepared')),
    is_prepared BOOLEAN NOT NULL DEFAULT FALSE,
    notes TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    device_id TEXT
);

CREATE TABLE IF NOT EXISTS public.inventory_reservations (
    id TEXT PRIMARY KEY,
    manufacturing_order_id TEXT NOT NULL REFERENCES public.manufacturing_orders(id) ON DELETE CASCADE,
    inventory_item_id TEXT NOT NULL REFERENCES public.inventory_items(id) ON DELETE CASCADE,
    reserved_quantity NUMERIC(12, 2) NOT NULL CHECK (reserved_quantity > 0),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'released', 'consumed')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    device_id TEXT
);

-- ── 12. MATERIAL SHORTAGES (النواقص المستقلة) ─────────────────
CREATE TABLE IF NOT EXISTS public.material_shortages (
    id TEXT PRIMARY KEY,
    material_name TEXT NOT NULL,
    quantity NUMERIC(12, 2),
    unit TEXT NOT NULL DEFAULT 'لوح',
    specifications TEXT,
    notes TEXT,
    manufacturing_order_id TEXT REFERENCES public.manufacturing_orders(id) ON DELETE SET NULL,
    manufacturing_order_number TEXT,
    status TEXT NOT NULL DEFAULT 'shortage' CHECK (status IN ('shortage', 'in_progress', 'resolved', 'reopened')),
    recorded_by TEXT NOT NULL,
    recorded_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_by TEXT,
    resolved_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    device_id TEXT
);

-- ── 13. AUDIT LOG (سجل التدقيق والتتبع) ──────────────────────
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_name TEXT NOT NULL,
    action TEXT NOT NULL,
    entity_table TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 14. PERFORMANCE INDEXES ─────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_purchases_date ON public.purchases (transaction_date);
CREATE INDEX IF NOT EXISTS idx_incomes_date ON public.incomes (transaction_date);
CREATE INDEX IF NOT EXISTS idx_attendance_worker_date ON public.worker_attendance (worker_id, attendance_date);
CREATE INDEX IF NOT EXISTS idx_financial_worker_date ON public.worker_financial_items (worker_id, transaction_date);
CREATE INDEX IF NOT EXISTS idx_contractor_payments_date ON public.contractor_payments (payment_date);
CREATE INDEX IF NOT EXISTS idx_contractor_payments_contractor ON public.contractor_payments (contractor_id);
CREATE INDEX IF NOT EXISTS idx_customer_orders_date ON public.customer_orders (start_date);
CREATE INDEX IF NOT EXISTS idx_order_payments_order ON public.order_payments (order_id);
CREATE INDEX IF NOT EXISTS idx_debts_status ON public.debts_advances (status);
CREATE INDEX IF NOT EXISTS idx_debts_type ON public.debts_advances (type);
CREATE INDEX IF NOT EXISTS idx_debt_payments_debt ON public.debt_advance_payments (debt_advance_id);
CREATE INDEX IF NOT EXISTS idx_mfg_orders_status ON public.manufacturing_orders (status);
CREATE INDEX IF NOT EXISTS idx_mfg_orders_date ON public.manufacturing_orders (manufacturing_date);
CREATE INDEX IF NOT EXISTS idx_shortages_status ON public.material_shortages (status);

-- ── 15. AUTOMATIC updated_at TRIGGER FUNCTION ────────────────
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

-- ── 16. AUTHORIZATION HELPER FUNCTIONS ───────────────────────
CREATE OR REPLACE FUNCTION public.is_factory_authorized()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid()
        AND is_active = TRUE
        AND role IN ('owner', 'manager')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_factory_owner()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid()
        AND is_active = TRUE
        AND role = 'owner'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── 17. INITIAL PERMISSIVE RLS POLICIES (SETUP MODE) ──────────
-- Enables RLS on all tables and allows authenticated app access
DO $$
DECLARE
  t TEXT;
  tbls TEXT[] := ARRAY[
    'profiles', 'categories', 'item_suggestions', 'purchases', 'incomes',
    'workers', 'worker_attendance', 'worker_financial_items', 'worker_payroll_settlements',
    'contractors', 'contractor_payments', 'customer_orders', 'order_payments',
    'debts_advances', 'debt_advance_payments', 'inventory_items', 'inventory_movements',
    'manufacturing_orders', 'manufacturing_order_dimensions', 'manufacturing_order_materials',
    'manufacturing_checklist', 'inventory_reservations', 'material_shortages', 'audit_logs'
  ];
BEGIN
  FOREACH t IN ARRAY tbls LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;', t);
    EXECUTE format('DROP POLICY IF EXISTS "allow_auth_all_%I" ON public.%I;', t, t);
    EXECUTE format('CREATE POLICY "allow_auth_all_%I" ON public.%I FOR ALL TO authenticated USING (true) WITH CHECK (true);', t, t);
    -- Development/Initial setup policy for anon key
    EXECUTE format('DROP POLICY IF EXISTS "allow_anon_all_%I" ON public.%I;', t, t);
    EXECUTE format('CREATE POLICY "allow_anon_all_%I" ON public.%I FOR ALL TO anon USING (true) WITH CHECK (true);', t, t);
  END LOOP;
END;
$$;

-- ── 18. SEED DATA ────────────────────────────────────────────
INSERT INTO public.categories (name, type) VALUES
('أخشاب ومواد خام', 'expense'),
('إكسسوارات ومعدات', 'expense'),
('أقمشة وجلود', 'expense'),
('وقود وصيانة سيارات', 'expense'),
('نقل وتروسيكل', 'expense'),
('مصاريف عمال وضيافة', 'expense'),
('ورش واشتراكات خارجية', 'expense'),
('فواتير ومرافق مصنع', 'expense'),
('مصروفات نثرية أخرى', 'expense')
ON CONFLICT (name) DO NOTHING;

INSERT INTO public.item_suggestions (item_name, default_category, last_unit_price, times_used) VALUES
('خشب زان', 'أخشاب ومواد خام', 14500.00, 10),
('خشب عادي (سويد)', 'أخشاب ومواد خام', 9200.00, 8),
('أبلكاش كوري', 'أخشاب ومواد خام', 350.00, 15),
('أبلكاش سيه', 'أخشاب ومواد خام', 290.00, 12),
('كونتر اندونيسي', 'أخشاب ومواد خام', 850.00, 6),
('ألواح MDF مستورد', 'أخشاب ومواد خام', 720.00, 9),
('إكسسوارات ومقابض', 'إكسسوارات ومعدات', 0, 5),
('مفصلات هيدروليك', 'إكسسوارات ومعدات', 45.00, 8),
('مسامير وغراء ألماني', 'إكسسوارات ومعدات', 0, 7),
('عدة وأدوات ورشة', 'إكسسوارات ومعدات', 0, 4),
('جلد تركي فاخر', 'أقمشة وجلود', 220.00, 6),
('قماش قطيفة تنجيد', 'أقمشة وجلود', 180.00, 10),
('بنزين سيارة المصنع', 'وقود وصيانة سيارات', 0, 20),
('صيانة وغيار زيت السيارة', 'وقود وصيانة سيارات', 0, 4),
('نقل وتروسيكل مشاوير', 'نقل وتروسيكل', 0, 14),
('وجبات ومشروبات العمال', 'مصاريف عمال وضيافة', 0, 25)
ON CONFLICT (item_name) DO NOTHING;

INSERT INTO public.contractors (id, name, service_type, notes, status) VALUES
(gen_random_uuid()::text, 'ورشة الدهان الحديث (المعلم رجب)', 'الدهان', 'دهانات أستر ودوكو وبوليستر لغرف النوم والسفرة', 'active'),
(gen_random_uuid()::text, 'ورشة التنجيد الراقي (المعلم صابر)', 'التنجيد', 'تنجيد صالونات وركنيات وأنتريهات إسفنج كثافة 33', 'active'),
(gen_random_uuid()::text, 'مكبس القشرة والكبس الآلي', 'القشرة', 'كبس قشرة أرو وجوز وزان على الكونتر وMDF', 'active'),
(gen_random_uuid()::text, 'ورشة الزجاج والمرايات', 'الزجاج والمرايات', 'تقطيع وشطف ومرايات بالليد', 'active'),
(gen_random_uuid()::text, 'مخرطة الخشب والسي ان سي', 'خرط وخراطة CNC', 'حفر وزخرفة خشب بالحاسب وتفصيل رجول', 'active')
ON CONFLICT DO NOTHING;

-- ── 19. ARABIC VIEWS FOR SUPABASE TABLE EDITOR (المخزن والنواقص) ─
CREATE OR REPLACE VIEW public."المخزن" AS
SELECT 
    id AS "المعرف",
    material_name AS "اسم_الصنف_أو_الخامة",
    category AS "التصنيف",
    unit AS "الوحدة",
    current_stock AS "الرصيد_الحالي_المتوفر",
    reserved_stock AS "الرصيد_المحجوز_للتصنيع",
    (current_stock - reserved_stock) AS "الرصيد_الفعلي_المتاح",
    minimum_stock_level AS "حد_الطلب_الأدنى",
    unit_cost AS "سعر_التكلفة_جنية",
    supplier_name AS "المورد_الافتراضي",
    notes AS "ملاحظات",
    updated_at AS "آخر_تحديث"
FROM public.inventory_items;

CREATE OR REPLACE VIEW public."النواقص" AS
SELECT 
    id AS "المعرف",
    material_name AS "اسم_الخامة_المطلوبة",
    quantity AS "الكمية_المطلوبة",
    unit AS "الوحدة",
    specifications AS "المواصفات_والمقاسات",
    notes AS "ملاحظات_الورشة",
    manufacturing_order_number AS "رقم_أمر_التصنيع_المرتبط",
    CASE 
        WHEN status = 'shortage' THEN 'ناقص - مطلوب'
        WHEN status = 'in_progress' THEN 'جارٍ المتابعة والشراء'
        WHEN status = 'resolved' THEN 'تم التوفير والحل'
        WHEN status = 'reopened' THEN 'أعيد فتحه'
        ELSE status
    END AS "حالة_الطلب",
    recorded_by AS "المسؤول_عن_التسجيل",
    recorded_at AS "تاريخ_التسجيل",
    resolved_by AS "المسؤول_عن_التوفير",
    resolved_at AS "تاريخ_الحل"
FROM public.material_shortages;

CREATE OR REPLACE VIEW public."حركات_المخزن" AS
SELECT 
    m.id AS "معرف_الحركة",
    i.material_name AS "اسم_الخامة",
    CASE 
        WHEN m.movement_type = 'receipt' THEN 'وارد (إضافة رصيد)'
        WHEN m.movement_type = 'issue' THEN 'منصرف (صرف للورشة)'
        WHEN m.movement_type = 'adjustment' THEN 'تسوية جردية'
        WHEN m.movement_type = 'reservation' THEN 'حجز لتصنيع'
        WHEN m.movement_type = 'reservation_release' THEN 'فك حجز'
        WHEN m.movement_type = 'return' THEN 'مرتجع للمخزن'
        ELSE m.movement_type
    END AS "نوع_الحركة",
    m.quantity AS "الكمية",
    m.reason_notes AS "السبب_والملاحظات",
    m.created_by AS "المسؤول",
    m.created_at AS "تاريخ_الوقت"
FROM public.inventory_movements m
LEFT JOIN public.inventory_items i ON m.inventory_item_id = i.id;

GRANT SELECT ON public."المخزن" TO authenticated, anon;
GRANT SELECT ON public."النواقص" TO authenticated, anon;
GRANT SELECT ON public."حركات_المخزن" TO authenticated, anon;

