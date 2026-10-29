# STARS HOMES — نظام إدارة مصنع الأثاث

> نظام ERP متكامل لإدارة مصنع **ستارز هومز للأثاث والمصنوعات الخشبية** — يعمل بشكل كامل بدون إنترنت مع مزامنة سحابية اختيارية عبر Supabase.

---

## الميزات الرئيسية

| القسم | الوصف |
|---|---|
| **الحسابات** | تسجيل المشتريات والمصروفات والدواخل والديون والسلف |
| **العمال** | الحضور والانصراف، السلف والمكافآت، تسوية الرواتب الأسبوعية |
| **الاشتراكات** | الورش الخارجية (دهان، قشرة، تنجيد، خراطة) وحساباتهم |
| **العملاء** | طلبيات الأثاث المخصص، الأقساط، إيصالات القبض |
| **التصنيع** | أوامر تصنيع وبطاقات ورشة مع مقاسات وخامات وقوالب جاهزة |
| **المخزون** | إدارة الخامات وحركات المستودع والتحفظات |
| **النواقص** | متابعة وتسجيل الخامات الناقصة مع درجة الإلحاح |
| **لوحة التحكم** | مؤشرات مالية ورسوم بيانية تفاعلية |

---

## هيكل المشروع

```
lib/
├── main.dart                          # نقطة الدخول — MultiProvider setup (9 providers)
├── core/
│   ├── constants/
│   │   ├── app_colors.dart            # لوحة الألوان (Dark Forest Green + Gold)
│   │   ├── app_strings.dart           # النصوص العربية
│   │   └── app_theme.dart             # ThemeData الداكن
│   ├── services/
│   │   ├── auth_service.dart          # مصادقة PIN — PBKDF2-SHA256 + lockout
│   │   ├── db_service.dart            # SQLite — إصدار v7 مع migrations منظمة
│   │   ├── sync_service.dart          # مزامنة Supabase — Offline-First + paginated pull
│   │   ├── inventory_service.dart     # إدارة المخزون وحركاته
│   │   ├── manufacturing_service.dart # أوامر التصنيع وبطاقات الورشة
│   │   ├── manufacturing_pdf_service.dart # توليد PDF عربي للورشة
│   │   └── shortages_service.dart     # إدارة النواقص
│   └── utils/
│       ├── currency_formatter.dart    # تنسيق الجنيه المصري
│       ├── date_helper.dart           # فلترة الفترات الزمنية
│       ├── export_helper.dart         # تصدير CSV/Excel
│       ├── furniture_templates.dart   # قوالب الأثاث الجاهزة (5+ أنواع)
│       ├── customer_receipt_helper.dart    # إيصالات العملاء PDF
│       ├── debt_advance_receipt_helper.dart # إيصالات الديون والسلف PDF
│       └── worker_payroll_receipt_helper.dart # كشوف رواتب العمال PDF
├── models/                            # 22 نموذج بيانات (fromMap/toMap)
├── providers/                         # 9 ChangeNotifier providers
│   ├── auth_provider.dart             # AuthState enum — لا login تلقائي
│   ├── accounts_provider.dart         # الحسابات المالية
│   ├── workers_provider.dart          # شؤون العمال
│   ├── contractors_provider.dart      # الورش الخارجية
│   ├── customers_provider.dart        # طلبيات العملاء
│   ├── dashboard_provider.dart        # لوحة التحكم
│   ├── inventory_provider.dart        # المخزون
│   ├── manufacturing_provider.dart    # التصنيع
│   └── shortages_provider.dart        # النواقص
└── views/                             # 12 مجلد شاشات
    ├── auth/login_screen.dart         # شاشة الدخول + إعداد PIN أولي
    ├── splash/splash_screen.dart      # شاشة التحميل
    ├── home/home_screen.dart          # الشاشة الرئيسية
    ├── accounts/                      # شاشات الحسابات (5 ملفات)
    ├── workers/                       # شاشات العمال (6 ملفات)
    ├── contractors/                   # شاشات الورش (3 ملفات)
    ├── customers/                     # شاشات العملاء (4 ملفات)
    ├── manufacturing/                 # شاشات التصنيع (4 ملفات)
    ├── inventory/                     # شاشات المخزون (4 ملفات)
    ├── shortages/                     # شاشات النواقص (2 ملفات)
    ├── dashboard/                     # لوحة التحكم (1 ملف)
    └── settings/                      # الإعدادات
database/
└── migrations/
    ├── 01_initial_schema.sql          # مخطط PostgreSQL الأساسي
    ├── 02_rls_and_security.sql        # سياسات RLS الأصلية
    ├── 03_seed_data.sql               # بيانات أولية تجريبية
    ├── 04_customers_and_orders.sql    # جداول العملاء
    ├── 05_manufacturing_and_inventory.sql # جداول التصنيع والمخزون
    ├── 06_shortages_and_order_sections.sql # جداول النواقص
    ├── 07_schema_reconciliation.sql   # [Issue 4] مزامنة SQLite ↔ PostgreSQL
    └── 08_rls_secure_policies.sql     # [Issue 5] سياسات RLS الآمنة
test/
├── widget_test.dart
├── manufacturing_and_inventory_test.dart
├── shortages_and_multisection_orders_test.dart
└── security_and_stability_test.dart  # [Issues 1-3, 7, 9, 11]
```

