# تقرير الفحص والتدقيق الشامل للمشروع (STARS HOMES ERP Project Audit Report)
**تاريخ الفحص:** 2026-11-09  
**المشروع:** STARS HOMES ERP — مصنع ستارز هومز للموبيليا والأخشاب  
**المستودع (GitHub):** https://github.com/mohaned-ashraf1/StarsHome  
**الفرع النشط:** `main`  
**أحدث Commit محلي وسحابي:** `833f092` (*feat: two-way deletion sync, responsive order layout, sections with photos in PDF, and data reset*)  

---

## 1. الملخص التنفيذي ومقارنة المستودع المحلي بالسحابي (Local vs Remote Assessment)

- **حالة المستودع:** المستودع المحلي على الفرع `main` متطابق بنسبة 100% مع أحدث نسخة على مستودع GitHub السحابي (`origin/main`). لا توجد أي تعديلات معلقة أو غير مرفوعة قبل البدء.
- **إصدار التطبيق الحالي:** `1.0.12+13` (وفقاً لـ `pubspec.yaml`).
- **سلامة الكود (Code Integrity):** تم اجتياز الفحص البرمجي الكامل بنجاح:
  - `flutter analyze --no-pub`: **No issues found** (0 أخطاء، 0 تحذيرات).
  - `flutter test`: **103 اختبارات ناجحة بنسبة 100%** تغطي دورة التصنيع، المخازن، الأمان، وإدارة الجلسات.
- **نسخ البناء الحالية المتوفرة:**
  - تم بناء وتجميع ملف الأندرويد التنفيذي: `build/app/outputs/flutter-apk/app-release.apk` (الحجم: 77.6 ميجابايت).
  - تم تجربة وتجميع نسخة الويب: `build/web`.

---

## 2. جرد الملفات والمكونات البرمجية (File & Component Inventory)

### أ. ملفات ومجلدات تطبيق فلاتر (Flutter Application Components)
- **`lib/`**: تحتوي على نواة التطبيق مقسمة إلى طبقتين:
  - **`lib/backend/`**:
    - **النماذج (Models - 22 نموذجاً):** `worker_model.dart`، `attendance_model.dart`، `payroll_settlement_model.dart`، `worker_financial_item_model.dart`، `purchase_model.dart`، `income_model.dart`، `contractor_model.dart`، `contractor_payment_model.dart`، `customer_order_model.dart` (مع نظام الأقسام والصور المرفقة `OrderSectionItem`)، `order_payment_model.dart`، `debt_advance_model.dart`، `debt_advance_payment_model.dart`، `inventory_item_model.dart`، `inventory_movement_model.dart`، `inventory_reservation_model.dart`، `manufacturing_order_model.dart`، `manufacturing_dimension_model.dart`، `manufacturing_material_model.dart`، `manufacturing_checklist_item_model.dart`، `material_shortage_model.dart`، `furniture_section_model.dart`، `user_profile.dart`.
    - **مقدمو البيانات وإدارة الحالة (Providers - 9 موفرين):** `workers_provider.dart`، `accounts_provider.dart`، `contractors_provider.dart`، `customers_provider.dart`، `inventory_provider.dart`، `manufacturing_provider.dart`، `shortages_provider.dart`، `dashboard_provider.dart`، `auth_provider.dart`.
    - **الخدمات (Services - 8 خدمات رئيسية):** `db_service.dart` (قاعدة SQLite المحلية)، `sync_service.dart` (محرك المزامنة السحابية والحذف المتبادل)، `auth_service.dart` (إدارة الرمز السري المحلي PIN)، `supabase_auth_service.dart` (جلسات وتفويض السحابة)، `inventory_service.dart`، `manufacturing_service.dart`، `manufacturing_pdf_service.dart`، `whatsapp_service.dart`.
    - **الأدوات والمساعدات (Utils):** `currency_formatter.dart`، `customer_receipt_helper.dart` (توليد وطباعة إيصالات العملاء مع الصور الملحقة)، `date_helper.dart`، `export_helper.dart` (تصدير CSV).
  - **`lib/frontend/`**:
    - شاشات وواجهات المستخدم (Views) موزعة حسب الموديولات: `accounts/`، `auth/`، `contractors/`، `customers/`، `dashboard/`، `home/`، `inventory/`، `manufacturing/`، `settings/`، `shortages/`، `splash/`، `sync/`.
    - عناصر واجهة مشتركة (Widgets): `sync_status_badge.dart`، `user_role_badge.dart`.
