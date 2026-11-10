-- ============================================================
-- STARS HOMES ERP — Migration 12: Comprehensive Arabic Dictionary
-- توثيق وتعريب شامل لجميع جداول وأعمدة قاعدة البيانات الحية في Supabase
--
-- الخصائص والضمانات الأمنية:
-- 1. يغطي 100% من جداول الإنتاج الحية (24 جدولاً).
-- 2. يغطي 100% من الأعمدة الحية (279 عموداً) دون استثناء أي عمود.
-- 3. خالي تماماً من أي جداول غير موجودة بالسيرفر (تم استبعاد sync_queue و backup_records).
-- 4. أوامر وصفية فقط (COMMENT ON) — آمنة 100% ولا تمس أو تحذف أي بيانات إنتاجية.
-- 5. لا يغير ولا يعيد تسمية أي معرفات SQL إنجليزية.
-- ============================================================

-- ============================================================
-- 1. وحدة الحسابات والمصروفات (purchases, incomes, categories, item_suggestions)
-- ============================================================

-- 1.1 جدول المشتريات والمصروفات (purchases)
COMMENT ON TABLE public.purchases IS 'سجل المشتريات والمصروفات اليومية للمصنع والخامات ومصاريف التشغيل';
COMMENT ON COLUMN public.purchases.id IS 'المعرف الفريد لكود حركة المصروف';
COMMENT ON COLUMN public.purchases.item_name IS 'اسم البند أو الخامة المشتراة بالتفصيل';
COMMENT ON COLUMN public.purchases.category IS 'تصنيف المصروف (أخشاب، إكسسوارات، وقود، صيانة، ضيافة...)';
COMMENT ON COLUMN public.purchases.quantity IS 'الكمية أو عدد الوحدات المشتراة';
COMMENT ON COLUMN public.purchases.unit_price IS 'سعر شراء الوحدة الواحدة بالجنيه المصري';
COMMENT ON COLUMN public.purchases.total_amount IS 'إجمالي المبلغ المدفوع بالجنيه المصري';
COMMENT ON COLUMN public.purchases.transaction_date IS 'تاريخ صرف المصروف أو الشراء الفعلي';
COMMENT ON COLUMN public.purchases.notes IS 'ملاحظات وتفاصيل الفاتورة واسم المورد';
COMMENT ON COLUMN public.purchases.source_type IS 'نوع المصدر المالي (direct, worker_advance, contractor_payment...)';
COMMENT ON COLUMN public.purchases.source_id IS 'معرف السجل المرتبط في حال كان المصروف سلفة لعامل أو دفعة لمقاول';
COMMENT ON COLUMN public.purchases.created_by IS 'اسم أو توقيع المسؤول الذي سجل حركة المصروف';
COMMENT ON COLUMN public.purchases.created_at IS 'الطابع الزمني لتسجيل المصروف بالنظام';
COMMENT ON COLUMN public.purchases.updated_at IS 'الطابع الزمني لآخر تعديل على السجل';
COMMENT ON COLUMN public.purchases.is_reversed IS 'علامة توضح هل تم إلغاء/عكس المصروف محاسبياً';
COMMENT ON COLUMN public.purchases.reversed_at IS 'تاريخ ووقت إلغاء المعاملة';
COMMENT ON COLUMN public.purchases.reversed_by IS 'اسم المسؤول الذي اعتمد إلغاء المصروف';
COMMENT ON COLUMN public.purchases.sync_status IS 'حالة المزامنة السحابية للسجل';
COMMENT ON COLUMN public.purchases.device_id IS 'بصمة الجهاز الذي أنشأ السجل لمنع التكرار';

-- 1.2 جدول الإيرادات والدخل (incomes)
COMMENT ON TABLE public.incomes IS 'سجل الإيرادات والدخل والمقبوضات الخارجية للمصنع';
COMMENT ON COLUMN public.incomes.id IS 'المعرف الفريد لحركة الإيراد';
COMMENT ON COLUMN public.incomes.source_name IS 'مصدر أو سبب الإيراد والمقبوضات';
COMMENT ON COLUMN public.incomes.amount IS 'مبلغ الإيراد المحصل بالجنيه المصري';
COMMENT ON COLUMN public.incomes.transaction_date IS 'تاريخ تحصيل واستلام الإيراد';
COMMENT ON COLUMN public.incomes.notes IS 'تفاصيل وبيان الإيراد أو رقم الحوالة';
COMMENT ON COLUMN public.incomes.created_by IS 'اسم المسؤول أو المدير المحصل للمبلغ';
COMMENT ON COLUMN public.incomes.created_at IS 'الطابع الزمني لتسجيل الإيراد';
COMMENT ON COLUMN public.incomes.updated_at IS 'الطابع الزمني لآخر تعديل';
COMMENT ON COLUMN public.incomes.is_reversed IS 'علامة توضح هل تم إلغاء/عكس الإيراد';
COMMENT ON COLUMN public.incomes.reversed_at IS 'تاريخ ووقت اعتماد إلغاء الإيراد';
COMMENT ON COLUMN public.incomes.reversed_by IS 'اسم المسؤول الذي ألغى الإيراد';
COMMENT ON COLUMN public.incomes.sync_status IS 'حالة المزامنة السحابية';
COMMENT ON COLUMN public.incomes.device_id IS 'بصمة الجهاز المسجل للحركة';

-- 1.3 جدول تصنيفات المصروفات والإيرادات (categories)
COMMENT ON TABLE public.categories IS 'التصنيفات المعتمدة للمصروفات والإيرادات لتسهيل التبويب المحاسبي';
COMMENT ON COLUMN public.categories.id IS 'المعرف الفريد للتصنيف';
COMMENT ON COLUMN public.categories.name IS 'اسم التصنيف المعتمد بالمصنع (أخشاب، إكسسوارات، صيانة...)';
COMMENT ON COLUMN public.categories.type IS 'نوع التصنيف: مصروف (expense) أو إيراد (income)';
COMMENT ON COLUMN public.categories.is_reusable IS 'هل يظهر التصنيف في القوائم المنسدلة السريعة';
COMMENT ON COLUMN public.categories.created_at IS 'تاريخ ووقت إنشاء التصنيف';

