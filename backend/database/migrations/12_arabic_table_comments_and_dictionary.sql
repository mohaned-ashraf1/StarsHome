-- ============================================================
-- STARS HOMES ERP — Migration 12: Arabic Table & Column Comments
-- توثيق وتعريب جداول وأعمدة قاعدة البيانات باللغة العربية داخل Supabase Dashboard
--
-- تعليمات التطبيق:
-- افتح Supabase Dashboard -> SQL Editor -> الصق محتوى هذا الملف واضغط RUN.
-- هذا السكريبت آمن بنسبة 100% (Non-Destructive):
-- - لا يحذف أي بيانات إطلاقاً.
-- - لا يغير أو يعيد تسمية أي جدول أو عمود.
-- - يضيف فقط التسميات والشروحات العربية الوصفية في واجهة Supabase Table Editor.
-- ============================================================

-- ── 1. وحدة الحسابات والمصروفات (Accounts & Expenses) ───────────
COMMENT ON TABLE public.purchases IS 'سجل المشتريات والمصروفات اليومية للمصنع والخامات ومصاريف التشغيل';
COMMENT ON COLUMN public.purchases.id IS 'المعرف الفريد لكود حركة المصروف';
COMMENT ON COLUMN public.purchases.item_name IS 'اسم البند أو الخامة المشتراة';
COMMENT ON COLUMN public.purchases.category IS 'تصنيف المصروف (أخشاب، إكسسوارات، صيانة، ضيافة...)';
COMMENT ON COLUMN public.purchases.quantity IS 'الكمية المشتراة';
COMMENT ON COLUMN public.purchases.unit_price IS 'سعر الوحدة بالجنيه المصري';
COMMENT ON COLUMN public.purchases.total_amount IS 'المبلغ الإجمالي المدفوع بالجنيه المصري';
COMMENT ON COLUMN public.purchases.transaction_date IS 'تاريخ الشراء أو صرف المصروف الفعلي';
COMMENT ON COLUMN public.purchases.notes IS 'ملاحظات وتفاصيل الفاتورة واسم المورد';
COMMENT ON COLUMN public.purchases.created_by IS 'اسم المالك أو المدير الذي قام بالتسجيل';

COMMENT ON TABLE public.incomes IS 'سجل الإيرادات والدخل والمقبوضات الخارجية للمصنع';
COMMENT ON COLUMN public.incomes.id IS 'المعرف الفريد لحركة الإيراد';
COMMENT ON COLUMN public.incomes.source_name IS 'مصدر أو سبب الإيراد والمقبوضات';
COMMENT ON COLUMN public.incomes.amount IS 'مبلغ الإيراد المحصل بالجنيه المصري';
COMMENT ON COLUMN public.incomes.transaction_date IS 'تاريخ تحصيل الإيراد';
COMMENT ON COLUMN public.incomes.created_by IS 'اسم الموظف أو المدير المستلم للمبلغ';
COMMENT ON COLUMN public.incomes.notes IS 'تفاصيل وبيان الإيراد أو رقم الحوالة';

COMMENT ON TABLE public.categories IS 'التصنيفات المعتمدة للمصروفات والإيرادات لتسهيل التبويب';
COMMENT ON COLUMN public.categories.name IS 'اسم التصنيف المعتمد بالمصنع';
COMMENT ON COLUMN public.categories.type IS 'نوع التصنيف: مصروف (expense) أو إيراد (income)';
COMMENT ON COLUMN public.categories.is_reusable IS 'ظهور التصنيف في القوائم المنسدلة السريعة';

COMMENT ON TABLE public.item_suggestions IS 'قائمة الاقتراحات السريعة لبنود المشتريات متكررة الاستخدام';
COMMENT ON COLUMN public.item_suggestions.item_name IS 'اسم الخامة أو البند المقترح للشراء السريع';
COMMENT ON COLUMN public.item_suggestions.default_category IS 'التصنيف التلقائي المقترن بالخامة';
COMMENT ON COLUMN public.item_suggestions.last_unit_price IS 'آخر سعر وحدة تم الشراء به للمقارنة والتسعير';
COMMENT ON COLUMN public.item_suggestions.times_used IS 'عدد مرات تكرار شراء هذه الخامة لترتيب الأولويات';