- **`assets/`**: شعارات التطبيق (`logo.png`، `logo_transparent.png`) وأيقونات الواجهة.
- **مجلدات المنصات (Platform Folders):** `android/`، `windows/`، `web/`، `ios/`، `linux/`، `macos/`.
- **`test/`**: ملفات الاختبارات المتكاملة (`manufacturing_and_inventory_test.dart`، `security_and_stability_test.dart`، `shortages_and_multisection_orders_test.dart`، `widget_test.dart`).

### ب. ملفات قاعدة البيانات والسحابة (Backend & Database)
- **`backend/database/`**:
  - `00_master_schema_init.sql`: سكريبت التأسيس الشامل لقاعدة البيانات الموحدة.
  - `migrations/`: 11 ملف هجرة (Migrations من 01 إلى 11) ترتب إنشاء الجداول، الصلاحيات، RLS، بيانات البداية، والمخازن.
- **`database/`**: نسخة مكررة بالكامل مطابقة بنسبة 100% لمجلد `backend/database/`.

---

## 3. تحديد الملفات المكررة وغير الضرورية والمؤقتة (Duplicates & Unnecessary Files)

1. **مجلد `database/` مكرر تماماً:** مجلد `database/` ومجلد `backend/database/` يحملان نفس الملفات والتجزئة التشفيرية (Hashes). يجب حذف المجلد القديم `database/` والإبقاء على الهيكل داخل `backend/database/`.
2. **ملفات IDE ومخلفات البناء المؤقتة:**
   - ملف المشروع القديم `stars_home.iml`.
   - مجلد `.idea/` غير الضروري للمستودع.
   - مجلد `build/` (سيتم حذفه من التتبع وتركه في `.gitignore`).
   - مجلد `.dart_tool/` (مخلفات محلية يتم توليدها تلقائياً).
3. **ملفات البيئة:**
   - `.env` محلي غير متبع في git (محمي بـ `.gitignore`).
   - `.env.example` موثق بدون أسرار.

---

## 4. فحص المعمارية ونظام المزامنة والأمان (Architecture, Sync & Security Review)

### أ. قاعدة البيانات المحلية (Local SQLite - `db_service.dart`)
- إصدار قاعدة البيانات المحلية: `v8`.
- تتضمن 23 جدولاً تشغيلياً بالإضافة لجدول طابور المزامنة `sync_queue`.
- كل جدول يحتوي على عمود `device_id` و `created_at` و `updated_at` لضمان التوافق مع السحابة.
- مزودة بوظيفة `clearAllOperationalData()` المحدثة لتصفير البيانات التشغيلية مع الحفاظ على التصنيفات والاقتراحات.

### ب. محرك المزامنة (Cloud Sync - `sync_service.dart`)
- يدعم استراتيجية **Offline-First**: السجلات تُحفظ محلياً أولاً في SQLite وتُضاف لطابور `sync_queue`.
- عند توفر الإنترنت، يتم الدفع بنظام Upsert لتفادي التكرار.
- **السحب والتوافق (Reconciliation):** تم تحديث `_pullRemoteTablePaginated` ليقارن المعرفات ويحذف محلياً أي سجل تم مسحه من السحابة.
- تم ضبط ترتيب المزامنة لتفادي أخطاء المفاتيح الأجنبية (Foreign Keys) كإنشاء العمال والمقاولين والطلبات قبل المدفوعات وتفاصيل التصنيع.