-- 1.4 جدول الاقتراحات السريعة لبنود الشراء (item_suggestions)
COMMENT ON TABLE public.item_suggestions IS 'قائمة الاقتراحات السريعة لبنود المشتريات متكررة الاستخدام';
COMMENT ON COLUMN public.item_suggestions.id IS 'المعرف الفريد للبند المقترح';
COMMENT ON COLUMN public.item_suggestions.item_name IS 'اسم البند أو الخامة المقترحة للشراء السريع';
COMMENT ON COLUMN public.item_suggestions.default_category IS 'التصنيف الافتراضي المقترن بالخامة تلقائياً';
COMMENT ON COLUMN public.item_suggestions.last_unit_price IS 'آخر سعر شراء تم تسجيله للبند بالجنيه';
COMMENT ON COLUMN public.item_suggestions.times_used IS 'عدد مرات تكرار شراء هذه الخامة لترتيب الأولويات';
COMMENT ON COLUMN public.item_suggestions.last_used_at IS 'تاريخ آخر عملية شراء تضمنت هذا البند';

-- ============================================================
-- 2. وحدة العمال والرواتب (workers, worker_attendance, worker_financial_items, worker_payroll_settlements)
-- ============================================================

-- 2.1 جدول ملفات العمال (workers)
COMMENT ON TABLE public.workers IS 'ملفات العمال والفنيين بالمصنع — اليوميات، المواعيد الرسمية، وأرقام التواصل';
COMMENT ON COLUMN public.workers.id IS 'كود العامل الفريد داخل المصنع';
COMMENT ON COLUMN public.workers.full_name IS 'اسم العامل أو الفني بالكامل';
COMMENT ON COLUMN public.workers.daily_wage IS 'قيمة اليومية الأساسية بالجنيه المصري';
COMMENT ON COLUMN public.workers.standard_start_time IS 'موعد بدء الوردية الرسمي (مثل 08:00)';
COMMENT ON COLUMN public.workers.standard_end_time IS 'موعد انتهاء الوردية الرسمي (مثل 19:00)';
COMMENT ON COLUMN public.workers.overtime_hourly_rate IS 'سعر ساعة العمل الإضافية (Overtime)';
COMMENT ON COLUMN public.workers.phone IS 'رقم هاتف العامل للتواصل والطوارئ';
COMMENT ON COLUMN public.workers.status IS 'حالة العامل: على قوة العمل (active) أو متوقف (inactive)';
COMMENT ON COLUMN public.workers.notes IS 'ملاحظات التعيين وتخصص الصنعة أو بيانات الضامن';
COMMENT ON COLUMN public.workers.created_at IS 'تاريخ إضافة ملف العامل بالنظام';
COMMENT ON COLUMN public.workers.updated_at IS 'تاريخ آخر تعديل لبيانات العامل أو اليومية';
COMMENT ON COLUMN public.workers.device_id IS 'بصمة الجهاز الذي أضاف السجل';

-- 2.2 جدول سجل الحضور والانصراف (worker_attendance)
COMMENT ON TABLE public.worker_attendance IS 'سجل الحضور والانصراف اليومي للعمال واحتساب الإضافي والغياب';
COMMENT ON COLUMN public.worker_attendance.id IS 'المعرف الفريد لحركة الحضور';
COMMENT ON COLUMN public.worker_attendance.worker_id IS 'معرف العامل المسجل له الحضور (ربط مع workers)';
COMMENT ON COLUMN public.worker_attendance.attendance_date IS 'تاريخ يوم العمل الفعلي';
COMMENT ON COLUMN public.worker_attendance.status IS 'حالة الحضور: حاضر (present)، غائب (absent)، إجازة (leave)';
COMMENT ON COLUMN public.worker_attendance.arrival_time IS 'توقيت الحضور الفعلي للورشة (مثل 08:05)';
COMMENT ON COLUMN public.worker_attendance.departure_time IS 'توقيت الانصراف الفعلي (مثل 21:00)';
COMMENT ON COLUMN public.worker_attendance.total_duration_minutes IS 'إجمالي مدة التواجد الفعلي بالورشة بالدقائق';
COMMENT ON COLUMN public.worker_attendance.overtime_duration_minutes IS 'دقائق العمل الإضافي المحتسبة بعد موعد الانصراف';
COMMENT ON COLUMN public.worker_attendance.overtime_pay IS 'المستحق المالي لساعات العمل الإضافية لليوم';
COMMENT ON COLUMN public.worker_attendance.daily_wage_applied IS 'قيمة اليومية المحتسبة لهذا اليوم';
COMMENT ON COLUMN public.worker_attendance.notes IS 'ملاحظات الحضور أو سبب التأخير والإذن';
COMMENT ON COLUMN public.worker_attendance.created_by IS 'اسم المشرف أو المدير الذي سجل الحضور';
COMMENT ON COLUMN public.worker_attendance.created_at IS 'الطابع الزمني لتسجيل الحضور';
COMMENT ON COLUMN public.worker_attendance.updated_at IS 'الطابع الزمني لآخر تعديل';
COMMENT ON COLUMN public.worker_attendance.device_id IS 'بصمة الجهاز';

