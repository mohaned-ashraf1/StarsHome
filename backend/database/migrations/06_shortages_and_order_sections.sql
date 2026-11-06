-- ========================================================
-- STARS HOMES - Factory Management System
-- Migration 06: Material Shortages Module & Multi-Section Manufacturing Orders
-- ========================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. MATERIAL SHORTAGES (موديول إدارة النواقص المستقل)
CREATE TABLE IF NOT EXISTS public.material_shortages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    material_name TEXT NOT NULL,
    quantity NUMERIC(12, 2), -- يمكن أن تكون غير محددة أو خالية
    unit TEXT NOT NULL DEFAULT 'لوح',
    specifications TEXT,
    notes TEXT,
    manufacturing_order_id UUID REFERENCES public.manufacturing_orders(id) ON DELETE SET NULL,
    manufacturing_order_number TEXT,
    status TEXT NOT NULL DEFAULT 'shortage' CHECK (status IN ('shortage', 'in_progress', 'resolved', 'reopened')),
    recorded_by TEXT NOT NULL,
    recorded_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_by TEXT,
    resolved_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Add sections_data column to manufacturing_orders for multi-section furniture orders
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'manufacturing_orders' 
        AND column_name = 'sections_data'
    ) THEN
        ALTER TABLE public.manufacturing_orders ADD COLUMN sections_data JSONB;
    END IF;
END $$;

-- 3. Add thickness, color, and linked piece to manufacturing_order_materials
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'manufacturing_order_materials' 
        AND column_name = 'thickness_grade'
    ) THEN
        ALTER TABLE public.manufacturing_order_materials ADD COLUMN thickness_grade TEXT;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'manufacturing_order_materials' 
        AND column_name = 'color_code'
    ) THEN
        ALTER TABLE public.manufacturing_order_materials ADD COLUMN color_code TEXT;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'manufacturing_order_materials' 
        AND column_name = 'linked_piece'
    ) THEN
        ALTER TABLE public.manufacturing_order_materials ADD COLUMN linked_piece TEXT;
    END IF;
END $$;

-- INDEXES
CREATE INDEX IF NOT EXISTS idx_material_shortages_status ON public.material_shortages (status);
CREATE INDEX IF NOT EXISTS idx_material_shortages_name ON public.material_shortages (material_name);
CREATE INDEX IF NOT EXISTS idx_material_shortages_order ON public.material_shortages (manufacturing_order_id);
CREATE INDEX IF NOT EXISTS idx_material_shortages_date ON public.material_shortages (recorded_at);

-- ROW LEVEL SECURITY
ALTER TABLE public.material_shortages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated full access to material_shortages" 
ON public.material_shortages FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Allow anon read/write if dev mode material_shortages" 
ON public.material_shortages FOR ALL TO anon USING (true) WITH CHECK (true);