---

## المصادقة والأمان (Issue 1 & 2)

### نظام المصادقة
- **PIN-based authentication** — رمز رقمي (4 أرقام على الأقل) لكل دور
- **PBKDF2-SHA256** مع 100,000 تكرار وملح عشوائي 128-bit لكل PIN
- **PIN لا يُخزَّن أبداً بصيغة نص عادي** — تُخزَّن دائماً الصيغة المشفرة فقط
- لا توجد PINات ثابتة مُضمَّنة في الكود (تمت إزالة 1122, 3344, 0000)
- **حد المحاولات:** 5 محاولات فاشلة → قفل لمدة 10 دقائق
- **حالة القفل** تُحفظ في SharedPreferences وتستمر عند إعادة تشغيل التطبيق
- **مهلة الجلسة:** 12 ساعة — يُعاد تسجيل الدخول تلقائياً بعد انتهائها
- **رسائل خطأ عامة** — لا تكشف معلومات عن الحسابات الموجودة

### حالات المصادقة (AuthState)
```dart
enum AuthState {
  loading,         // جاري التحقق من الجلسة المحفوظة
  unauthenticated, // لا توجد جلسة صالحة — عرض شاشة الدخول
  authenticated,   // جلسة نشطة وصالحة
  setupRequired,   // تثبيت جديد — إعداد PIN مطلوب
  error,           // خطأ غير متوقع
}
```

### التثبيت الأول (First Run)
عند أول تشغيل للتطبيق، ستظهر شاشة إعداد رمز الدخول. يجب على:
- **مالك المصنع:** اختيار رمز سري خاص به
- **مدير المصنع:** اختيار رمز سري منفصل

> ⚠️ **لا يوجد رمز افتراضي** — يجب إعداد الرمز قبل استخدام النظام.

### الأدوار والصلاحيات
| الدور | الصلاحيات |
|---|---|
| `owner` (مالك المصنع) | كامل الصلاحيات — قراءة، كتابة، تعديل، حذف، تسوية الحسابات |
| `manager` (مدير المصنع) | قراءة وكتابة — لا يمكن حذف السجلات المالية الأساسية |

### تغيير الرمز السري
من شاشة الإعدادات (Settings):
```
الإعدادات → تغيير رمز الدخول → أدخل الرمز الحالي → أدخل الرمز الجديد
```

---

## قاعدة البيانات المحلية (SQLite)

### نظام الترحيل (Versioned Migrations)
```
v1 — المخطط الأساسي (purchases, incomes, workers, attendance, payroll, contractors, sync_queue)
v2 — customer_orders, order_payments
v3 — debts_advances, debt_advance_payments
v4 — inventory_items, movements, manufacturing_orders, dimensions, materials, checklist, reservations, material_shortages
v5 — أعمدة إضافية للتصنيع (sections_data, thickness_grade, color_code, linked_piece)
v6 — last_error في sync_queue للتشخيص
v7 — supplier_name, minimum_limit في inventory_items؛ تعديلات material_shortages
```

الترقية آمنة ومتراكبة — لا تُفقد البيانات الموجودة.

### الجداول الرئيسية (23 جدول)
```
categories, item_suggestions, purchases, incomes,
workers, worker_attendance, worker_financial_items, worker_payroll_settlements,
contractors, contractor_payments, sync_queue,
customer_orders, order_payments,
debts_advances, debt_advance_payments,
inventory_items, inventory_movements, inventory_reservations,
manufacturing_orders, manufacturing_order_dimensions, manufacturing_order_materials,
manufacturing_checklist, material_shortages
```

---

## إعداد Supabase (اختياري)