COMMENT ON TABLE public.debts_advances IS 'سجل السلف والديون والعهد المالية الخارجية للمصنع';
COMMENT ON COLUMN public.debts_advances.person_name IS 'اسم صاحب السلفة أو الدين الخارجي';
COMMENT ON COLUMN public.debts_advances.phone IS 'رقم هاتف صاحب الدين للمتابعة';
COMMENT ON COLUMN public.debts_advances.type IS 'نوع السجل: سلفة (advance)، دين لنا (debt_receivable)، دين علينا (debt_payable)';
COMMENT ON COLUMN public.debts_advances.amount IS 'المبلغ الإجمالي الأصلي للدين بالجنيه';
COMMENT ON COLUMN public.debts_advances.paid_amount IS 'إجمالي المبالغ المسددة حتى الآن';
COMMENT ON COLUMN public.debts_advances.transaction_date IS 'تاريخ نشوء الدين أو استلام السلفة';
COMMENT ON COLUMN public.debts_advances.due_date IS 'موعد استحقاق السداد النهائي';
COMMENT ON COLUMN public.debts_advances.status IS 'حالة الدين: قائم ونشط (active) أو مسدد بالكامل (settled)';

COMMENT ON TABLE public.debt_advance_payments IS 'سجل دفعات سداد الديون والسلف المسجلة';
COMMENT ON COLUMN public.debt_advance_payments.debt_advance_id IS 'معرف أصل الدين التابع له هذا القسط';
COMMENT ON COLUMN public.debt_advance_payments.amount IS 'قيمة القسط المسدد بالجنيه';
COMMENT ON COLUMN public.debt_advance_payments.payment_date IS 'تاريخ سداد القسط الفعلي';

-- ── 2. وحدة العمال والرواتب (Workers & Payroll) ──────────────────
COMMENT ON TABLE public.workers IS 'ملفات العمال والفنيين بالمصنع — اليوميات، المواعيد الرسمية، وأرقام التواصل';
COMMENT ON COLUMN public.workers.full_name IS 'اسم العامل أو الفني بالكامل';
COMMENT ON COLUMN public.workers.daily_wage IS 'قيمة اليومية الأساسية بالجنيه المصري';
COMMENT ON COLUMN public.workers.standard_start_time IS 'موعد بدء الوردية الرسمي (مثل 08:00)';
COMMENT ON COLUMN public.workers.standard_end_time IS 'موعد انتهاء الوردية الرسمي (مثل 19:00)';
COMMENT ON COLUMN public.workers.overtime_hourly_rate IS 'سعر ساعة العمل الإضافية (Overtime)';
COMMENT ON COLUMN public.workers.phone IS 'رقم هاتف العامل للتواصل والطوارئ';
COMMENT ON COLUMN public.workers.status IS 'حالة العامل: على قوة العمل (active) أو متوقف (inactive)';

COMMENT ON TABLE public.worker_attendance IS 'سجل الحضور والانصراف اليومي للعمال واحتساب الإضافي والغياب';
COMMENT ON COLUMN public.worker_attendance.worker_id IS 'معرف العامل المسجل له الحضور';
COMMENT ON COLUMN public.worker_attendance.attendance_date IS 'تاريخ يوم العمل الفعلي';
COMMENT ON COLUMN public.worker_attendance.status IS 'حالة الحضور: حاضر (present)، غائب (absent)، إجازة (leave)';
COMMENT ON COLUMN public.worker_attendance.arrival_time IS 'توقيت الحضور الفعلي للورشة';
COMMENT ON COLUMN public.worker_attendance.departure_time IS 'توقيت الانصراف الفعلي';
COMMENT ON COLUMN public.worker_attendance.total_duration_minutes IS 'إجمالي زمن التواجد الفعلي بالدقائق';
COMMENT ON COLUMN public.worker_attendance.overtime_duration_minutes IS 'دقائق العمل الإضافي المعتمدة';
COMMENT ON COLUMN public.worker_attendance.overtime_pay IS 'الأجر الإضافي المستحق لليوم';
COMMENT ON COLUMN public.worker_attendance.daily_wage_applied IS 'اليومية المحتسبة لليوم';

