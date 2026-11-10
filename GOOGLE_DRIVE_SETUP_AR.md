# دليل ربط جوجل درايف للنسخ السحابي (Google Drive Integration)
## STARS HOMES ERP — Cloud Backup Storage

يوفر التطبيق إمكانية رفع وحفظ النسخ الاحتياطية تلقائياً في مجلد مخصص وآمن على حساب Google Drive الخاص بالمصنع باسم **`STARS_HOMES_BACKUPS`**.

---

### 1. إعداد حساب Google Cloud Console (مرة واحدة للمصنع)

1. توجه إلى منصة مطوري جوجل: [Google Cloud Console](https://console.cloud.google.com/).
2. أنشئ مشروعاً جديداً باسم `Stars-Homes-ERP`.
3. من القائمة الجانبية، ادخل على **APIs & Services** ⬅️ **Library**، وابحث عن **Google Drive API** واضغط **Enable**.
4. ادخل على **OAuth consent screen**:
   - اختر **External**.
   - املأ اسم التطبيق: `STARS HOMES ERP`، والبريد الإلكتروني للدعم.
   - في قسم **Scopes** أضف الصلاحية المحدودة والآمنة:
     `https://www.googleapis.com/auth/drive.file`
     *(هذه الصلاحية تسمح فقط بالوصول إلى الملفات التي ينشئها التطبيق نفسه ولا يمكن للتطبيق قراءة أي ملفات شخصية أخرى في درايف)*.
5. ادخل على **Credentials** ⬅️ **Create Credentials** ⬅️ **OAuth Client ID**:
   - نوع التطبيق: **Android** (للهواتف) و **Desktop App** (لويندوز).
   - احفظ الـ `Client ID`.

---

### 2. كيفية الربط من داخل التطبيق

1. افتح شاشة **الإعدادات** ⚙️ ⬅️ **النسخ الاحتياطي والاستعادة**.
2. في بطاقة **جوجل درايف (Google Drive)**، اضغط على زر **"ربط حساب Google Drive"**.
3. ستفتح نافذة تسجيل الدخول الرسمية من Google؛ اختر إيميل المصنع واضغط **سماح**.
4. يتم تشفير وحفظ رموز الدخول (Access & Refresh Tokens) بأعلى معايير الأمان عبر:
   - **Windows DPAPI** على الكمبيوتر.
   - **Android EncryptedSharedPreferences (Keystore)** على الهاتف.
5. فور اكتمال الربط، ستتحول الحالة إلى اللون الأخضر: **"متصل بحساب جوجل درايف"**، وسيتم رفع كافة النسخ الاحتياطية الجديدة إلى مجلد `STARS_HOMES_BACKUPS` تلقائياً.