### المتطلبات
1. حساب على [supabase.com](https://supabase.com)
2. مشروع جديد (PostgreSQL 15+)
3. تطبيق SQL migrations بالترتيب (انظر `database/migrations/`)

### الإعداد في التطبيق
من شاشة الإعدادات:
```
الإعدادات → Supabase → أدخل URL → أدخل Anon Key → حفظ
```

### المزامنة
- **Offline-First:** التطبيق يعمل كاملاً بدون إنترنت
- **Sync Queue:** جميع التغييرات تُخزَّن في طابور محلي (`sync_queue`)
- **عند الاتصال:** يُرسَل الطابور تلقائياً للسيرفر
- **conflict resolution:** آخر تعديل يفوز (Last-Write-Wins بناءً على `updated_at`)
- **Pagination:** السحب من السيرفر يتم بدفعات 100 سطر تتجاوز حد 200
- **إعادة المحاولة:** حتى 5 مرات لكل عملية قبل وضعها في حالة `failed`

### تطبيق SQL Migrations على Supabase
```bash
# ترتيب التطبيق:
# 1. database/migrations/01_initial_schema.sql
# 2. database/migrations/02_rls_and_security.sql
# 3. database/migrations/03_seed_data.sql
# 4. database/migrations/04_customers_and_orders.sql
# 5. database/migrations/05_manufacturing_and_inventory.sql
# 6. database/migrations/06_shortages_and_order_sections.sql
# 7. database/migrations/07_schema_reconciliation.sql  ← [Issue 4]
# 8. database/migrations/08_rls_secure_policies.sql    ← [Issue 5]
```

---

## المتغيرات البيئية

لا يوجد ملف `.env` مطلوب — الإعدادات تُحفظ في SharedPreferences المشفر على الجهاز.

> ⚠️ **لا تضع `service_role` key أو كلمات السر في كود التطبيق أبداً**

---

## التثبيت والتطوير

### المتطلبات
- Flutter SDK `^3.13.3`
- Dart SDK `^3.13.3`

### تشغيل التطبيق
```bash
# تثبيت الحزم
flutter pub get

# تشغيل على Android/iOS
flutter run

# تشغيل على Windows Desktop
flutter run -d windows

# تحليل الكود
flutter analyze

# تشغيل الاختبارات
flutter test
```

### المنصات المدعومة
- ✅ Android
- ✅ iOS
- ✅ Windows Desktop
- ✅ macOS Desktop
- ✅ Linux Desktop
- ✅ Web (تجريبي)

---

## إجراءات الاختبار

```bash
# اختبارات الأمان والاستقرار
flutter test test/security_and_stability_test.dart --reporter=expanded

# اختبارات التصنيع والمخزون
flutter test test/manufacturing_and_inventory_test.dart

# اختبارات النواقص والطلبيات متعددة الأقسام
flutter test test/shortages_and_multisection_orders_test.dart

# جميع الاختبارات
flutter test
```

---

## القيود المعروفة والمتطلبات للنشر

### قيود حالية
1. **المصادقة محلية فقط:** لا يوجد Supabase Auth — PINs مُدارة محلياً على الجهاز. للأمان العالي، يُوصى بالترقية إلى Supabase Auth مع JWT claims في إصدار مستقبلي.
2. **PIN قصير:** PIN من 4 أرقام له entropy محدود. يُعالَج بـ PBKDF2 و lockout، لكن يوصى باستخدام 6+ أرقام.
3. **اختبار multi-device sync:** يتطلب Supabase credentials — لم يُختبر في هذه الجلسة بيئة live.
4. **Role-based server enforcement:** الأدوار تُطبَّق حالياً على مستوى التطبيق؛ لا JWT claims في Supabase بعد.

### ما يجب تنفيذه يدوياً قبل الإنتاج
- [ ] تطبيق `07_schema_reconciliation.sql` على Supabase
- [ ] تطبيق `08_rls_secure_policies.sql` على Supabase
- [ ] التحقق من أن سياسات RLS تمنع الوصول بدون مصادقة
- [ ] إعداد رمز الدخول (PIN) للمالك والمدير عند أول تشغيل
- [ ] اختبار المزامنة مع أكثر من 200 سجل في بيئة حقيقية
- [ ] اختبار التعديل المتزامن من جهازين مختلفين

---

## تاريخ الإصدارات الأمنية

| الإصدار | التاريخ | التغييرات |
|---|---|---|
| 1.1.0 | 2026-10 | Issue 1-12 Remediation: PBKDF2 hashing, no auto-login, paginated sync, versioned migrations, unsafe cleanup removed |
