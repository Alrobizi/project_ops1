# وثيقة تسليم المشروع والإصلاحات الشاملة (Project Handoff & Complete Fixes Guide)
**مشروع: بركة عدن (Barakat Aden)**  
**تاريخ التحديث:** نوفمبر 2026  
**الهدف من الملف:** مرجع تقني شامل ومفصل لجميع الإصلاحات، المعماريات، المشاكل المحلولة، وإعدادات الربط لنقله لأي نموذج ذكاء اصطناعي آخر (AI Handoff Document).

---

## 1. روابط المستودعات والبيئات (Repositories & Environments)

* **تطبيق فلاتر (Flutter Frontend):**
  * المستودع: `https://github.com/Alrobizi/project_ops1`
  * الفرع النشط: `main`
  * إطار العمل: Flutter 3.29.x / Dart 3.7.x
  * إدارة الحالة: Riverpod (`flutter_riverpod: ^2.5.1`)
  * التوجيه (Routing): GoRouter (`go_router: ^14.2.0`)

* **السيرفر ولوحة التحكم (Laravel Backend & API):**
  * المستودع: `https://github.com/Alrobizi/project_ops_server_backend_BRKEDT_ADEN`
  * الفرع النشط: `main`
  * السيرفر السحابي المباشر: `https://barakat-aden.onrender.com` (مستضاف على Render، نشر تلقائي عند الـ Push)
  * إطار العمل: Laravel 11.x / PHP 8.2+
  * قاعدة البيانات: SQLite (`server/database/database.sqlite`)
  * لوحة التحكم الرئيسية: `https://barakat-aden.onrender.com/admin` (مبنية بـ React SPA مدمج داخل Laravel)

---

## 2. المشكلات التي تم حلها بالتفصيل (Solved Issues & Root Causes)

### المشكلة الأولى: بناء وتثبيت تطبيق iOS وخطأ الشاشة البيضاء (White Screen & iOS Build)
1. **أخطاء CocoaPods و Swift في GitHub Actions:**
   * **السبب:** ظهور خطأ `CocoaPods could not find compatible versions for pod "Flutter"` بسبب عدم تعيين منصة صريحة في `ios/Podfile` وافتراض النظام القديم (iOS 13.0). وظهور خطأ `Access level on imports require '-enable-experimental-feature AccessLevelOnImports'` في مكتبات Firebase مع Swift 6 على macOS 15.
   * **الحل:**
     * إنشاء وتعديل `ios/Podfile` ورفع الحد الأدنى إلى `platform :ios, '15.0'`.
     * ضبط `IPHONEOS_DEPLOYMENT_TARGET = '15.0'` في الـ Pods ومشروع Xcode `project.pbxproj`.
     * إضافة راية Swift في `post_install`:  
       `config.build_settings['OTHER_SWIFT_FLAGS'] = '$(inherited) -enable-experimental-feature AccessLevelOnImports'`.
     * تحديث سير العمل في `.github/workflows/ios_build.yml` للعمل على `macos-15` وبناء حزمة الـ IPA وتضمين `GoogleService-Info.plist` تلقائياً داخل مجلد الحزمة `Payload/Runner.app/`.

2. **مشكلة الشاشة البيضاء (White Screen Crash) عند فتح التطبيق على الآيفون:**
   * **السبب:** كان استدعاء `Firebase.initializeApp()` و `FirebaseMessaging` يعلق في انتظار استجابة خدمات آبل (APNs) في حال لم تكن الشهادة موقعة بحساب مطور، مما يمنع تنفيذ `runApp()` وتظل الشاشة بيضاء للأبد.
   * **الحل:** في `lib/main.dart`، تم وضع مهلة زمنية (Timeout مدته 3 ثوانٍ) داخل `try-catch` لتهيئة Firebase، بحيث يستمر التطبيق في فتح الواجهات فوراً حتى لو تأخرت خدمة الإشعارات:
     ```dart
     await FirebaseNotificationService.initialize().timeout(
       const Duration(seconds: 3),
       onTimeout: () => debugPrint('⚠️ Firebase init timeout, proceeding to runApp'),
     );
     runApp(const ProviderScope(child: MyApp()));
     ```

3. **مشكلة برنامج Sideloadly (`<no devices detected>`):**
   * **السبب:** عدم توفر تعريفات أجهزة آبل (Apple Mobile Device Support) على ويندوز أو عدم منح إذن الوثوق.
   * **الحل:** تثبيت برنامج iTunes الرسمي (نسخة ملف التثبيت المباشر وليس متجر مايكروسوفت) أو iCloud، وتوصيل الآيفون عبر USB وفتح قفل الشاشة والضغط على **"وثوق (Trust)"** وإدخال الرمز، ثم تشغيل Sideloadly وسحب ملف `barakat_aden.ipa` ووضع Apple ID والضغط على **Start**.

---