COMMENT ON TABLE public.worker_financial_items IS 'بنود المعاملات المالية للعمال: السلف المؤقتة، المكافآت، والجزاءات والخصومات';
COMMENT ON COLUMN public.worker_financial_items.worker_id IS 'معرف العامل صاحب المعاملة';
COMMENT ON COLUMN public.worker_financial_items.type IS 'نوع المعاملة: سلفة (advance)، مكافأة (bonus)، خصم (deduction)';
COMMENT ON COLUMN public.worker_financial_items.amount IS 'قيمة المبلغ بالجنيه المصري';
COMMENT ON COLUMN public.worker_financial_items.transaction_date IS 'تاريخ صرف السلفة أو توقيع الجزاء';
COMMENT ON COLUMN public.worker_financial_items.is_settled_in_payroll IS 'هل تم تسوية وخصم البند في راتب الأسبوع';

COMMENT ON TABLE public.worker_payroll_settlements IS 'سجل تقفيل الرواتب وتصفية حسابات العمال الدورية';
COMMENT ON COLUMN public.worker_payroll_settlements.worker_id IS 'معرف العامل صاحب كشف الراتب';
COMMENT ON COLUMN public.worker_payroll_settlements.week_start_date IS 'تاريخ بداية أسبوع المحاسبة (السبت)';
COMMENT ON COLUMN public.worker_payroll_settlements.week_end_date IS 'تاريخ نهاية أسبوع المحاسبة (الخميس)';
COMMENT ON COLUMN public.worker_payroll_settlements.gross_earnings IS 'إجمالي الاستحقاقات قبل الخصم';
COMMENT ON COLUMN public.worker_payroll_settlements.net_due IS 'صافي الراتب المستحق للصرف بعد إضافة الإضافي وخصم السلف';
COMMENT ON COLUMN public.worker_payroll_settlements.amount_paid IS 'المبلغ المسلم للعامل نقداً';
COMMENT ON COLUMN public.worker_payroll_settlements.is_settled IS 'هل تم سداد الراتب كاملاً';

-- ── 3. وحدة مقاولي الباطن والورش (Contractors) ──────────────────
COMMENT ON TABLE public.contractors IS 'بيانات مقاولي الباطن والورش والخدمات الخارجية (دهانات، ليزر، سي ان سي، خراطة)';
COMMENT ON COLUMN public.contractors.name IS 'اسم المقاول أو الورشة الخارجية';
COMMENT ON COLUMN public.contractors.service_type IS 'تخصص الورشة (دهانات، CNC، تقطيع ليزر، زجاج...)';
COMMENT ON COLUMN public.contractors.phone IS 'رقم هاتف الورشة للتواصل والمتابعة';

COMMENT ON TABLE public.contractor_payments IS 'سجل المدفوعات والدفعات المحولة للورش ومقاولي الباطن';
COMMENT ON COLUMN public.contractor_payments.contractor_id IS 'معرف الورشة أو المقاول المستلم';
COMMENT ON COLUMN public.contractor_payments.description IS 'بيان تفاصيل الشغل المنفذ (مثل دهان غرفة نوم مط)';
COMMENT ON COLUMN public.contractor_payments.amount IS 'قيمة الدفعة المسددة بالجنيه';
COMMENT ON COLUMN public.contractor_payments.payment_date IS 'تاريخ سداد الدفعة';

-- ── 4. وحدة العملاء والطلبيات (Customers & Orders) ───────────────
COMMENT ON TABLE public.customer_orders IS 'طلبيات وعقود العملاء وتفاصيل الأثاث المطلوب مع مواعيد التسليم والأقسام';
COMMENT ON COLUMN public.customer_orders.customer_name IS 'اسم العميل بالكامل أو اسم المعرض';
COMMENT ON COLUMN public.customer_orders.phone IS 'رقم هاتف العميل للتواصل والواتساب';
COMMENT ON COLUMN public.customer_orders.order_description IS 'الوصف العام للطلبية والبنود المتفق عليها';
COMMENT ON COLUMN public.customer_orders.start_date IS 'تاريخ التعاقد وبدء الطلب';
COMMENT ON COLUMN public.customer_orders.delivery_date IS 'موعد التسليم النهائي المتفق عليه';
COMMENT ON COLUMN public.customer_orders.total_amount IS 'إجمالي قيمة الاتفاق للطلبية بالكامل';
COMMENT ON COLUMN public.customer_orders.status IS 'مرحلة التنفيذ: قيد التنفيذ (in_progress)، جاهز (ready)، تم التسليم (delivered)، ملغي (cancelled)';
COMMENT ON COLUMN public.customer_orders.notes IS 'المواصفات التفصيلية والأقسام وبيانات الصور بتنسيق JSON';

