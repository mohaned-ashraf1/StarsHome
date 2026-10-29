# 🏛️ STARS HOMES ERP — هندسة وهيكل المشروع (Architecture Overview)

هذا المستند يوضح الهيكلية المعتمدة في مشروع **Stars Homes**، والتي تفصل بوضوح بين طبقة الـ **Backend** (البيانات والخدمات السحابية والمحلية) وطبقة الـ **Frontend** (الواجهات وتجربة المستخدم)، مع طبقة الـ **State Management** التي تربط بينهما.

---

## 📂 هيكل المجلدات المنظم (Directory Structure)

```text
lib/
├── backend.dart               <-- مجمع ومصدر لجميع مكونات الـ Backend
├── frontend.dart              <-- مجمع ومصدر لجميع مكونات الـ Frontend
├── main.dart                  <-- نقطة انطلاق التطبيق وتثبيت الـ Providers
│
├── core/
│   ├── constants/             [FRONTEND] الألوان (AppColors)، النصوص، والثيمات
│   ├── services/              [BACKEND] خدمات قواعد البيانات، المزامنة، الأمان، الواتساب
│   │   ├── db_service.dart            <-- SQLite المحلي (Offline-first)
│   │   ├── sync_service.dart          <-- المزامنة السحابية مع Supabase
│   │   ├── auth_service.dart          <-- مصادقة الـ PIN وأمان الجهاز
│   │   ├── supabase_auth_service.dart <-- تفويض الأجهزة عبر السحابة
│   │   └── whatsapp_service.dart      <-- إرسال رسائل وتأكيدات وفواتير PDF عبر واتساب
│   └── utils/                 [BACKEND / HELPERS] معالجة العملات، التواريخ، وبناء فواتير PDF
│
├── models/                    [BACKEND] نماذج البيانات (Data Entities & Models)
│   ├── customer_order_model.dart
│   ├── worker_model.dart
│   ├── inventory_item_model.dart
│   └── ...
│
├── providers/                 [STATE CONTROLLER] طبقة إدارة الحالة وربط الواجهات بالبيانات
│   ├── customers_provider.dart
│   ├── accounts_provider.dart
│   ├── workers_provider.dart
│   ├── inventory_provider.dart
│   └── ...
│
├── views/                     [FRONTEND] الشاشات وواجهات المستخدم
│   ├── auth/                  <-- شاشات تسجيل الدخول وتفويض الجهاز
│   ├── home/                  <-- الشاشة الرئيسية
│   ├── customers/             <-- شاشات العملاء، تفاصيل الطلب، ومشاركة الفواتير
│   ├── accounts/              <-- الحسابات والمصروفات
│   ├── workers/               <-- العمال والحضور والرواتب
│   ├── inventory/             <-- المخزن والنواقص
│   └── manufacturing/         <-- أوامر التصنيع وبطاقات الورشة
│
└── widgets/                   [FRONTEND] المكونات الرسومية القابلة لإعادة الاستخدام
```

---

## ⚡ خدمات الباك إند (Backend Services):
1. **قاعدة بيانات محلية (SQLite - DBService):**
   - يعمل التطبيق بنظام **Offline-first** بالكامل بدون الحاجة لإنترنت.
   - حفظ مزدوج للرموز السرية وبيانات الجلسة لمنع أي خطأ.
2. **المزامنة السحابية (Supabase - SyncService):**
   - مزامنة فورية تلقائية مع مشروع Supabase: `https://rxbepjrwowtkhonebcsp.supabase.co`.
   - رتل عمليات (Queue) لإرسال أي تعديلات تمت دون إنترنت فور عودة الاتصال.
3. **خدمة واتساب (WhatsAppService):**
   - تجهيز رسالة احترافية باللغة العربية باسم العميل وتفاصيل طلبه فور التسجيل.
   - فتح واتساب العميل بضغطة زر وتوليد فاتورة PDF ومشاركتها مباشرة.

---

## 🎨 واجهات الفرونت إند (Frontend Views):
- تصميم داكن عصري (Dark Theme) مستوحى من هوية مصنع ستارز هومز (الكحلي الداكن والأصفر الذهبي).
- شاشات سريعة ومصممة لشاشات الهواتف وأجهزة التابلت وشاشات العرض داخل المصنع.

