// =============================================================================
// STARS HOMES ERP — FRONTEND LAYER (طبقة واجهات المستخدم والتصميم)
// =============================================================================
// هذا الملف يجمع ويفصل كافة مكونات الفرونت إند (Frontend) لتسهيل استيرادها والوصول إليها:
// 1. Screens & Views (شاشات التطبيق)
// 2. Constants & Theme (الألوان، الخطوط، الثيم الليلي والنهاري)
// 3. Reusable UI Widgets (العناصر المشتركة والبطاقات)
// =============================================================================

// ── 1. Design & Theme (الثيم والألوان) ───────────────────────────────────────
export 'package:stars_home/frontend/constants/app_colors.dart';           // لوحة ألوان التطبيق (الكحلي، الذهبي، الأخضر، الأحمر)
export 'package:stars_home/frontend/constants/app_strings.dart';          // النصوص والعناوين الثابتة
export 'package:stars_home/frontend/constants/app_theme.dart';            // الثيم العام وتنسيقات Material 3

// ── 2. Views & Screens (شاشات التطبيق) ───────────────────────────────────────
export 'package:stars_home/frontend/views/splash/splash_screen.dart';          // شاشة البداية المتحركة
export 'package:stars_home/frontend/views/auth/login_screen.dart';             // شاشة تسجيل الدخول والـ PIN
export 'package:stars_home/frontend/views/auth/device_authorization_screen.dart'; // شاشة ربط وتفويض الجهاز
export 'package:stars_home/frontend/views/home/home_screen.dart';              // الشاشة الرئيسية وملاحة الأقسام
export 'package:stars_home/frontend/views/dashboard/dashboard_screen.dart';    // لوحة المؤشرات والإحصائيات
export 'package:stars_home/frontend/views/customers/customers_screen.dart';    // شاشة العملاء والطلبيات
export 'package:stars_home/frontend/views/customers/order_detail_screen.dart'; // تفاصيل الطلب والفواتير
export 'package:stars_home/frontend/views/accounts/accounts_screen.dart';      // شاشة الحسابات والمصروفات والإيرادات
export 'package:stars_home/frontend/views/workers/workers_screen.dart';        // شاشة إدارة العمال والرواتب والحضور
export 'package:stars_home/frontend/views/contractors/contractors_screen.dart';// شاشة مقاولي الباطن والورش
export 'package:stars_home/frontend/views/inventory/inventory_screen.dart';    // شاشة المخزن وحركات الخامات
export 'package:stars_home/frontend/views/manufacturing/manufacturing_orders_screen.dart'; // شاشة أوامر التصنيع
export 'package:stars_home/frontend/views/manufacturing/create_manufacturing_order_screen.dart'; // إنشاء أمر تصنيع جديد

// ── 3. Shared Widgets (العناصر الرسومية المشتركة) ───────────────────────────
export 'package:stars_home/frontend/widgets/sync_status_badge.dart';           // شارة حالة المزامنة والاتصال السحابي

