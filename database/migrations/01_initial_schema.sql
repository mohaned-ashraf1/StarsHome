-- ========================================================
-- STARS HOMES - Factory Financial Management System
-- Migration 01: Initial Database Schema (PostgreSQL / Supabase)
-- ========================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. PROFILES & ROLES
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('owner', 'manager')),
    phone TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. EXPENSE CATEGORIES & REUSABLE ITEMS
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    type TEXT NOT NULL DEFAULT 'expense' CHECK (type IN ('expense', 'income')),
    is_reusable BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.item_suggestions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    item_name TEXT NOT NULL UNIQUE,
    default_category TEXT,
    last_unit_price NUMERIC(12, 2) DEFAULT 0,
    times_used INTEGER DEFAULT 1,
    last_used_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. PURCHASES & EXPENSES (الحسابات - المشتريات والمصروفات)
CREATE TABLE IF NOT EXISTS public.purchases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    item_name TEXT NOT NULL,
    category TEXT NOT NULL,
    quantity NUMERIC(12, 2),
    unit_price NUMERIC(12, 2),
    total_amount NUMERIC(12, 2) NOT NULL,
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT,
    source_type TEXT DEFAULT 'direct' CHECK (source_type IN ('direct', 'worker_advance', 'worker_payroll', 'contractor_payment', 'maintenance', 'fuel', 'other')),
    source_id UUID, -- References worker advance, payroll settlement, or contractor payment
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_reversed BOOLEAN DEFAULT FALSE,
    reversed_at TIMESTAMPTZ,
    reversed_by TEXT
);

-- 4. FACTORY INCOME (الحسابات - الداخل)
CREATE TABLE IF NOT EXISTS public.incomes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_name TEXT NOT NULL,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT,
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_reversed BOOLEAN DEFAULT FALSE,
    reversed_at TIMESTAMPTZ,
    reversed_by TEXT
);

-- 5. WORKERS (العمال)
CREATE TABLE IF NOT EXISTS public.workers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name TEXT NOT NULL,
    daily_wage NUMERIC(12, 2) NOT NULL DEFAULT 0,
    standard_start_time TEXT NOT NULL DEFAULT '08:00',
    standard_end_time TEXT NOT NULL DEFAULT '19:00',
    overtime_hourly_rate NUMERIC(12, 2) NOT NULL DEFAULT 0,
    phone TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. WORKER ATTENDANCE (حضور وانصراف العمال)
CREATE TABLE IF NOT EXISTS public.worker_attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    worker_id UUID NOT NULL REFERENCES public.workers(id) ON DELETE CASCADE,
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
    CONSTRAINT unique_worker_date UNIQUE (worker_id, attendance_date)
);

-- 7. WORKER FINANCIAL ITEMS (المكافآت، السلف، الخصومات)
CREATE TABLE IF NOT EXISTS public.worker_financial_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    worker_id UUID NOT NULL REFERENCES public.workers(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('advance', 'bonus', 'deduction')),
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    reason_notes TEXT,
    is_settled_in_payroll BOOLEAN DEFAULT FALSE,
    payroll_settlement_id UUID,
    linked_expense_id UUID REFERENCES public.purchases(id) ON DELETE SET NULL,
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. WEEKLY PAYROLL SETTLEMENTS (كشف وتصفية الرواتب الأسبوعية)
CREATE TABLE IF NOT EXISTS public.worker_payroll_settlements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    worker_id UUID NOT NULL REFERENCES public.workers(id) ON DELETE CASCADE,
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
    linked_expense_id UUID REFERENCES public.purchases(id) ON DELETE SET NULL,
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. CONTRACTORS / EXTERNAL SERVICE PROVIDERS (الاشتراكات والورش الخارجية)
CREATE TABLE IF NOT EXISTS public.contractors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    service_type TEXT NOT NULL, -- e.g. الدهان, التنجيد, القشرة
    phone TEXT,
    notes TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. CONTRACTOR PAYMENTS (مدفوعات الاشتراكات)
CREATE TABLE IF NOT EXISTS public.contractor_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contractor_id UUID NOT NULL REFERENCES public.contractors(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    related_order TEXT,
    notes TEXT,
    linked_expense_id UUID REFERENCES public.purchases(id) ON DELETE SET NULL,
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. AUDIT LOG (سجل التدقيق والتتبع)
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_name TEXT NOT NULL,
    action TEXT NOT NULL,
    entity_table TEXT NOT NULL,
    entity_id UUID NOT NULL,
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- INDEXES FOR FAST REPORTING & DATE QUERIES
CREATE INDEX IF NOT EXISTS idx_purchases_date ON public.purchases (transaction_date);
CREATE INDEX IF NOT EXISTS idx_purchases_item ON public.purchases (item_name);
CREATE INDEX IF NOT EXISTS idx_purchases_category ON public.purchases (category);
CREATE INDEX IF NOT EXISTS idx_incomes_date ON public.incomes (transaction_date);
CREATE INDEX IF NOT EXISTS idx_attendance_worker_date ON public.worker_attendance (worker_id, attendance_date);
CREATE INDEX IF NOT EXISTS idx_financial_worker_date ON public.worker_financial_items (worker_id, transaction_date);
CREATE INDEX IF NOT EXISTS idx_contractor_payments_date ON public.contractor_payments (payment_date);
CREATE INDEX IF NOT EXISTS idx_contractor_payments_contractor ON public.contractor_payments (contractor_id);
