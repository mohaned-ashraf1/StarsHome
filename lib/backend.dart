// =============================================================================
// STARS HOMES ERP — BACKEND LAYER (طبقة البيانات والخدمات والمزامنة)
// =============================================================================
// هذا الملف يجمع ويفصل كافة مكونات الباك إند (Backend) لتسهيل استيرادها والوصول إليها:
// 1. Core Services (قواعد البيانات، المزامنة، المصادقة، خدمة الواتساب)
// 2. Data Models (نماذج البيانات والكيانات)
// 3. Helpers & Utilities (أدوات الحسابات، تحويل العملات، إنشاء مستندات PDF)
// =============================================================================

// ── 1. Services (خدمات قواعد البيانات والاتصال) ──────────────────────────────
export 'core/services/db_service.dart';            // قاعدة بيانات SQLite المحلية
export 'core/services/sync_service.dart';          // خدمة المزامنة السحابية مع Supabase
export 'core/services/auth_service.dart';          // خدمة المصادقة المحلية والرموز السرية
export 'core/services/supabase_auth_service.dart'; // خدمة تفويض الأجهزة عبر Supabase Auth
export 'core/services/whatsapp_service.dart';       // خدمة الربط بواتساب ومشاركة الفواتير

// ── 2. Data Models (نماذج البيانات والكائنات) ────────────────────────────────
export 'models/user_profile.dart';                 // بيانات المستخدم وصلاحياته
export 'models/customer_order_model.dart';         // بيانات طلبات العملاء
export 'models/order_payment_model.dart';          // دفعات وعرابين الطلبيات
export 'models/worker_model.dart';                 // بيانات العمال والفنيين
export 'models/attendance_model.dart';             // سجلات حضور وانصراف العمال
export 'models/worker_financial_item_model.dart';  // سلف ومكافآت وخصومات العمال
export 'models/payroll_settlement_model.dart';          // تسويات الرواتب الأسبوعية والشهرية
export 'models/contractor_model.dart';             // بيانات مقاولي الباطن والورش
export 'models/contractor_payment_model.dart';     // دفعات مقاولي الباطن
export 'models/purchase_model.dart';               // المشتريات والمصروفات
export 'models/income_model.dart';                 // الإيرادات والمقبوضات
export 'models/debt_advance_model.dart';           // السلف والديون الخارجية
export 'models/debt_advance_payment_model.dart';   // سداد الديون والسلف
export 'models/inventory_item_model.dart';         // أصناف وخامات المخزن
export 'models/inventory_movement_model.dart';     // حركات الإضافة والصرف من المخزن
export 'models/manufacturing_order_model.dart';    // أوامر التصنيع وبطاقات الورشة
export 'models/material_shortage_model.dart';      // النواقص والمواد المطلوبة

// ── 3. Utilities & Helpers (الأدوات المساعدة) ───────────────────────────────
export 'core/utils/currency_formatter.dart';       // تنسيق المبالغ والعملة (ج.م)
export 'core/utils/date_helper.dart';              // معالجة وتنسيق التواريخ الهجرية والميلادية
export 'core/utils/customer_receipt_helper.dart';  // توليد فواتير وإيصالات العملاء PDF

