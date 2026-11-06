-- ========================================================
-- STARS HOMES - Factory Financial Management System
-- Migration 04: Customers, Custom Orders & Installment Payments
-- ========================================================

-- 1. CUSTOMER ORDERS (طلبيات وحسابات العملاء)
CREATE TABLE IF NOT EXISTS public.customer_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. ORDER PAYMENTS (دفعات وأقساط العميل)
CREATE TABLE IF NOT EXISTS public.order_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES public.customer_orders(id) ON DELETE CASCADE,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    payment_method TEXT DEFAULT 'نقدي',
    notes TEXT,
    linked_income_id UUID REFERENCES public.incomes(id) ON DELETE SET NULL,
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- INDEXES
CREATE INDEX IF NOT EXISTS idx_customer_orders_date ON public.customer_orders (start_date);
CREATE INDEX IF NOT EXISTS idx_customer_orders_delivery ON public.customer_orders (delivery_date);
CREATE INDEX IF NOT EXISTS idx_customer_orders_status ON public.customer_orders (status);
CREATE INDEX IF NOT EXISTS idx_order_payments_order ON public.order_payments (order_id);
CREATE INDEX IF NOT EXISTS idx_order_payments_date ON public.order_payments (payment_date);

-- RLS POLICIES (If RLS enabled)
ALTER TABLE public.customer_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all authenticated users full access to customer_orders" 
    ON public.customer_orders FOR ALL 
    TO authenticated 
    USING (true) 
    WITH CHECK (true);

CREATE POLICY "Allow anon read/write if dev mode customer_orders" 
    ON public.customer_orders FOR ALL 
    TO anon 
    USING (true) 
    WITH CHECK (true);

CREATE POLICY "Allow all authenticated users full access to order_payments" 
    ON public.order_payments FOR ALL 
    TO authenticated 
    USING (true) 
    WITH CHECK (true);

CREATE POLICY "Allow anon read/write if dev mode order_payments" 
    ON public.order_payments FOR ALL 
    TO anon 
    USING (true) 
    WITH CHECK (true);