COMMENT ON TABLE public.order_payments IS 'سجل دفعات وعرابين العملاء الخاصة بطلبيات التصنيع';
COMMENT ON COLUMN public.order_payments.order_id IS 'معرف طلبية العميل التابع لها هذا القسط';
COMMENT ON COLUMN public.order_payments.amount IS 'قيمة الدفعة أو العربون المسدد بالجنيه';
COMMENT ON COLUMN public.order_payments.payment_date IS 'تاريخ تحصيل الدفعة';
COMMENT ON COLUMN public.order_payments.payment_method IS 'طريقة السداد (نقدي، إنستاباي، فودافون كاش، تحويل بنكي، شيك)';

-- ── 5. وحدة المخازن والخامات (Inventory) ─────────────────────────
COMMENT ON TABLE public.inventory_items IS 'رصيد الخامات والأخشاب والإكسسوارات في مخزن المصنع';
COMMENT ON COLUMN public.inventory_items.material_name IS 'اسم الخامة أو اللوح (خشب زان، أبلكاش، قماش، دهانات...)';
COMMENT ON COLUMN public.inventory_items.category IS 'تصنيف الخامة (أخشاب، إكسسوارات، أقمشة)';
COMMENT ON COLUMN public.inventory_items.unit IS 'وحدة القياس (لوح، متر، قطعة، كجم، علبة)';
COMMENT ON COLUMN public.inventory_items.current_stock IS 'الرصيد الفعلي المتوفر حالياً في المخزن';
COMMENT ON COLUMN public.inventory_items.reserved_stock IS 'الكميات المحجوزة لأوامر تصنيع قيد التنفيذ في الورشة';
COMMENT ON COLUMN public.inventory_items.minimum_stock_level IS 'حد الطلب الأدنى للتنبيه عند نقص الخامة';
COMMENT ON COLUMN public.inventory_items.unit_cost IS 'متوسط تكلفة شراء الوحدة بالجنيه';

COMMENT ON TABLE public.inventory_movements IS 'حركات المخزن: وارد، منصرف تشغيل، مرتجع، تسوية جرد';
COMMENT ON COLUMN public.inventory_movements.inventory_item_id IS 'معرف صنف المخزن';
COMMENT ON COLUMN public.inventory_movements.movement_type IS 'نوع حركة المخزن: وارد (receipt)، منصرف (issue)، تسوية (adjustment)، مرتجع (return)';
COMMENT ON COLUMN public.inventory_movements.quantity IS 'الكمية المنصرفة أو المضافة';

COMMENT ON TABLE public.inventory_reservations IS 'حجوزات الخامات المخصصة لأوامر التصنيع';
COMMENT ON COLUMN public.inventory_reservations.manufacturing_order_id IS 'معرف أمر التصنيع المحجوز له الخامات';
COMMENT ON COLUMN public.inventory_reservations.inventory_item_id IS 'معرف خامة المخزن';
COMMENT ON COLUMN public.inventory_reservations.reserved_quantity IS 'الكمية المحجوزة للقطعة';
COMMENT ON COLUMN public.inventory_reservations.status IS 'حالة الحجز: محجوز ساري (active)، تم الاستهلاك (consumed)، تم فك الحجز (released)';

COMMENT ON TABLE public.material_shortages IS 'قائمة النواقص واحتياجات الخامات العاجلة المطلوب شراؤها';
COMMENT ON COLUMN public.material_shortages.material_name IS 'اسم الخامة الناقصة المطلوب شراؤها عاجلاً';
COMMENT ON COLUMN public.material_shortages.quantity IS 'الكمية المطلوبة';
COMMENT ON COLUMN public.material_shortages.status IS 'حالة النقص: عجز مطلوب (shortage)، جاري الشراء (in_progress)، تم التوريد (resolved)';