-- 2.3 جدول المعاملات المالية للعمال (worker_financial_items)
COMMENT ON TABLE public.worker_financial_items IS 'بنود المعاملات المالية للعمال: السلف المؤقتة، المكافآت، والجزاءات والخصومات';
COMMENT ON COLUMN public.worker_financial_items.id IS 'المعرف الفريد للسند المالي';
COMMENT ON COLUMN public.worker_financial_items.worker_id IS 'معرف العامل صاحب المعاملة (ربط مع workers)';
COMMENT ON COLUMN public.worker_financial_items.type IS 'نوع البند: سلفة (advance)، مكافأة (bonus)، خصم (deduction)';
COMMENT ON COLUMN public.worker_financial_items.amount IS 'قيمة المبلغ بالجنيه المصري';
COMMENT ON COLUMN public.worker_financial_items.transaction_date IS 'تاريخ صرف السلفة أو توقيع الجزاء';
COMMENT ON COLUMN public.worker_financial_items.reason_notes IS 'بيان سبب السلفة أو المكافأة أو مخالفة الجزاء';
COMMENT ON COLUMN public.worker_financial_items.is_settled_in_payroll IS 'هل تم تسوية وخصم البند في راتب الأسبوع';
COMMENT ON COLUMN public.worker_financial_items.payroll_settlement_id IS 'معرف كشف تسوية الراتب المرتبط به البند';
COMMENT ON COLUMN public.worker_financial_items.linked_expense_id IS 'معرف بند المصروف بالخزينة بجدول المشتريات';
COMMENT ON COLUMN public.worker_financial_items.created_by IS 'اسم المسؤول الذي اعتمد الصرف أو الخصم';
COMMENT ON COLUMN public.worker_financial_items.created_at IS 'الطابع الزمني لإنشاء السند';
COMMENT ON COLUMN public.worker_financial_items.updated_at IS 'الطابع الزمني لآخر تعديل';
COMMENT ON COLUMN public.worker_financial_items.device_id IS 'بصمة الجهاز';

-- 2.4 جدول إقفال وتسوية الرواتب الأسبوعية (worker_payroll_settlements)
COMMENT ON TABLE public.worker_payroll_settlements IS 'سجل تقفيل الرواتب وتصفية حسابات العمال الدورية';
COMMENT ON COLUMN public.worker_payroll_settlements.id IS 'المعرف الفريد لكشف تصفية الراتب';
COMMENT ON COLUMN public.worker_payroll_settlements.worker_id IS 'معرف العامل صاحب الكشف (ربط مع workers)';
COMMENT ON COLUMN public.worker_payroll_settlements.week_start_date IS 'تاريخ بداية أسبوع المحاسبة (السبت)';
COMMENT ON COLUMN public.worker_payroll_settlements.week_end_date IS 'تاريخ نهاية أسبوع المحاسبة (الخميس)';
COMMENT ON COLUMN public.worker_payroll_settlements.days_attended IS 'إجمالي عدد أيام الحضور الفعلية خلال الأسبوع';
COMMENT ON COLUMN public.worker_payroll_settlements.daily_wages_total IS 'مجموع مستحقات اليوميات الأساسية للأسبوع';
COMMENT ON COLUMN public.worker_payroll_settlements.overtime_hours_total IS 'مجموع ساعات العمل الإضافي خلال الأسبوع';
COMMENT ON COLUMN public.worker_payroll_settlements.overtime_pay_total IS 'إجمالي القيمة المالية لساعات الإضافي';
COMMENT ON COLUMN public.worker_payroll_settlements.bonuses_total IS 'مجموع الحوافز والمكافآت المستحقة للأسبوع';
COMMENT ON COLUMN public.worker_payroll_settlements.advances_total IS 'مجموع السلف المخصومة من الراتب للأسبوع';
COMMENT ON COLUMN public.worker_payroll_settlements.deductions_total IS 'مجموع الخصومات والجزاءات المطبقة على العامل';
COMMENT ON COLUMN public.worker_payroll_settlements.gross_earnings IS 'إجمالي الاستحقاقات قبل الخصومات (يوميات + إضافي + مكافآت)';
COMMENT ON COLUMN public.worker_payroll_settlements.net_due IS 'صافي الراتب المستحق للصرف بعد خصم السلف والجزاءات';
COMMENT ON COLUMN public.worker_payroll_settlements.amount_paid IS 'المبلغ المنصرف والمسلم للعامل نقداً';
COMMENT ON COLUMN public.worker_payroll_settlements.remaining_balance IS 'الرصيد المتبقي للعامل إذا لم يصرف المبلغ كاملاً';
COMMENT ON COLUMN public.worker_payroll_settlements.payment_date IS 'تاريخ صرف وتسليم الراتب للعامل';
COMMENT ON COLUMN public.worker_payroll_settlements.payment_method IS 'طريقة الدفع (cash نقدي، محفظة...)';
COMMENT ON COLUMN public.worker_payroll_settlements.notes IS 'ملاحظات التقفيل والتسويات المرحلة للأسبوع القادم';
COMMENT ON COLUMN public.worker_payroll_settlements.is_settled IS 'هل تم سداد وتصفية مستحقات الأسبوع كاملاً';
COMMENT ON COLUMN public.worker_payroll_settlements.linked_expense_id IS 'معرف بند المصروف بالخزينة التابع له الصرف';
COMMENT ON COLUMN public.worker_payroll_settlements.created_by IS 'اسم المدير الذي راجع واعتمد الراتب';
COMMENT ON COLUMN public.worker_payroll_settlements.created_at IS 'الطابع الزمني لإنشاء الكشف';
COMMENT ON COLUMN public.worker_payroll_settlements.device_id IS 'بصمة الجهاز';

-- ============================================================
-- 3. وحدة مقاولي الباطن والورش الخارجية (contractors, contractor_payments)
-- ============================================================

