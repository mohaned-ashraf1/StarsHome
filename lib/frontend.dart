// =============================================================================
// STARS HOMES ERP — FRONTEND LAYER (طبقة واجهات المستخدم والتصميم)
// =============================================================================
// هذا الملف يجمع ويفصل كافة مكونات الفرونت إند (Frontend) لتسهيل استيرادها والوصول إليها:
// 1. Screens & Views (شاشات التطبيق)
// 2. Constants & Theme (الألوان، الخطوط، الثيم الليلي والنهاري)
// 3. Reusable UI Widgets (العناصر المشتركة والبطاقات)
// =============================================================================

// ── 1. Design & Theme (الثيم والألوان) ───────────────────────────────────────
export 'core/constants/app_colors.dart';           // لوحة ألوان التطبيق (الكحلي، الذهبي، الأخضر، الأحمر)
export 'core/constants/app_strings.dart';          // النصوص والعناوين الثابتة
export 'core/constants/app_theme.dart';            // الثيم العام وتنسيقات Material 3

// ── 2. Views & Screens (شاشات التطبيق) ───────────────────────────────────────
export 'views/splash/splash_screen.dart';          // شاشة البداية المتحركة
export 'views/auth/login_screen.dart';             // شاشة تسجيل الدخول والـ PIN
export 'views/auth/device_authorization_screen.dart'; // شاشة ربط وتفويض الجهاز
export 'views/home/home_screen.dart';              // الشاشة الرئيسية وملاحة الأقسام
export 'views/dashboard/dashboard_screen.dart';    // لوحة المؤشرات والإحصائيات
export 'views/customers/customers_screen.dart';    // شاشة العملاء والطلبيات
export 'views/customers/order_detail_screen.dart'; // تفاصيل الطلب والفواتير
export 'views/accounts/accounts_screen.dart';      // شاشة الحسابات والمصروفات والإيرادات
export 'views/workers/workers_screen.dart';        // شاشة إدارة العمال والرواتب والحضور
export 'views/contractors/contractors_screen.dart';// شاشة مقاولي الباطن والورش
export 'views/inventory/inventory_screen.dart';    // شاشة المخزن وحركات الخامات
export 'views/manufacturing/manufacturing_orders_screen.dart'; // شاشة أوامر التصنيع
export 'views/manufacturing/create_manufacturing_order_screen.dart'; // إنشاء أمر تصنيع جديد

// ── 3. Shared Widgets (العناصر الرسومية المشتركة) ───────────────────────────
export 'widgets/sync_status_badge.dart';           // شارة حالة المزامنة والاتصال السحابي