### ج. الأمان والصلاحيات (Authentication & Roles)
- **الأدوار:** المالك (`owner`) له كافة الصلاحيات، المدير (`manager`) له صلاحيات تشغيلية محددة.
- يتم تخزين الجلسات المشفرة باستخدام `FlutterSecureStorage` (AES-GCM على أندرويد و DPAPI على ويندوز).
- لا يتم تضمين `service_role` السري في كود التطبيق، بل يتم استخدام `anon key` العام مع قيود RLS على السيرفر.

---

## 5. تحليل ملفات الهجرة (SQL Migrations Analysis)

| رقم الهجرة | اسم الملف | الوصف والغرض | حالة التوافق |
|:---:|:---|:---|:---:|
| 01 | `01_initial_schema.sql` | الجداول الأساسية (المصاريف، العمال، المقاولين، الحضور) | متوافق |
| 02 | `02_rls_and_security.sql` | تمكين RLS الأولي وسياسات القراءة العامة | متوافق |
| 03 | `03_seed_data.sql` | التصنيفات والمقاولين الافتراضيين واقتراحات الخامات | متوافق |
| 04 | `04_customers_and_orders.sql` | جداول العملاء، الطلبات، والدفعات | متوافق |
| 05 | `05_manufacturing_and_inventory.sql` | أوامر التصنيع، المقاسات، الخامات، الحجوزات | متوافق |
| 06 | `06_shortages_and_order_sections.sql` | النواقص، أقسام الأثاث، والمقاسات التفصيلية | متوافق |
| 07 | `07_schema_reconciliation.sql` | توحيد أعمدة الربط والتوافق بين الجداول | متوافق |
| 08 | `08_rls_secure_policies.sql` | سياسات الأمان المتقدمة وفرز المالك والمدير | **يُطبق بعد استقرار وتأكيد تسجيل الدخول** |
| 09 | `09_supabase_auth_setup.sql` | ربط جداول البروفايل مع مستخدمي `auth.users` | متوافق |
| 10 | `10_inventory_and_shortages_setup.sql` | جداول المخزن والحركات والنواقص | متوافق |
| 11 | `11_fix_all_permissions_and_sync.sql` | تحرير الصلاحيات ومنح أذونات المزامنة لكافة الأجهزة | متوافق ويعمل حالياً |

---

## 6. خطة إعادة الهيكلة والتنفيذ المعتمدة (Restructuring Execution Plan)

1. **إنشاء مجلد `frontend/`**:
   - نقل كافة ملفات تطبيق فلاتر (`lib/`، `assets/`، `android/`، `windows/`، `web/`، `ios/`، `linux/`، `macos/`، `test/`، `pubspec.yaml`، `pubspec.lock`، `analysis_options.yaml`).
2. **إنشاء مجلد `backend/` منظم**:
   - إبقاء وتوثيق ملفات الهجرة والتأسيس ومجلد `docs/`.
   - حذف المجلد المكرر `database/`.
3. **إنشاء مجلد `server/`**:
   - وضع التوثيق الكامل وتوصيف بنية الربط ومعالجة الـ Webhooks / Background Jobs لعدم الحاجة لسيرفر Node.js إضافي مع الحفاظ على استقلالية المجلد.
4. **تحديث إعدادات البناء والمستودع والجذور**:
   - تحديث `.gitignore`.
   - إنشاء سكريبتات البناء من المجلد الرئيسي.
   - إعداد GitHub Actions لبناء نسخة الويندوز والأندرويد تلقائياً.
   - إنشاء سكريبت مثبت الويندوز Inno Setup (`STARS_HOMES_ERP_Setup.exe`).

---
**الخلاصة:** المشروع جاهز تماماً للانتقال إلى المرحلة الثانية لإعادة الهيكلة المنظمة دون أي فقدان للوظائف.