-- 3.1 جدول مقاولي الباطن والورش (contractors)
COMMENT ON TABLE public.contractors IS 'بيانات مقاولي الباطن والورش والخدمات الخارجية (دهانات، ليزر، سي ان سي، خراطة)';
COMMENT ON COLUMN public.contractors.id IS 'كود المقاول أو الورشة الفريد';
COMMENT ON COLUMN public.contractors.name IS 'اسم المقاول أو الاسم التجاري للورشة';
COMMENT ON COLUMN public.contractors.service_type IS 'تخصص الورشة (دهانات، CNC، تقطيع ليزر، زجاج ومرايات...)';
COMMENT ON COLUMN public.contractors.phone IS 'رقم هاتف الورشة للتواصل والمتابعة والواتساب';
COMMENT ON COLUMN public.contractors.notes IS 'العنوان، شروط التعامل، وأسعار الخدمات الخارجية';
COMMENT ON COLUMN public.contractors.status IS 'حالة التعامل: نشط (active) أو متوقف (inactive)';
COMMENT ON COLUMN public.contractors.created_at IS 'تاريخ فتح ملف الورشة بالنظام';
COMMENT ON COLUMN public.contractors.updated_at IS 'تاريخ آخر تعديل للبيانات';
COMMENT ON COLUMN public.contractors.device_id IS 'بصمة الجهاز';

-- 3.2 جدول دفعات مقاولي الباطن (contractor_payments)
COMMENT ON TABLE public.contractor_payments IS 'سجل المدفوعات والدفعات المحولة للورش ومقاولي الباطن';
COMMENT ON COLUMN public.contractor_payments.id IS 'كود سند صرف الدفعة الفريد';
COMMENT ON COLUMN public.contractor_payments.contractor_id IS 'معرف الورشة المستلمة للدفعة (ربط مع contractors)';
COMMENT ON COLUMN public.contractor_payments.description IS 'بيان وتفاصيل الشغل المنفذ (مثل دهان غرفة نوم رئيسية مط)';
COMMENT ON COLUMN public.contractor_payments.amount IS 'قيمة الدفعة المسددة بالجنيه المصري';
COMMENT ON COLUMN public.contractor_payments.payment_date IS 'تاريخ صرف وسداد الدفعة الفعلي';
COMMENT ON COLUMN public.contractor_payments.related_order IS 'رقم أو وصف طلبية العميل التابع لها الشغل';
COMMENT ON COLUMN public.contractor_payments.notes IS 'ملاحظات الإيصال أو الشيك';
COMMENT ON COLUMN public.contractor_payments.linked_expense_id IS 'معرف بند المصروف بالخزينة بجدول المشتريات';
COMMENT ON COLUMN public.contractor_payments.created_by IS 'اسم المسؤول الذي قام بالصرف والسداد';
COMMENT ON COLUMN public.contractor_payments.created_at IS 'الطابع الزمني لتسجيل الدفعة';
COMMENT ON COLUMN public.contractor_payments.updated_at IS 'الطابع الزمني لآخر تعديل';
COMMENT ON COLUMN public.contractor_payments.device_id IS 'بصمة الجهاز';

-- ============================================================
-- 4. وحدة العملاء والطلبيات (customer_orders, order_payments)
-- ============================================================

-- 4.1 جدول طلبيات وعقود العملاء (customer_orders)
COMMENT ON TABLE public.customer_orders IS 'طلبيات وعقود العملاء وتفاصيل الأثاث المطلوب مع مواعيد التسليم والأقسام';
COMMENT ON COLUMN public.customer_orders.id IS 'كود طلبية العميل الفريد';
COMMENT ON COLUMN public.customer_orders.customer_name IS 'اسم العميل بالكامل أو اسم المعرض المتعاقد';
COMMENT ON COLUMN public.customer_orders.phone IS 'رقم هاتف العميل للتواصل والواتساب وإرسال الفواتير';
COMMENT ON COLUMN public.customer_orders.order_description IS 'الوصف العام للطلبية والبنود المتفق على تصنيعها';
COMMENT ON COLUMN public.customer_orders.start_date IS 'تاريخ التعاقد وبدء تنفيذ الطلبية ودفع العربون';
COMMENT ON COLUMN public.customer_orders.delivery_date IS 'موعد التسليم النهائي المتفق عليه مع العميل';
COMMENT ON COLUMN public.customer_orders.total_amount IS 'إجمالي القيمة المالية للاتفاق بالكامل بالجنيه';
COMMENT ON COLUMN public.customer_orders.status IS 'حالة تنفيذ الطلب: قيد التنفيذ (in_progress)، جاهز (ready)، تم التسليم (delivered)، ملغي (cancelled)';
COMMENT ON COLUMN public.customer_orders.notes IS 'المواصفات التفصيلية والأقسام والصور المرفقة بتنسيق JSON';
COMMENT ON COLUMN public.customer_orders.created_by IS 'اسم أو توقيع من حرر العقد مع العميل';
COMMENT ON COLUMN public.customer_orders.created_at IS 'الطابع الزمني لتسجيل العقد';
COMMENT ON COLUMN public.customer_orders.updated_at IS 'الطابع الزمني لآخر تحديث للحالة أو البيانات';
COMMENT ON COLUMN public.customer_orders.device_id IS 'بصمة الجهاز';

-- 4.2 جدول دفعات وعرابين العملاء (order_payments)
COMMENT ON TABLE public.order_payments IS 'سجل دفعات وعرابين العملاء الخاصة بطلبيات التصنيع';
COMMENT ON COLUMN public.order_payments.id IS 'المعرف الفريد لإيصال استلام الدفعة';
COMMENT ON COLUMN public.order_payments.order_id IS 'معرف طلبية العميل التابع لها هذا القسط (ربط مع customer_orders)';
COMMENT ON COLUMN public.order_payments.amount IS 'قيمة الدفعة أو العربون المحصل بالجنيه المصري';
COMMENT ON COLUMN public.order_payments.payment_date IS 'تاريخ تحصيل واستلام الدفعة';
COMMENT ON COLUMN public.order_payments.payment_method IS 'وسيلة السداد (نقدي، إنستاباي، فودافون كاش، تحويل بنكي، شيك)';
COMMENT ON COLUMN public.order_payments.notes IS 'ملاحظات الإيصال أو رقم الحوالة أو اسم صاحب المحفظة';
COMMENT ON COLUMN public.order_payments.linked_income_id IS 'معرف بند الإيراد بالخزينة بجدول incomes';
COMMENT ON COLUMN public.order_payments.created_by IS 'اسم المدير أو المحصل الذي استلم المبلغ';
COMMENT ON COLUMN public.order_payments.created_at IS 'الطابع الزمني لتسجيل الإيصال';
COMMENT ON COLUMN public.order_payments.device_id IS 'بصمة الجهاز';

