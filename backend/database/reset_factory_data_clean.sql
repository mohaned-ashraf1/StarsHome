-- ============================================================
-- STARS HOMES ERP — Safe Factory Data Reset Script (تنظيف البيانات)
-- يقوم هذا السكريبت بمسح وتصفير كافة السجلات والمعاملات التجريبية القديمة
-- مع الحفاظ التام والآمن على:
-- 1. هيكل الجداول والـ Schema بالكامل دون أي حذف.
-- 2. حسابات المستخدمين في Supabase Auth (auth.users) وملفاتهم (profiles).
-- 3. الدوال والـ Triggers وسياسات الأمان RLS.
-- 4. التصنيفات وقوائم الاقتراحات الأساسية (categories, item_suggestions).
-- ============================================================

BEGIN;

-- ── 1. تصفير بيانات أوامر التصنيع والنواقص والمخازن ─────────────
TRUNCATE TABLE public.inventory_reservations CASCADE;
TRUNCATE TABLE public.inventory_movements CASCADE;
TRUNCATE TABLE public.material_shortages CASCADE;
TRUNCATE TABLE public.manufacturing_checklist CASCADE;
TRUNCATE TABLE public.manufacturing_order_materials CASCADE;
TRUNCATE TABLE public.manufacturing_order_dimensions CASCADE;
TRUNCATE TABLE public.manufacturing_orders CASCADE;
TRUNCATE TABLE public.inventory_items CASCADE;

-- ── 2. تصفير بيانات العملاء والطلبيات والدفعات ──────────────────
TRUNCATE TABLE public.order_payments CASCADE;
TRUNCATE TABLE public.customer_orders CASCADE;

-- ── 3. تصفير بيانات مقاولي الباطن والورش ────────────────────────
TRUNCATE TABLE public.contractor_payments CASCADE;
TRUNCATE TABLE public.contractors CASCADE;

-- ── 4. تصفير بيانات العمال والرواتب والحضور ─────────────────────
TRUNCATE TABLE public.worker_payroll_settlements CASCADE;
TRUNCATE TABLE public.worker_financial_items CASCADE;
TRUNCATE TABLE public.worker_attendance CASCADE;
TRUNCATE TABLE public.workers CASCADE;

-- ── 5. تصفير بيانات المصروفات والإيرادات والديون ─────────────────
TRUNCATE TABLE public.debt_advance_payments CASCADE;
TRUNCATE TABLE public.debts_advances CASCADE;
TRUNCATE TABLE public.purchases CASCADE;
TRUNCATE TABLE public.incomes CASCADE;
TRUNCATE TABLE public.audit_logs CASCADE;

-- ── 6. إعادة إدراج التصنيفات الأساسية النظيفة (إن لزم) ───────────
INSERT INTO public.categories (id, name, type, is_reusable)
VALUES 
    ('cat_1', 'أخشاب ومواد خام', 'expense', TRUE),
    ('cat_2', 'إكسسوارات ومعدات', 'expense', TRUE),
    ('cat_3', 'أقمشة وجلود', 'expense', TRUE),
    ('cat_4', 'وقود وصيانة سيارات', 'expense', TRUE),
    ('cat_5', 'نقل وتروسيكل', 'expense', TRUE),
    ('cat_6', 'مصاريف عمال وضيافة', 'expense', TRUE),
    ('cat_7', 'ورش واشتراكات خارجية', 'expense', TRUE),
    ('cat_8', 'فواتير ومرافق مصنع', 'expense', TRUE),
    ('cat_9', 'مصروفات نثرية أخرى', 'expense', TRUE)
ON CONFLICT (name) DO NOTHING;

COMMIT;

-- تأكيد التصفير:
SELECT 'تم تصفير كافة البيانات التشغيلية بنجاح، وقاعدة البيانات جاهزة للعمل الفعلي النظيف.' AS result;

