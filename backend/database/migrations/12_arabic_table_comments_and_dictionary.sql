-- ============================================================
-- STARS HOMES ERP — Migration 12: Arabic Table & Column Comments
-- توثيق وتعريب جداول وأعمدة قاعدة البيانات باللغة العربية داخل Supabase Dashboard
-- ============================================================

-- ── 1. وحدة الحسابات والمصروفات (Accounts & Expenses) ───────────
COMMENT ON TABLE public.purchases IS 'سجل المشتريات والمصروفات اليومية للمصنع والخامات ومصاريف التشغيل';
COMMENT ON COLUMN public.purchases.item_name IS 'اسم البند أو الخامة المشتراة';
COMMENT ON COLUMN public.purchases.category IS 'تصنيف المصروف (أخشاب، إكسسوارات، صيانة، ضيافة...)';
COMMENT ON COLUMN public.purchases.amount IS 'المبلغ الإجمالي المدفوع بالجنيه المصري';
COMMENT ON COLUMN public.purchases.purchased_by IS 'اسم الشخص الذي قام بالشراء';
COMMENT ON COLUMN public.purchases.invoice_number IS 'رقم الفاتورة الورقية إن وجد';

COMMENT ON TABLE public.incomes IS 'سجل الإيرادات والدخل والمقبوضات الخارجية للمصنع';
COMMENT ON COLUMN public.incomes.source IS 'مصدر أو سبب الإيراد';
COMMENT ON COLUMN public.incomes.amount IS 'مبلغ الإيراد بالجنيه المصري';

COMMENT ON TABLE public.categories IS 'التصنيفات المعتمدة للمصروفات والإيرادات لتسهيل التبويب';
COMMENT ON TABLE public.item_suggestions IS 'قائمة الاقتراحات السريعة لبنود المشتريات متكررة الاستخدام';

COMMENT ON TABLE public.debts_advances IS 'سجل السلف والديون والعهد المالية الخارجية للمصنع';
COMMENT ON COLUMN public.debts_advances.person_name IS 'اسم صاحب السلفة أو الدين';
COMMENT ON COLUMN public.debts_advances.type IS 'نوع السجل: سلفة لموظف، دين على المصنع، أو دين للمصنع';
COMMENT ON COLUMN public.debts_advances.total_amount IS 'المبلغ الإجمالي الأصلي';
COMMENT ON COLUMN public.debts_advances.remaining_amount IS 'المبلغ المتبقي سداده';

COMMENT ON TABLE public.debt_advance_payments IS 'سجل دفعات سداد الديون والسلف المسجلة';

-- ── 2. وحدة العمال والرواتب (Workers & Payroll) ──────────────────
COMMENT ON TABLE public.workers IS 'ملفات العمال والفنيين بالمصنع — اليوميات، المواعيد الرسمية، وأرقام التواصل';
COMMENT ON COLUMN public.workers.name IS 'اسم العامل بالكامل';
COMMENT ON COLUMN public.workers.role_title IS 'المهنة أو التخصص (نجار، استورجي، مساعد، حداد...)';
COMMENT ON COLUMN public.workers.daily_rate IS 'قيمة اليومية الأساسية بالجنيه المصري';
COMMENT ON COLUMN public.workers.overtime_hourly_rate IS 'سعر ساعة العمل الإضافية (Overtime)';
COMMENT ON COLUMN public.workers.status IS 'حالة العامل (نشط بالمصنع / متوقف)';

COMMENT ON TABLE public.worker_attendance IS 'سجل الحضور والانصراف اليومي للعمال واحتساب الإضافي والغياب';
COMMENT ON COLUMN public.worker_attendance.status IS 'حالة الحضور: حاضر، غائب، إجازة مدفوعة، نصف يوم';
COMMENT ON COLUMN public.worker_attendance.work_hours IS 'عدد ساعات العمل الفعلية';
COMMENT ON COLUMN public.worker_attendance.overtime_hours IS 'ساعات العمل الإضافية المعتمدة';

COMMENT ON TABLE public.worker_financial_items IS 'بنود المعاملات المالية للعمال: السلف المؤقتة، المكافآت، والجزاءات والخصومات';
COMMENT ON COLUMN public.worker_financial_items.item_type IS 'نوع البند: سلفة (advance)، مكافأة (bonus)، خصم (penalty)';

COMMENT ON TABLE public.worker_payroll_settlements IS 'سجل تقفيل الرواتب وتصفية حسابات العمال الدورية';
COMMENT ON COLUMN public.worker_payroll_settlements.net_amount IS 'صافي الراتب المستحق للصرف بعد إضافة الإضافي والبدلات وخصم السلف والغياب';

-- ── 3. وحدة مقاولي الباطن والورش (Contractors) ──────────────────
COMMENT ON TABLE public.contractors IS 'بيانات مقاولي الباطن والورش والخدمات الخارجية (دهانات، ليزر، سي ان سي، خراطة)';
COMMENT ON TABLE public.contractor_payments IS 'سجل المدفوعات والدفعات المحولة للورش ومقاولي الباطن';