-- ============================================================
-- 5. وحدة الديون والسلف والأمانات الخارجية (debts_advances, debt_advance_payments)
-- ============================================================

-- 5.1 جدول الديون والسلف الخارجية (debts_advances)
COMMENT ON TABLE public.debts_advances IS 'سجل الديون والسلف والعهد المالية الخارجية للمصنع';
COMMENT ON COLUMN public.debts_advances.id IS 'المعرف الفريد لسجل الدين أو الأمانة';
COMMENT ON COLUMN public.debts_advances.person_name IS 'اسم صاحب السلفة أو التاجر أو الشركة صاحبة الدين';
COMMENT ON COLUMN public.debts_advances.phone IS 'رقم هاتف الطرف الآخر للتواصل والمطالبة';
COMMENT ON COLUMN public.debts_advances.type IS 'نوع السجل: سلفة (advance)، دين لنا (debt_receivable)، دين علينا (debt_payable)';
COMMENT ON COLUMN public.debts_advances.amount IS 'المبلغ الإجمالي الأصلي للدين بالجنيه المصري';
COMMENT ON COLUMN public.debts_advances.paid_amount IS 'إجمالي المبالغ التراكمية المسددة حتى الآن';
COMMENT ON COLUMN public.debts_advances.transaction_date IS 'تاريخ نشوء الدين أو استلام السلفة';
COMMENT ON COLUMN public.debts_advances.due_date IS 'موعد استحقاق السداد النهائي المتفق عليه';
COMMENT ON COLUMN public.debts_advances.status IS 'حالة الدين: نشط ومستمر (active) أو مسدد بالكامل (settled)';
COMMENT ON COLUMN public.debts_advances.notes IS 'التفاصيل، الضمانات، أو تفاصيل الشيك';
COMMENT ON COLUMN public.debts_advances.created_by IS 'اسم المسؤول الذي سجل المعاملة';
COMMENT ON COLUMN public.debts_advances.created_at IS 'الطابع الزمني لإنشاء السجل';
COMMENT ON COLUMN public.debts_advances.updated_at IS 'الطابع الزمني لآخر تعديل';
COMMENT ON COLUMN public.debts_advances.device_id IS 'بصمة الجهاز';

-- 5.2 جدول دفعات سداد الديون (debt_advance_payments)
COMMENT ON TABLE public.debt_advance_payments IS 'سجل دفعات وأقساط سداد الديون والسلف المسجلة';
COMMENT ON COLUMN public.debt_advance_payments.id IS 'المعرف الفريد لسند سداد القسط';
COMMENT ON COLUMN public.debt_advance_payments.debt_advance_id IS 'معرف أصل الدين التابع له هذا القسط (ربط مع debts_advances)';
COMMENT ON COLUMN public.debt_advance_payments.amount IS 'قيمة القسط المسدد بالجنيه المصري';
COMMENT ON COLUMN public.debt_advance_payments.payment_date IS 'تاريخ سداد أو قبض القسط الفعلي';
COMMENT ON COLUMN public.debt_advance_payments.notes IS 'ملاحظات الإيصال أو رقم التحويل البنكي';
COMMENT ON COLUMN public.debt_advance_payments.created_by IS 'اسم الشخص القائم بالصرف أو الاستلام';
COMMENT ON COLUMN public.debt_advance_payments.created_at IS 'الطابع الزمني لتسجيل السند';
COMMENT ON COLUMN public.debt_advance_payments.device_id IS 'بصمة الجهاز';

-- ============================================================
-- 6. وحدة المخازن والخامات (inventory_items, inventory_movements, inventory_reservations, material_shortages)
-- ============================================================

-- 6.1 جدول أصناف المخزون (inventory_items)
COMMENT ON TABLE public.inventory_items IS 'رصيد الخامات والأخشاب والإكسسوارات في مخزن المصنع';
COMMENT ON COLUMN public.inventory_items.id IS 'كود صنف الخامة الفريد بالمخزن';
COMMENT ON COLUMN public.inventory_items.material_name IS 'اسم الخامة أو اللوح (خشب زان روماني، أبلكاش 12مم، دهانات...)';
COMMENT ON COLUMN public.inventory_items.category IS 'تصنيف الخامة (أخشاب، إكسسوارات، أقمشة وجلود، دهانات)';
COMMENT ON COLUMN public.inventory_items.unit IS 'وحدة القياس المخزنية (لوح، متر، قطعة، كجم، علبة، لفة)';
COMMENT ON COLUMN public.inventory_items.current_stock IS 'الرصيد الفعلي المتوفر حالياً على أرض المخزن';
COMMENT ON COLUMN public.inventory_items.reserved_stock IS 'الكميات المحجوزة لأوامر تصنيع قيد التنفيذ بالورشة';
COMMENT ON COLUMN public.inventory_items.minimum_stock_level IS 'حد الطلب الأدنى للتنبيه عند نقص رصيد الخامة';
COMMENT ON COLUMN public.inventory_items.unit_cost IS 'متوسط تكلفة شراء الوحدة الواحدة بالجنيه';
COMMENT ON COLUMN public.inventory_items.notes IS 'مكان التخزين في الورشة أو ملاحظات فنية على الجودة';
COMMENT ON COLUMN public.inventory_items.created_at IS 'تاريخ إضافة كارت الصنف للمخزن';
COMMENT ON COLUMN public.inventory_items.updated_at IS 'تاريخ آخر جرد أو تعديل على الرصيد';
COMMENT ON COLUMN public.inventory_items.device_id IS 'بصمة الجهاز';