### المشكلة الثانية: صفحة «طلباتي» في تطبيق الفلاتر (Orders Screen Activation)
1. **السبب:**
   * لم تكن الشاشة تستدعي جلب الطلبات عند الدخول إليها ولا عند تسجيل الدخول الجديد، بل كانت تُستدعى مرة واحدة فقط عند إقلاع التطبيق قبل تسجيل الدخول فتفشل برمز 401.
   * كان هناك خطأ في تحويل قيم الأرقام القادمة من السيرفر `(json['subtotal'] as num).toDouble()` فإذا وصلت كـ String من بعض الـ API resources كان ينهار الكود بصمت وتظهر الشاشة فارغة.
   * غياب علاقة الـ eager loading للمنتج `items.product` في السيرفر.
2. **الحل:**
   * **في التطبيق (`lib/screens/cart_screen.dart`):**
     * إعادة بناء `_OrdersScreenState` كـ `ConsumerStatefulWidget`.
     * إضافة استدعاء مباشر لجلب الطلبات `ref.read(ordersProvider.notifier).loadOrders()` فور فتح الشاشة.
     * إضافة ميزة السحب للتحديث `RefreshIndicator` وزر تحديث يدوي في شريط العنوان (AppBar).
     * عرض بطاقات الطلبات مع شارة ملونة توضح حالة الطلب.
   * **في النماذج (`lib/models/models.dart`):**
     * استبدال التحويل المباشر بـ `double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0` لكافة حقول المبالغ (`subtotal`, `shipping`, `total`).
     * تعديل دالة `CartItem.fromJson` لإنشاء كائن بديل من المنتج إذا وصل فارغاً لتفادي أي انهيار.
     * تحديث حالات الطلب `OrderStatus`:
       * `pending` -> **قيد المراجعة** (أصفر / Amber)
       * `processing` -> **قيد التجهيز** (بنفسجي / Purple)
       * `shipped` -> **قيد الشحن** (أزرق / Blue)
       * `delivered` -> **تم التوصيل** (أخضر / Green)
       * `cancelled` -> **ملغي** (أحمر / Red)
   * **في إدارة الحالة (`lib/providers/app_providers.dart`):**
     * ربط `ordersProvider` بمراقبة `authProvider.isAuthenticated` لإعادة جلب الطلبات فور تسجيل الدخول.
   * **في السيرفر (`server/app/Http/Controllers/Api/OrderController.php`):**
     * إضافة `with(['items.product', 'address'])` في كل من `index()` و `show()`.
     * زيادة حد استعراض الطلبات إلى 50 طلباً لكل صفحة.

---

### المشكلة الثالثة: إشعارات Firebase وربط الـ FCM Token بالسيرفر
1. **السبب:**
   * في `main.dart`، كان يتم تمرير كائن `ApiClient` فارغ وجديد إلى `setFcmApiClient(ApiClient())` قبل أن يقوم المستخدم بتسجيل الدخول.
   * عندما يسجل المستخدم دخوله، كان `AuthNotifier` يضع التوكن في نسخة أخرى داخل `apiClientProvider`، بينما ظلت خدمة FCM تستخدم النسخة القديمة الفارغة من الـ Bearer Token، فكان إرسال التوكن إلى `POST /api/user/fcm-token` يُرفض دائماً برمز `401 Unauthorized` ولا يتم حفظ التوكن في قاعدة البيانات مطلقاً.
2. **الحل:**
   * في `lib/providers/app_providers.dart`: تم ربط `setFcmApiClient(client)` داخل `apiClientProvider` لضمان استخدام الـ Singleton الفعلي.
   * في `lib/services/api_service.dart`: تم تعديل `setToken(String token)` بحيث تستدعي تلقائياً `setFcmApiClient(this)` ثم تستدعي `FirebaseNotificationService.syncToken()` بمجرد تسجيل الدخول.
   * في `lib/services/firebase_notification_service.dart`: إزالة القيود المانعة لجلب التوكن عند عدم توفر APNs Token على أجهزة الاختبار، وتفعيل التقاط الإشعارات المباشرة وعرضها داخل التطبيق فور وصولها.

---

### المشكلة الرابعة: تثبيت وتحديث رقم الواتساب بالكامل إلى `772055335`
1. **السبب:**
   * وجود قيم افتراضية قديمة مسبقة (مثل `777967456` أو `777123456`) في ملفات الـ Migration وواجهة `admin.html` وكود فلاتر `StoreSettings`.
   * عدم تفاعل React State في لوحة التحكم عند جلب الإعدادات المحفوظة من السيرفر، حيث كان الفورم يحتفظ بالقيم الأولية.
