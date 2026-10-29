-- ============================================================
-- STARS HOMES ERP — Migration 10: Inventory & Shortages Setup
-- جدول المخزن وجدول النواقص مع واجهات العرض باللغة العربية
-- Version: 2026-10-28
-- ============================================================

-- ── 1. جدول المخزون والخامات (INVENTORY ITEMS) ─────────────────
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

-- ── 2. جدول حركات المخزن الوارد والمنصرف (INVENTORY MOVEMENTS) ─
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

-- ── 3. جدول حجوزات المخزون لأوامر التصنيع (RESERVATIONS) ────────
CREATE TABLE IF NOT EXISTS public.inventory_reservations (
    id TEXT PRIMARY KEY,
    manufacturing_order_id TEXT NOT NULL REFERENCES public.manufacturing_orders(id) ON DELETE CASCADE,
    inventory_item_id TEXT NOT NULL REFERENCES public.inventory_items(id) ON DELETE CASCADE,
    reserved_quantity NUMERIC(12, 2) NOT NULL CHECK (reserved_quantity > 0),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'released', 'consumed')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    device_id TEXT
);

-- ── 4. جدول النواقص واحتياجات الخامات (MATERIAL SHORTAGES) ─────
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

-- ── 5. الفهارس لتسريع البحث والأداء ────────────────────────────
CREATE INDEX IF NOT EXISTS idx_inventory_material_name ON public.inventory_items (material_name);
CREATE INDEX IF NOT EXISTS idx_inventory_category ON public.inventory_items (category);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_item ON public.inventory_movements (inventory_item_id);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_date ON public.inventory_movements (created_at);
CREATE INDEX IF NOT EXISTS idx_shortages_status ON public.material_shortages (status);
CREATE INDEX IF NOT EXISTS idx_shortages_material ON public.material_shortages (material_name);
CREATE INDEX IF NOT EXISTS idx_shortages_date ON public.material_shortages (recorded_at);

-- ── 6. تفعيل التحديث التلقائي لتاريخ التعديل (updated_at) ───────
DO $$
DECLARE t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['inventory_items', 'material_shortages'] LOOP
    EXECUTE format('
      DROP TRIGGER IF EXISTS trg_%I_updated_at ON public.%I;
      CREATE TRIGGER trg_%I_updated_at
        BEFORE UPDATE ON public.%I
        FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
    ', t, t, t, t);
  END LOOP;
END;
$$;

-- ── 7. تفعيل سياسات الأمان والحماية (RLS) ────────────────────────
DO $$
DECLARE
  t TEXT;
  tbls TEXT[] := ARRAY['inventory_items', 'inventory_movements', 'inventory_reservations', 'material_shortages'];
BEGIN
  FOREACH t IN ARRAY tbls LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;', t);
    EXECUTE format('DROP POLICY IF EXISTS "allow_auth_all_%I" ON public.%I;', t, t);
    EXECUTE format('CREATE POLICY "allow_auth_all_%I" ON public.%I FOR ALL TO authenticated USING (true) WITH CHECK (true);', t, t);
    EXECUTE format('DROP POLICY IF EXISTS "allow_anon_all_%I" ON public.%I;', t, t);
    EXECUTE format('CREATE POLICY "allow_anon_all_%I" ON public.%I FOR ALL TO anon USING (true) WITH CHECK (true);', t, t);
  END LOOP;
END;
$$;

-- ── 8. إنشاء واجهات عرض مباشرة باللغة العربية (VIEWS) ───────────
-- تمكنك من رؤية جدول "المخزن" وجدول "النواقص" بالعربي مباشرة في Supabase

CREATE OR REPLACE VIEW public."المخزن" AS
SELECT 
    id AS "المعرف",
    material_name AS "اسم_الصنف_أو_الخامة",
    category AS "التصنيف",
    unit AS "الوحدة",
    current_stock AS "الرصيد_الحالي_المتوفر",
    reserved_stock AS "الرصيد_المحجوز_للتصنيع",
    (current_stock - reserved_stock) AS "الرصيد_الفعل_المتاح",
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

-- منح الصلاحيات لواجهات العرض
GRANT SELECT ON public."المخزن" TO authenticated, anon;
GRANT SELECT ON public."النواقص" TO authenticated, anon;
GRANT SELECT ON public."حركات_المخزن" TO authenticated, anon;

