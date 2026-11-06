-- ========================================================
-- STARS HOMES - Factory Financial Management System
-- Migration 02: Row Level Security (RLS) & Access Policies
-- ========================================================

-- Enable Row Level Security on all factory tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.item_suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incomes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.worker_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.worker_financial_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.worker_payroll_settlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contractors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contractor_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Helper function to check if current user is an authorized factory member (owner or manager)
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

-- Helper function to check if current user is Owner
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

-- 1. PROFILES POLICIES
CREATE POLICY "Authorized users can read profiles"
ON public.profiles FOR SELECT
USING (auth.uid() = id OR public.is_factory_authorized());

CREATE POLICY "Only owner can insert or update profiles"
ON public.profiles FOR ALL
USING (public.is_factory_owner());

-- 2. PURCHASES POLICIES
CREATE POLICY "Authorized users can read purchases"
ON public.purchases FOR SELECT
USING (public.is_factory_authorized());

CREATE POLICY "Authorized users can insert purchases"
ON public.purchases FOR INSERT
WITH CHECK (public.is_factory_authorized());

CREATE POLICY "Authorized users can update purchases"
ON public.purchases FOR UPDATE
USING (public.is_factory_authorized());

-- 3. INCOMES POLICIES
CREATE POLICY "Authorized users can read incomes"
ON public.incomes FOR SELECT
USING (public.is_factory_authorized());

CREATE POLICY "Authorized users can insert incomes"
ON public.incomes FOR INSERT
WITH CHECK (public.is_factory_authorized());

CREATE POLICY "Authorized users can update incomes"
ON public.incomes FOR UPDATE
USING (public.is_factory_authorized());

-- 4. WORKERS & ATTENDANCE POLICIES
CREATE POLICY "Authorized users can access workers"
ON public.workers FOR ALL
USING (public.is_factory_authorized());

CREATE POLICY "Authorized users can access attendance"
ON public.worker_attendance FOR ALL
USING (public.is_factory_authorized());

CREATE POLICY "Authorized users can access financial items"
ON public.worker_financial_items FOR ALL
USING (public.is_factory_authorized());

CREATE POLICY "Authorized users can access payroll"
ON public.worker_payroll_settlements FOR ALL
USING (public.is_factory_authorized());

-- 5. CONTRACTORS POLICIES
CREATE POLICY "Authorized users can access contractors"
ON public.contractors FOR ALL
USING (public.is_factory_authorized());

CREATE POLICY "Authorized users can access contractor payments"
ON public.contractor_payments FOR ALL
USING (public.is_factory_authorized());

-- 6. AUDIT LOGS POLICIES
CREATE POLICY "Authorized users can read audit logs"
ON public.audit_logs FOR SELECT
USING (public.is_factory_authorized());

CREATE POLICY "Authorized users can insert audit logs"
ON public.audit_logs FOR INSERT
WITH CHECK (public.is_factory_authorized());
