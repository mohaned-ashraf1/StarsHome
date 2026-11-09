# دليل بناء وإصدار النسخ الجديدة (STARS HOMES ERP Deployment Guide)

دليل موجه لفريق التطوير وإدارة النظام لشرح كيفية تجميع وبناء النسخ الجديدة لكافة المنصات وتحديثها.

---

## 1. البناء الآلي السحابي عبر GitHub Actions 🌟 *(الأسهل والأنظف)*

المشروع مزود بملف عمل آلي داخل: `.github/workflows/build_releases.yml`.
بمجرد عمل `git push` لأي تعديل على الفرع `main`:
1. تقوم سيرفرات GitHub (سيرفرات ويندوز وسيرفرات لينكس) آلياً بإجراء الآتي:
   - فحص الأكواد واختبارها عبر `flutter analyze` و `flutter test`.
   - بناء تطبيق ويندوز Release كامل.
   - تشغيل **Inno Setup** لتجميع مثبت الويندوز المباشر: `STARS_HOMES_ERP_Setup.exe`.
   - تجميع حزمة ويندوز المحمولة: `STARS_HOMES_ERP_Windows_Portable.zip`.
   - بناء ملف الأندرويد: `app-release.apk`.
2. تتوفر هذه الملفات مباشرة للتحميل في تبويب **Actions** أو **Releases** على GitHub دون الحاجة لتثبيت أي برامج تجميع على جهازك الشخصي.

---

## 2. البناء اليدوي المحلي من سطر الأوامر (Local Manual Builds)

جميع أوامر فلاتر الآن تعمل من داخل مجلد **`frontend/`**:

### أ. بناء نسخة الأندرويد (Android APK)
```bash
cd frontend
flutter pub get
flutter build apk --release
```
- **المخرج:** `frontend/build/app/outputs/flutter-apk/app-release.apk`.

### ب. بناء تطبيق ويندوز 11 (Windows Desktop)
*(يتطلب تثبيت Visual Studio Community مع مكون C++ Desktop Development على اللابتوب)*:
```bash
cd frontend
flutter pub get
flutter build windows --release
```
- **المخرج:** `frontend/build/windows/x64/runner/Release/`.

### ج. تجميع مثبت الويندوز (Inno Setup)
بعد اكتمال بناء الويندوز أعلاه:
```bash
iscc windows_installer\installer_script.iss
```
- **المخرج:** `windows_installer/STARS_HOMES_ERP_Setup.exe`.

### د. بناء نسخة الويب (Web App)
```bash
cd frontend
flutter build web --release
```
- **المخرج:** `frontend/build/web/`.

---

## 3. إدارة الإصدارات والترقية (Version Management)

عند إجراء أي ترقية برمجية جديدة:
1. افتح ملف `frontend/pubspec.yaml`.
2. قم بزيادة رقم الإصدار (Version) ورقم البناء (Build Number)، مثال:
   ```yaml
   version: 1.0.13+14
   ```
3. ارفع التعديل إلى المستودع (`git commit` ثم `git push`).
4. سيقوم GitHub Actions آلياً بتجميع النسخة الجديدة وحفظها جاهزة للتحميل والتثبيت.