-- ── 4. وحدة العملاء والطلبيات (Customers & Orders) ───────────────
COMMENT ON TABLE public.customer_orders IS 'طلبيات وعقود العملاء وتفاصيل الأثاث المطلوب مع مواعيد التسليم والأقسام';
COMMENT ON COLUMN public.customer_orders.order_number IS 'كود الطلب الرسمي المميز';
COMMENT ON COLUMN public.customer_orders.customer_name IS 'اسم العميل بالكامل';
COMMENT ON COLUMN public.customer_orders.customer_phone IS 'رقم هاتف العميل للتواصل والواتساب';
COMMENT ON COLUMN public.customer_orders.delivery_date IS 'تاريخ التسليم المتفق عليه مع العميل';
COMMENT ON COLUMN public.customer_orders.total_amount IS 'إجمالي قيمة الاتفاق للطلب بالكامل';
COMMENT ON COLUMN public.customer_orders.paid_amount IS 'إجمالي ما تم سداده حتى الآن (العربون والدفعات)';
COMMENT ON COLUMN public.customer_orders.notes IS 'مواصفات الطلب، ويتضمن بنية الأقسام والصور المرفقة مشفرة JSON';

COMMENT ON TABLE public.order_payments IS 'سجل دفعات وعرابين العملاء الخاصة بطلبيات التصنيع';

-- ── 5. وحدة المخازن والخامات (Inventory) ─────────────────────────
COMMENT ON TABLE public.inventory_items IS 'رصيد الخامات والأخشاب والإكسسوارات في مخزن المصنع';
COMMENT ON COLUMN public.inventory_items.material_name IS 'اسم الخامة أو اللوح (خشب زان، أبلكاش، قماش...)';
COMMENT ON COLUMN public.inventory_items.current_stock IS 'الرصيد الفعلي المتوفر حالياً في المخزن';
COMMENT ON COLUMN public.inventory_items.reserved_stock IS 'الكميات المحجوزة لأوامر تصنيع قيد التنفيذ في الورشة';
COMMENT ON COLUMN public.inventory_items.minimum_stock_level IS 'حد الطلب الأدنى للتنبيه عند نقص الخامة';

COMMENT ON TABLE public.inventory_movements IS 'حركات المخزن: وارد، منصرف تشغيل، مرتجع، تسوية جرد';
COMMENT ON TABLE public.inventory_reservations IS 'حجوزات الخامات المخصصة لأوامر التصنيع';
COMMENT ON TABLE public.material_shortages IS 'قائمة النواقص واحتياجات الخامات العاجلة المطلوب شراؤها';

-- ── 6. وحدة أوامر التصنيع والتشغيل (Manufacturing) ───────────────
COMMENT ON TABLE public.manufacturing_orders IS 'أوامر تشغيل وتصنيع الموبيليا في خط الإنتاج داخل الورشة';
COMMENT ON COLUMN public.manufacturing_orders.order_number IS 'رقم أمر التشغيل';
COMMENT ON COLUMN public.manufacturing_orders.product_name IS 'اسم القطعة المطلوبة (غرفة نوم، دولاب، سفرة...)';
COMMENT ON COLUMN public.manufacturing_orders.status IS 'مرحلة أمر التشغيل (معلق، قيد التنفيذ، مكتمل، ملغي)';

COMMENT ON TABLE public.manufacturing_order_dimensions IS 'المقاسات التفصيلية للقطع (الطول، العرض، الارتفاع، العدد)';
COMMENT ON TABLE public.manufacturing_order_materials IS 'الخامات المحددة المطلوب استهلاكها لتصنيع القطعة';
COMMENT ON TABLE public.manufacturing_checklist IS 'قائمة مراحل الجودة والمتابعة (تقطيع، تجميع، صنفرة، دهان، تنجيد، تسليم)';

-- ── 7. وحدة الأمان ومستخدمي النظام (Auth & Profiles) ─────────────
COMMENT ON TABLE public.profiles IS 'ملفات مستخدمي النظام وتحديد دور المالك أو المدير وصلاحيات الوصول';
COMMENT ON COLUMN public.profiles.role IS 'دور المستخدم: owner (مالك المصنع)، manager (مدير المصنع)';
COMMENT ON TABLE public.audit_logs IS 'سجل العمليات والرقابة لتتبع أي إدخال أو تعديل في النظام';
COMMENT ON TABLE public.backup_records IS 'سجلات النسخ الاحتياطي السحابي والمحلي مع البصمات المشفرة وحالة الاستعادة';
COMMENT ON TABLE public.sync_queue IS 'طابور المزامنة دون اتصال للعمليات المعلقة المطلوب مزامنتها مع السحابة';

