-- ============================================================
-- STARS HOMES ERP — Scheduled Server Job: Order Delivery Reminders
-- تنبيهات مواعيد تسليم الطلبات للعملاء قبل موعد التسليم بـ 7 أيام
-- ============================================================

CREATE OR REPLACE FUNCTION public.check_upcoming_deliveries()
RETURNS TABLE (
    order_id TEXT,
    order_number TEXT,
    customer_name TEXT,
    customer_phone TEXT,
    delivery_date DATE,
    days_left INTEGER,
    remaining_balance NUMERIC
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        co.id,
        co.order_number,
        co.customer_name,
        co.customer_phone,
        co.delivery_date,
        (co.delivery_date - CURRENT_DATE)::INTEGER AS days_left,
        (co.total_amount - co.paid_amount) AS remaining_balance
    FROM public.customer_orders co
    WHERE co.status NOT IN ('delivered', 'cancelled')
      AND co.delivery_date IS NOT NULL
      AND co.delivery_date BETWEEN CURRENT_DATE AND (CURRENT_DATE + INTERVAL '7 days')
    ORDER BY co.delivery_date ASC;
END;
$$;

COMMENT ON FUNCTION public.check_upcoming_deliveries() IS 'فحص الطلبات المستحقة للتسليم خلال 7 أيام وتجهيز بيانات التنبيه للعميل والمدير';