-- ── 6. وحدة أوامر التصنيع والتشغيل (Manufacturing) ───────────────
COMMENT ON TABLE public.manufacturing_orders IS 'أوامر تشغيل وتصنيع الموبيليا في خط الإنتاج داخل الورشة';
COMMENT ON COLUMN public.manufacturing_orders.order_number IS 'رقم أمر التشغيل المطبوع بالورشة (مثل MO-2026-001)';
COMMENT ON COLUMN public.manufacturing_orders.product_name IS 'اسم القطعة المطلوبة (غرفة نوم، دولاب، سفرة...)';
COMMENT ON COLUMN public.manufacturing_orders.product_category IS 'تصنيف القطعة (أثاث خشبي، تنجيد وصالون، مطابخ)';
COMMENT ON COLUMN public.manufacturing_orders.quantity IS 'عدد القطع المطلوب تصنيعها';
COMMENT ON COLUMN public.manufacturing_orders.status IS 'مرحلة أمر التشغيل (جديد، انتظار خامات، جاهز للتجميع، جاري العمل، مكتمل، ملغي)';
COMMENT ON COLUMN public.manufacturing_orders.assigned_worker_id IS 'معرف الفني أو الأسطى المسؤول عن التنفيذ';

COMMENT ON TABLE public.manufacturing_order_dimensions IS 'المقاسات التفصيلية للقطع (الطول، العرض، الارتفاع، العدد)';
COMMENT ON COLUMN public.manufacturing_order_dimensions.height IS 'ارتفاع القطعة';
COMMENT ON COLUMN public.manufacturing_order_dimensions.width IS 'عرض القطعة';
COMMENT ON COLUMN public.manufacturing_order_dimensions.depth IS 'عمق أو تخانة القطعة';
COMMENT ON COLUMN public.manufacturing_order_dimensions.unit IS 'وحدة القياس الهندسية (سم)';

COMMENT ON TABLE public.manufacturing_order_materials IS 'الخامات المحددة المطلوب استهلاكها لتصنيع القطعة (BOM)';
COMMENT ON COLUMN public.manufacturing_order_materials.material_name IS 'اسم الخامة المقررة لتصنيع القطعة';
COMMENT ON COLUMN public.manufacturing_order_materials.required_quantity IS 'الكمية المحددة للقطعة';
COMMENT ON COLUMN public.manufacturing_order_materials.unit IS 'وحدة القياس';

COMMENT ON TABLE public.manufacturing_checklist IS 'قائمة مراحل الجودة والمتابعة وجاهزية الخامات';
COMMENT ON COLUMN public.manufacturing_checklist.material_name IS 'اسم الخامة المطلوب التأكد من جاهزيتها';
COMMENT ON COLUMN public.manufacturing_checklist.is_prepared IS 'هل جاهزة لبدء الشغل في الورشة';

-- ── 7. وحدة الأمان والنسخ الاحتياطي (Auth & System) ──────────────
COMMENT ON TABLE public.profiles IS 'ملفات مستخدمي النظام وتحديد دور المالك أو المدير وصلاحيات الوصول';
COMMENT ON COLUMN public.profiles.full_name IS 'اسم المستخدم بالكامل';
COMMENT ON COLUMN public.profiles.role IS 'دور المستخدم: owner (مالك المصنع)، manager (مدير المصنع)';
COMMENT ON COLUMN public.profiles.is_active IS 'هل الحساب مفعل ونشط ومصرح له بالدخول';

COMMENT ON TABLE public.audit_logs IS 'سجل العمليات والرقابة لتتبع أي إدخال أو تعديل في النظام';
COMMENT ON COLUMN public.audit_logs.user_name IS 'اسم المستخدم الذي قام بالحركة';
COMMENT ON COLUMN public.audit_logs.action IS 'نوع الإجراء المنفذ (دخول، إضافة، تعديل، حذف)';
COMMENT ON COLUMN public.audit_logs.entity_table IS 'اسم الجدول المتأثر بالعملية';
COMMENT ON COLUMN public.audit_logs.details IS 'تفاصيل التغيير بتنسيق JSON';

COMMENT ON TABLE public.backup_records IS 'سجلات النسخ الاحتياطي السحابي والمحلي مع البصمات المشفرة وحالة الاستعادة';
COMMENT ON TABLE public.sync_queue IS 'طابور المزامنة دون اتصال للعمليات المعلقة المطلوب مزامنتها مع السحابة';

-- رسالة تأكيد التنفيذ
SELECT 'تم توثيق وتعريب جداول وأعمدة قاعدة البيانات باللغة العربية بنجاح تام داخل Supabase Dashboard!' AS status;