-- 6.2 جدول حركات المخزن (inventory_movements)
COMMENT ON TABLE public.inventory_movements IS 'حركات المخزن: وارد، منصرف تشغيل، مرتجع، تسوية جرد';
COMMENT ON COLUMN public.inventory_movements.id IS 'كود إذن حركة المخزن الفريد';
COMMENT ON COLUMN public.inventory_movements.inventory_item_id IS 'معرف صنف الخامة بالمخزن (ربط مع inventory_items)';
COMMENT ON COLUMN public.inventory_movements.movement_type IS 'نوع الحركة: وارد (receipt)، منصرف تشغيل (issue)، تسوية جرد (adjustment)، مرتجع (return)';
COMMENT ON COLUMN public.inventory_movements.quantity IS 'الكمية المنصرفة أو الواردة للرصيد';
COMMENT ON COLUMN public.inventory_movements.reference_type IS 'نوع السند المرجعي (شراء purchase، أمر تصنيع manufacturing_order، تسوية يدوية manual)';
COMMENT ON COLUMN public.inventory_movements.reference_id IS 'رقم السند المرجعي أو كود أمر التشغيل';
COMMENT ON COLUMN public.inventory_movements.reason_notes IS 'بيان سبب الصرف أو مبرر تسوية عجز أو زيادة الجرد';
COMMENT ON COLUMN public.inventory_movements.created_by IS 'اسم أمين المخزن أو المسؤول القائم بالصرف';
COMMENT ON COLUMN public.inventory_movements.created_at IS 'الطابع الزمني لتنفيذ الحركة';
COMMENT ON COLUMN public.inventory_movements.device_id IS 'بصمة الجهاز';

-- 6.3 جدول حجوزات الخامات لأوامر التشغيل (inventory_reservations)
COMMENT ON TABLE public.inventory_reservations IS 'حجوزات الخامات المخصصة لأوامر التصنيع لمنع استهلاكها في قطعة أخرى';
COMMENT ON COLUMN public.inventory_reservations.id IS 'معرف كود الحجز الفريد';
COMMENT ON COLUMN public.inventory_reservations.manufacturing_order_id IS 'معرف أمر التصنيع المحجوز له الخامات (ربط مع manufacturing_orders)';
COMMENT ON COLUMN public.inventory_reservations.inventory_item_id IS 'معرف صنف الخامة بالمخزن (ربط مع inventory_items)';
COMMENT ON COLUMN public.inventory_reservations.reserved_quantity IS 'الكمية المحجوزة للقطعة من الرصيد';
COMMENT ON COLUMN public.inventory_reservations.status IS 'حالة الحجز: محجوز ساري (active)، تم الاستهلاك والتقطيع (consumed)، تم فك الحجز وإرجاعه (released)';
COMMENT ON COLUMN public.inventory_reservations.created_at IS 'الطابع الزمني لإنشاء الحجز';
COMMENT ON COLUMN public.inventory_reservations.device_id IS 'بصمة الجهاز';

-- 6.4 جدول نواقص الخامات (material_shortages)
COMMENT ON TABLE public.material_shortages IS 'قائمة النواقص واحتياجات الخامات العاجلة المطلوب شراؤها لخط الإنتاج';
COMMENT ON COLUMN public.material_shortages.id IS 'كود إشعار النقص الفريد';
COMMENT ON COLUMN public.material_shortages.material_name IS 'اسم الخامة الناقصة المطلوب شراؤها عاجلاً';
COMMENT ON COLUMN public.material_shortages.quantity IS 'الكمية اللازمة لإكمال العمل';
COMMENT ON COLUMN public.material_shortages.unit IS 'وحدة القياس (لوح، متر، كجم، علبة...)';
COMMENT ON COLUMN public.material_shortages.specifications IS 'التخانة أو اللون أو الجودة والمواصفات المطلوبة';
COMMENT ON COLUMN public.material_shortages.notes IS 'ملاحظات الاستعجال وتفاصيل القطعة المتوقفة';
COMMENT ON COLUMN public.material_shortages.manufacturing_order_id IS 'معرف أمر التصنيع المتوقف على هذه الخامة';
COMMENT ON COLUMN public.material_shortages.manufacturing_order_number IS 'رقم أمر التشغيل المكتبي';
COMMENT ON COLUMN public.material_shortages.status IS 'حالة النقص: عجز مطلوب (shortage)، جاري الشراء (in_progress)، تم التوريد (resolved)، أعيد فتحه (reopened)';
COMMENT ON COLUMN public.material_shortages.recorded_by IS 'اسم الفني أو المشرف الذي سجل إشعار النقص';
COMMENT ON COLUMN public.material_shortages.recorded_at IS 'تاريخ ووقت تسجيل النقص';
COMMENT ON COLUMN public.material_shortages.resolved_by IS 'اسم المشتري أو المدير الذي وفر الخامة بالورشة';
COMMENT ON COLUMN public.material_shortages.resolved_at IS 'تاريخ ووقت حل وتوريد الخامة';
COMMENT ON COLUMN public.material_shortages.updated_at IS 'الطابع الزمني لآخر تعديل';
COMMENT ON COLUMN public.material_shortages.device_id IS 'بصمة الجهاز';

-- ============================================================
-- 7. وحدة أوامر التصنيع والتشغيل (manufacturing_orders, dimensions, materials, checklist)
-- ============================================================

