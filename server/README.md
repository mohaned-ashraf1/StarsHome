# STARS HOMES ERP — Server Components Architecture

## نظرة عامة (Overview)
يعتمد نظام **STARS HOMES ERP** على بنية سحابية هجينة وخفيفة (Cloud Serverless Architecture) تعتمد بشكل رئيسي على **Supabase PostgreSQL** كوحدة معالجة مركزية آمنة (Database-driven backend). يضمن هذا التصميم:
1. عدم الحاجة إلى تشغيل خادم وسيط (Middle-tier server) دائم، مما يقلل تكلفة الاستضافة والصيانة بنسبة 100%.
2. سرعة استجابة فائقة واتصال مباشر آمن عبر بروتوكولات REST و WebSocket (Realtime Sync) مشفرة بمفاتيح JWT و RLS.

---

## المكونات المستقلة داخل مجلد الخادم (`/server`)

### 1. الوظائف السحابية والمهام الدورية (`/server/cron_jobs`)
- **`order_delivery_reminders.sql`**: وظيفة مجدولة تفحص مواعيد تسليم الطلبات يومياً وتنبه المدير والمالك قبل موعد التسليم بأسبوع (7 أيام).
- **`inventory_stock_watchdog.sql`**: وظيفة تدقيق ومطابقة أرصدة الخامات مع الحجوزات لتحديث النواقص آلياً.

### 2. دوال الحافة السحابية (`/server/edge_functions`)
- **`whatsapp_notifications/`**: دالة Deno/TypeScript سحابية معدة للربط مع بوابات الواتساب الرسمية (مثل Twilio أو WhatsApp Cloud API) لإرسال إشعارات التذكير وتحديثات الطلبات للعملاء.

### 3. مستقبلات الأحداث الخارجية (`/server/webhooks`)
- **`webhook_receiver.json`**: مخطط استقبال وتوجيه الأحداث الخارجية (Webhooks) من بوابات الدفع الإلكتروني أو أجهزة البصمة إلى جداول الحضور والمشتريات مباشرة.
