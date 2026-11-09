// =============================================================================
// STARS HOMES ERP — BACKEND LAYER (طبقة البيانات والخدمات والمزامنة)
// =============================================================================
// هذا الملف يجمع ويفصل كافة مكونات الباك إند (Backend) لتسهيل استيرادها والوصول إليها:
// 1. Core Services (قواعد البيانات، المزامنة، المصادقة، خدمة الواتساب)
// 2. Data Models (نماذج البيانات والكيانات)
// 3. Helpers & Utilities (أدوات الحسابات، تحويل العملات، إنشاء مستندات PDF)
// =============================================================================

// ── 1. Services (خدمات قواعد البيانات والاتصال) ──────────────────────────────
export 'package:stars_home/backend/services/db_service.dart';            // قاعدة بيانات SQLite المحلية
export 'package:stars_home/backend/services/sync_service.dart';          // خدمة المزامنة السحابية مع Supabase
export 'package:stars_home/backend/services/auth_service.dart';          // خدمة المصادقة المحلية والرموز السرية
export 'package:stars_home/backend/services/supabase_auth_service.dart'; // خدمة تفويض الأجهزة عبر Supabase Auth
export 'package:stars_home/backend/services/whatsapp_service.dart';       // خدمة الربط بواتساب ومشاركة الفواتير

// ── 2. Data Models (نماذج البيانات والكائنات) ────────────────────────────────
export 'package:stars_home/backend/models/user_profile.dart';                 // بيانات المستخدم وصلاحياته
export 'package:stars_home/backend/models/customer_order_model.dart';         // بيانات طلبات العملاء
export 'package:stars_home/backend/models/order_payment_model.dart';          // دفعات وعرابين الطلبيات
export 'package:stars_home/backend/models/worker_model.dart';                 // بيانات العمال والفنيين
export 'package:stars_home/backend/models/attendance_model.dart';             // سجلات حضور وانصراف العمال
export 'package:stars_home/backend/models/worker_financial_item_model.dart';  // سلف ومكافآت وخصومات العمال
export 'package:stars_home/backend/models/payroll_settlement_model.dart';          // تسويات الرواتب الأسبوعية والشهرية
export 'package:stars_home/backend/models/contractor_model.dart';             // بيانات مقاولي الباطن والورش
export 'package:stars_home/backend/models/contractor_payment_model.dart';     // دفعات مقاولي الباطن
export 'package:stars_home/backend/models/purchase_model.dart';               // المشتريات والمصروفات
export 'package:stars_home/backend/models/income_model.dart';                 // الإيرادات والمقبوضات
export 'package:stars_home/backend/models/debt_advance_model.dart';           // السلف والديون الخارجية
export 'package:stars_home/backend/models/debt_advance_payment_model.dart';   // سداد الديون والسلف
export 'package:stars_home/backend/models/inventory_item_model.dart';         // أصناف وخامات المخزن
export 'package:stars_home/backend/models/inventory_movement_model.dart';     // حركات الإضافة والصرف من المخزن
export 'package:stars_home/backend/models/manufacturing_order_model.dart';    // أوامر التصنيع وبطاقات الورشة
export 'package:stars_home/backend/models/material_shortage_model.dart';      // النواقص والمواد المطلوبة

// ── 3. Utilities & Helpers (الأدوات المساعدة) ───────────────────────────────
export 'package:stars_home/backend/utils/currency_formatter.dart';       // تنسيق المبالغ والعملة (ج.م)
export 'package:stars_home/backend/utils/date_helper.dart';              // معالجة وتنسيق التواريخ الهجرية والميلادية
export 'package:stars_home/backend/utils/customer_receipt_helper.dart';  // توليد فواتير وإيصالات العملاء PDF