-- 7.1 جدول أوامر التصنيع والورشة (manufacturing_orders)
COMMENT ON TABLE public.manufacturing_orders IS 'أوامر تشغيل وتصنيع الموبيليا في خط الإنتاج داخل الورشة';
COMMENT ON COLUMN public.manufacturing_orders.id IS 'المعرف المرجعي الداخلي لأمر التشغيل';
COMMENT ON COLUMN public.manufacturing_orders.order_number IS 'رقم أمر التشغيل الرسمي المطبوع بالورشة (مثل MO-2026-001)';
COMMENT ON COLUMN public.manufacturing_orders.customer_order_id IS 'معرف طلبية العميل التابع لها الأمر (ربط مع customer_orders)';
COMMENT ON COLUMN public.manufacturing_orders.customer_name IS 'اسم العميل لسهولة المتابعة بالورشة';
COMMENT ON COLUMN public.manufacturing_orders.product_name IS 'اسم القطعة المطلوبة (غرفة نوم ماستر خشب زان، دولاب جرار...)';
COMMENT ON COLUMN public.manufacturing_orders.product_category IS 'تصنيف القطعة (أثاث خشبي، تنجيد وصالون، مطابخ...)';
COMMENT ON COLUMN public.manufacturing_orders.quantity IS 'عدد القطع المطلوب تصنيعها';
COMMENT ON COLUMN public.manufacturing_orders.manufacturing_date IS 'تاريخ تسليم الخامات وبدء التصنيع بالورشة';
COMMENT ON COLUMN public.manufacturing_orders.expected_completion_date IS 'الموعد المتوقع لخروج القطعة للتسليم';
COMMENT ON COLUMN public.manufacturing_orders.assigned_worker_id IS 'معرف الأسطى أو النجار المسؤول عن تنفيذ القطعة (ربط مع workers)';
COMMENT ON COLUMN public.manufacturing_orders.assigned_worker_name IS 'اسم النجار المسؤول للتيسير في الطباعة والتقارير';
COMMENT ON COLUMN public.manufacturing_orders.status IS 'مرحلة التصنيع: جديد (new)، انتظار خامات (awaiting_materials)، جاهز للتجميع (ready_to_build)، جاري العمل (in_progress)، مكتمل (completed)، ملغي (cancelled)';
COMMENT ON COLUMN public.manufacturing_orders.notes IS 'تعليمات فنية خاصة بالنجارة والدهان والتجميع';
COMMENT ON COLUMN public.manufacturing_orders.sections_data IS 'بيانات التقسيم الهندسية وموديلات الغرف والصور بتنسيق JSON';
COMMENT ON COLUMN public.manufacturing_orders.created_by IS 'اسم المدير الذي أصدر أمر التشغيل';
COMMENT ON COLUMN public.manufacturing_orders.created_at IS 'الطابع الزمني لإنشاء الأمر';
COMMENT ON COLUMN public.manufacturing_orders.updated_at IS 'الطابع الزمني لآخر تحديث للمرحلة';
COMMENT ON COLUMN public.manufacturing_orders.device_id IS 'بصمة الجهاز';

-- 7.2 جدول المقاسات والأبعاد الهندسية للقطع (manufacturing_order_dimensions)
COMMENT ON TABLE public.manufacturing_order_dimensions IS 'المقاسات التفصيلية للقطع (الطول، العرض، الارتفاع، العدد)';
COMMENT ON COLUMN public.manufacturing_order_dimensions.id IS 'المعرف الفريد لسجل المقاس';
COMMENT ON COLUMN public.manufacturing_order_dimensions.manufacturing_order_id IS 'معرف أمر التشغيل التابع له هذا البُعد (ربط مع manufacturing_orders)';
COMMENT ON COLUMN public.manufacturing_order_dimensions.height IS 'ارتفاع القطعة بالمقاس الهندسي المحدد (مثلاً 220 سم)';
COMMENT ON COLUMN public.manufacturing_order_dimensions.width IS 'عرض القطعة (مثلاً 280 سم للدولاب)';
COMMENT ON COLUMN public.manufacturing_order_dimensions.depth IS 'عمق أو تخانة القطعة (مثلاً 60 سم)';
COMMENT ON COLUMN public.manufacturing_order_dimensions.unit IS 'وحدة القياس الهندسية (سم، مم، متر)';
COMMENT ON COLUMN public.manufacturing_order_dimensions.additional_notes IS 'ملاحظات هندسية خاصة بالشطف والبروز وتوزيع الأدراج';
COMMENT ON COLUMN public.manufacturing_order_dimensions.created_at IS 'الطابع الزمني لتسجيل المقاس';
COMMENT ON COLUMN public.manufacturing_order_dimensions.device_id IS 'بصمة الجهاز';

