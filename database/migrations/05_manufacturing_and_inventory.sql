-- ========================================================
-- STARS HOMES - Factory Financial & Manufacturing Management System
-- Migration 05: Manufacturing Orders, Dimensions, Material Checklist & Inventory
-- ========================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. INVENTORY ITEMS (أصناف وخامات المخزون)
CREATE TABLE IF NOT EXISTS public.inventory_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    material_name TEXT NOT NULL UNIQUE,
    category TEXT NOT NULL, -- e.g. أخشاب ومواد خام, إكسسوارات ومعدات, أقمشة وجلود, دهانات
    unit TEXT NOT NULL DEFAULT 'لوح', -- لوح, متر, قطعة, كجم, لفة, طقم
    current_stock NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (current_stock >= 0),
    reserved_stock NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (reserved_stock >= 0),
    minimum_stock_level NUMERIC(12, 2) NOT NULL DEFAULT 0,
    unit_cost NUMERIC(12, 2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. INVENTORY MOVEMENTS (سجل حركات المخزن)
CREATE TABLE IF NOT EXISTS public.inventory_movements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    inventory_item_id UUID NOT NULL REFERENCES public.inventory_items(id) ON DELETE CASCADE,
    movement_type TEXT NOT NULL CHECK (movement_type IN ('receipt', 'issue', 'adjustment', 'reservation', 'reservation_release', 'return')),
    quantity NUMERIC(12, 2) NOT NULL,
    reference_type TEXT CHECK (reference_type IN ('purchase', 'manufacturing_order', 'manual_adjustment', 'return')),
    reference_id UUID,
    reason_notes TEXT,
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. MANUFACTURING ORDERS (أوامر التصنيع)
CREATE TABLE IF NOT EXISTS public.manufacturing_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number TEXT NOT NULL UNIQUE,
    customer_order_id UUID REFERENCES public.customer_orders(id) ON DELETE SET NULL,
    customer_name TEXT,
    product_name TEXT NOT NULL, -- دولاب, سرير, مكتب, ترابيزة, كرسي, وحدة تلفزيون, مطبخ, etc.
    product_category TEXT NOT NULL DEFAULT 'أثاث خشبي',
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    manufacturing_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expected_completion_date DATE,
    assigned_worker_id UUID REFERENCES public.workers(id) ON DELETE SET NULL,
    assigned_worker_name TEXT,
    status TEXT NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'awaiting_materials', 'ready_to_build', 'in_progress', 'completed', 'cancelled')),
    notes TEXT,
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. MANUFACTURING ORDER DIMENSIONS (المقاسات)
CREATE TABLE IF NOT EXISTS public.manufacturing_order_dimensions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    manufacturing_order_id UUID NOT NULL REFERENCES public.manufacturing_orders(id) ON DELETE CASCADE,
    height NUMERIC(8, 2),
    width NUMERIC(8, 2),
    depth NUMERIC(8, 2),
    unit TEXT NOT NULL DEFAULT 'سم',
    additional_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. MANUFACTURING ORDER MATERIALS (الخامات المطلوبة لكل أمر تصنيع)
CREATE TABLE IF NOT EXISTS public.manufacturing_order_materials (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    manufacturing_order_id UUID NOT NULL REFERENCES public.manufacturing_orders(id) ON DELETE CASCADE,
    inventory_item_id UUID REFERENCES public.inventory_items(id) ON DELETE SET NULL,
    material_name TEXT NOT NULL,
    required_quantity NUMERIC(12, 2) NOT NULL CHECK (required_quantity > 0),
    unit TEXT NOT NULL,
    specifications TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. MANUFACTURING CHECKLIST (قائمة مراجعة وتجهيز الخامات)
CREATE TABLE IF NOT EXISTS public.manufacturing_checklist (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    manufacturing_order_id UUID NOT NULL REFERENCES public.manufacturing_orders(id) ON DELETE CASCADE,
    material_name TEXT NOT NULL,
    required_quantity NUMERIC(12, 2) NOT NULL,
    unit TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'required' CHECK (status IN ('required', 'ordered', 'received', 'prepared')),
    is_prepared BOOLEAN NOT NULL DEFAULT FALSE,
    notes TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. INVENTORY RESERVATIONS (حجوزات الخامات للأوامر)
CREATE TABLE IF NOT EXISTS public.inventory_reservations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    manufacturing_order_id UUID NOT NULL REFERENCES public.manufacturing_orders(id) ON DELETE CASCADE,
    inventory_item_id UUID NOT NULL REFERENCES public.inventory_items(id) ON DELETE CASCADE,
    reserved_quantity NUMERIC(12, 2) NOT NULL CHECK (reserved_quantity > 0),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'released', 'consumed')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- INDEXES
CREATE INDEX IF NOT EXISTS idx_inventory_items_name ON public.inventory_items (material_name);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_item ON public.inventory_movements (inventory_item_id);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_date ON public.inventory_movements (created_at);
CREATE INDEX IF NOT EXISTS idx_manufacturing_orders_number ON public.manufacturing_orders (order_number);
CREATE INDEX IF NOT EXISTS idx_manufacturing_orders_status ON public.manufacturing_orders (status);
CREATE INDEX IF NOT EXISTS idx_manufacturing_orders_date ON public.manufacturing_orders (manufacturing_date);
CREATE INDEX IF NOT EXISTS idx_order_materials_order ON public.manufacturing_order_materials (manufacturing_order_id);
CREATE INDEX IF NOT EXISTS idx_checklist_order ON public.manufacturing_checklist (manufacturing_order_id);
CREATE INDEX IF NOT EXISTS idx_reservations_order ON public.inventory_reservations (manufacturing_order_id);

-- RLS POLICIES
ALTER TABLE public.inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.manufacturing_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.manufacturing_order_dimensions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.manufacturing_order_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.manufacturing_checklist ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_reservations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated full access to inventory_items" ON public.inventory_items FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon read/write if dev mode inventory_items" ON public.inventory_items FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Allow authenticated full access to inventory_movements" ON public.inventory_movements FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon read/write if dev mode inventory_movements" ON public.inventory_movements FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Allow authenticated full access to manufacturing_orders" ON public.manufacturing_orders FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon read/write if dev mode manufacturing_orders" ON public.manufacturing_orders FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Allow authenticated full access to manufacturing_order_dimensions" ON public.manufacturing_order_dimensions FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon read/write if dev mode manufacturing_order_dimensions" ON public.manufacturing_order_dimensions FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Allow authenticated full access to manufacturing_order_materials" ON public.manufacturing_order_materials FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon read/write if dev mode manufacturing_order_materials" ON public.manufacturing_order_materials FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Allow authenticated full access to manufacturing_checklist" ON public.manufacturing_checklist FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon read/write if dev mode manufacturing_checklist" ON public.manufacturing_checklist FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Allow authenticated full access to inventory_reservations" ON public.inventory_reservations FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon read/write if dev mode inventory_reservations" ON public.inventory_reservations FOR ALL TO anon USING (true) WITH CHECK (true);