2. **الحل الشامل:**
   * **في قاعدة البيانات والسيرفر:**
     * تحديث سجلات جدول `settings` في قاعدة بيانات SQLite لتصبح:
       * `store_phone` = `'772055335'`
       * `whatsapp_number` = `'772055335'`
       * `whatsapp_transfer_number` = `'772055335'`
     * تعديل الهجرة `server/database/migrations/2026_08_03_100005_create_settings_table.php` لتكون القيمة الافتراضية `'772055335'`.
     * في `server/app/Http/Controllers/Api/AdminController.php`:
       * في `publicSettings()`: تم تثبيت الرقم البديل ليكون `'772055335'`.
       * في `updateSettings()`: دعم استقبال البيانات سواء ككائن مفاتيح أو كمصفوفة، مع المزامنة التلقائية بين `whatsapp_number` و `whatsapp_transfer_number`.
   * **في لوحة التحكم (`server/public/admin.html` و `server/resources/views/admin.html`):**
     * تحديث القيم الأولية الافتراضية لـ `INITIAL_SETTINGS`.
     * إضافة `useEffect` لمزامنة `formData` مع `settings` الحقيقية فور تحميلها من الـ API، وتحديث الـ Cache فور الضغط على حفظ.
   * **في تطبيق فلاتر (`lib/providers/app_providers.dart`):**
     * ضبط القيمة الاحتياطية في `StoreSettings` إلى `772055335` (والدولي `967772055335`).

---

## 3. قائمة الملفات المعدلة في المستودعين (Modified Files List)

### مستودع فلاتر (`project_ops1`):
1. `lib/main.dart` - حماية تهيئة Firebase بمهلة زمنية غير مانعة لتجنب الشاشة البيضاء.
2. `lib/models/models.dart` - معالجة آمنة للأرقام والأسعار بـ `double.tryParse`، وتحديث مسميات حالات الطلب.
3. `lib/providers/app_providers.dart` - ربط الـ ApiClient المعتمد بخدمة FCM، وإعادة جلب الطلبات عند تسجيل الدخول، وتحديث رقم الواتساب الافتراضي.
4. `lib/screens/cart_screen.dart` - تفعيل شاشة `OrdersScreen` بالسحب للتحديث وعرض تفاصيل وحالات الطلبات.
5. `lib/services/api_service.dart` - مزامنة توكن FCM عند `setToken`، وفحص التحقق قبل إرسال التوكن.
6. `lib/services/firebase_notification_service.dart` - معالجة استقبال وتوليد التوكن على مختلف المنصات دون تعليق.
7. `lib/widgets/common_widgets.dart` - ألوان مميزة ومحدثة لشارة حالة الطلب (`OrderStatusBadge`).
8. `ios/Podfile` - ضبط الحد الأدنى `platform :ios, '15.0'` وإضافة `-enable-experimental-feature AccessLevelOnImports`.
9. `ios/Runner.xcodeproj/project.pbxproj` - ضبط `IPHONEOS_DEPLOYMENT_TARGET = 15.0`.
10. `.github/workflows/ios_build.yml` - أتمتة بناء الـ IPA على macOS-15 وحزم الملفات بشكل سليم.

### مستودع السيرفر (`project_ops_server_backend_BRKEDT_ADEN`):
1. `app/Http/Controllers/Api/AdminController.php` - تحديث جلب وحفظ الإعدادات بالرقم الجديد.
2. `app/Http/Controllers/Api/OrderController.php` - إضافة Eager Loading للعناصر والمنتجات والعناوين.
3. `app/Http/Resources/OrderItemResource.php` - تمرير بيانات وصور المنتجات ضمن عناصر الطلب.
4. `database/migrations/2026_08_03_100005_create_settings_table.php` - تعيين الرقم الافتراضي `772055335`.
5. `public/admin.html` و `resources/views/admin.html` - تحديث لوحة التحكم ومزامنة حفظ الإعدادات في الواجهة.

---

## 4. إرشادات الاستخدام والاختبار للنماذج اللاحقة (Instructions for Next AI)

1. **التعامل مع بيئة البناء:**
   - نظام التشغيل الحالي: Windows.
   - Flutter SDK مساره: `C:\src\flutter\bin\flutter.bat`.
   - Dart SDK مساره: `C:\src\flutter\bin\cache\dart-sdk\bin\dart.exe`.
   - فحص الأخطاء يتم دوماً عبر:
     `& "C:\src\flutter\bin\cache\dart-sdk\bin\dart.exe" analyze <files>`.
2. **التعامل مع السيرفر المحلي والبعيد:**
   - المجلد المحلي للسيرفر: `server/`.
   - السيرفر السحابي يعمل على Render ويتم تحديثه تلقائياً بمجرد عمل `git push origin main` داخل مجلد `server/`.
   - قاعدة البيانات المحلية: SQLite في `server/database/database.sqlite`.
3. **تطبيق الفلاتر وحزم iOS:**
   - بمجرد عمل `git push origin main` في المجلد الرئيسي، يتم تشغيل GitHub Actions لبناء ملف `barakat_aden.ipa`.
   - يمكن تحميل الـ IPA من تبويب Artifacts في صفحة الـ Actions وتثبيته عبر Sideloadly على هواتف الآيفون بدون حساب مطور مدفوع.