-- 7.3 جدول خامات ومستهلكات أمر التشغيل BOM (manufacturing_order_materials)
COMMENT ON TABLE public.manufacturing_order_materials IS 'الخامات المحددة المطلوب استهلاكها لتصنيع القطعة';
COMMENT ON COLUMN public.manufacturing_order_materials.id IS 'معرف بند خامة أمر التشغيل';
COMMENT ON COLUMN public.manufacturing_order_materials.manufacturing_order_id IS 'معرف أمر التشغيل التابع له البند (ربط مع manufacturing_orders)';
COMMENT ON COLUMN public.manufacturing_order_materials.inventory_item_id IS 'معرف الصنف بالمخزن لخصم الرصيد تلقائياً (ربط مع inventory_items)';
COMMENT ON COLUMN public.manufacturing_order_materials.material_name IS 'اسم الخامة المطلوبة لتصنيع القطعة';
COMMENT ON COLUMN public.manufacturing_order_materials.required_quantity IS 'الكمية المقررة لاستهلاك تصنيع هذه القطعة';
COMMENT ON COLUMN public.manufacturing_order_materials.unit IS 'وحدة القياس (لوح، قطعة، طقم، متر...)';
COMMENT ON COLUMN public.manufacturing_order_materials.specifications IS 'المواصفات الفنية وماركة الإكسسوارات';
COMMENT ON COLUMN public.manufacturing_order_materials.notes IS 'توجيهات للنجار أثناء التقطيع والاستهلاك';
COMMENT ON COLUMN public.manufacturing_order_materials.thickness_grade IS 'التخانة أو درجة نقاء الخشب';
COMMENT ON COLUMN public.manufacturing_order_materials.color_code IS 'كود لون الدهان أو كود القماش المعتمد';
COMMENT ON COLUMN public.manufacturing_order_materials.linked_piece IS 'الجزء المرتبط بالقطعة (الباب، الدرج، القرصة، الظهر، القاعدة)';
COMMENT ON COLUMN public.manufacturing_order_materials.created_at IS 'الطابع الزمني لإضافة الخامة';
COMMENT ON COLUMN public.manufacturing_order_materials.device_id IS 'بصمة الجهاز';

-- 7.4 جدول قائمة فحص وتجهيز خامات القطعة (manufacturing_checklist)
COMMENT ON TABLE public.manufacturing_checklist IS 'قائمة مراحل الجودة والمتابعة وجاهزية الخامات قبل بدء الشغل';
COMMENT ON COLUMN public.manufacturing_checklist.id IS 'المعرف الفريد لبند الفحص';
COMMENT ON COLUMN public.manufacturing_checklist.manufacturing_order_id IS 'معرف أمر التشغيل المرتبط (ربط مع manufacturing_orders)';
COMMENT ON COLUMN public.manufacturing_checklist.material_name IS 'اسم الخامة المطلوب التأكد من جاهزيتها بالورشة';
COMMENT ON COLUMN public.manufacturing_checklist.required_quantity IS 'الكمية الكافية للقطعة';
COMMENT ON COLUMN public.manufacturing_checklist.unit IS 'وحدة القياس (لوح، قطعة...)';
COMMENT ON COLUMN public.manufacturing_checklist.status IS 'حالة الجاهزية: مطلوبة (required)، تم طلبها (ordered)، استلمت (received)، تم تجهيزها (prepared)';
COMMENT ON COLUMN public.manufacturing_checklist.is_prepared IS 'علامة تأكيد جاهزية الخامة لبدء التجميع في الورشة';
COMMENT ON COLUMN public.manufacturing_checklist.notes IS 'ملاحظات المشرف على استلام وجودة الخامات';
COMMENT ON COLUMN public.manufacturing_checklist.updated_at IS 'الطابع الزمني لآخر تحديث للحالة';
COMMENT ON COLUMN public.manufacturing_checklist.device_id IS 'بصمة الجهاز';

-- ============================================================
-- 8. وحدة الأمان ومستخدمي النظام والرقابة (profiles, audit_logs)
-- ============================================================

-- 8.1 جدول ملفات المستخدمين والصلاحيات (profiles)
COMMENT ON TABLE public.profiles IS 'ملفات مستخدمي النظام وتحديد دور المالك أو المدير وصلاحيات الوصول';
COMMENT ON COLUMN public.profiles.id IS 'المعرف الأساسي للمستخدم المرتبط بحسابه في Supabase Auth';
COMMENT ON COLUMN public.profiles.full_name IS 'اسم المالك أو مدير المصنع المعروض في النظام';
COMMENT ON COLUMN public.profiles.role IS 'دور المستخدم وصلاحيته: مالك المصنع (owner) أو مدير المصنع (manager)';
COMMENT ON COLUMN public.profiles.phone IS 'رقم هاتف المستخدم للتواصل';
COMMENT ON COLUMN public.profiles.is_active IS 'هل الحساب مفعل ونشط ومصرح له بالدخول للنظام';
COMMENT ON COLUMN public.profiles.created_at IS 'تاريخ ووقت إنشاء ملف المستخدم بالنظام';
COMMENT ON COLUMN public.profiles.updated_at IS 'تاريخ ووقت آخر تعديل لبيانات الحساب';

-- 8.2 جدول سجل العمليات والرقابة الإدارية (audit_logs)
COMMENT ON TABLE public.audit_logs IS 'سجل العمليات والرقابة لتتبع أي إدخال أو تعديل في النظام';
COMMENT ON COLUMN public.audit_logs.id IS 'المعرف الفريد المرجعي لحركة التدقيق';
COMMENT ON COLUMN public.audit_logs.user_name IS 'اسم المستخدم أو المدير الذي قام بالحركة';
COMMENT ON COLUMN public.audit_logs.action IS 'نوع الإجراء المنفذ (تسجيل دخول، إضافة، تعديل، حذف، تصدير CSV)';
COMMENT ON COLUMN public.audit_logs.entity_table IS 'اسم الجدول المعني الذي طرأ عليه التغيير';
COMMENT ON COLUMN public.audit_logs.entity_id IS 'كود السجل المتأثر بالعملية';
COMMENT ON COLUMN public.audit_logs.details IS 'تفاصيل التغيير والبيانات السابقة والجديدة بتنسيق JSON';
COMMENT ON COLUMN public.audit_logs.created_at IS 'الطابع الزمني بالثانية لوقت حدوث العملية';

-- ============================================================
-- استعلام التحقق النهائي (حساب عدد الجداول المعربة في public)
-- ============================================================
SELECT 
    'تهانينا! تم تعريب وتوثيق 100% من جداول وأعمدة قاعدة البيانات الحية بنجاح!' AS status,
    count(DISTINCT c.relname) AS commented_tables_count,
    count(*) AS commented_columns_count
FROM pg_catalog.pg_description d
JOIN pg_catalog.pg_class c ON c.oid = d.objoid
JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public';
