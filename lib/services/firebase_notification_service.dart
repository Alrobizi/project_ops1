// ============================================
// خدمة إشعارات Firebase (Firebase Notification Service)
// إدارة الإشعارات الفورية والرسائل
//
// ملاحظات الأداء (Performance):
// - التهيئة كاملة غير حاجزة: تُستدعى بعد أول إطار (runApp) ولا تُوقف الإقلاع.
// - كل المستمعات (listeners) تُسجَّل مرة واحدة فقط، فلا تكرار عند إعادة التهيئة.
// - توكن FCM يُخزَّن محلياً ولا يُرسل للسيرفر إلا عند تغيّره أو كل 12 ساعة،
//   مما يوفّر طلب شبكة + كتابة في قاعدة البيانات عند كل فتح للتطبيق.
// - جلب التوكن يُعيد المحاولة بتأخير تصاعدي لأن FCM و APNs قد يتأخران.
// - السجلات (debugPrint) تُكتب في وضع التطوير فقط.
// ============================================

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_router.dart';
import 'api_service.dart';

/// ApiClient عام لإرسال توكن FCM للسيرفر
ApiClient? fcmApiClient;

/// تعيين ApiClient المستخدم لإرسال توكن FCM (يُستدعى من main.dart)
void setFcmApiClient(ApiClient client) {
  fcmApiClient = client;
}

/// سجل تشخيصي لا يُنفَّذ في نسخة الإصدار
void _log(String message) {
  if (kDebugMode) {
    debugPrint('[FCM] $message');
  }
}

/// معالجة الإشعارات في الخلفية / عند إغلاق التطبيق
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // لا نُهيّئ Firebase هنا: الإشعار من نوع notification يعرضه النظام تلقائياً،
  // وتهيئة Firebase داخل الـ isolate الخلفي مكلفة وتُبطئ معالجة الرسائل.
  _log('📩 إشعار في الخلفية (Background): ${message.notification?.title}');
  _log('📄 الرسالة: ${message.notification?.body}');
  if (message.data.isNotEmpty) {
    _log('📦 بيانات الإشعار: ${message.data}');
  }
}

class FirebaseNotificationService {
  FirebaseNotificationService._();

  // ----- مفاتيح التخزين المحلي -----
  static const String _prefToken = 'fcm_token_value';
  static const String _prefSyncedToken = 'fcm_token_synced_value';
  static const String _prefSyncedAt = 'fcm_token_synced_at';

  /// مدة إعادة المصالحة مع السيرفر (12 ساعة) — حماية من فقدان التوكن على الخادم
  static const Duration _resyncInterval = Duration(hours: 12);

  /// عدد محاولات جلب توكن FCM
  static const int _maxTokenAttempts = 4;

  static FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  // ----- بثّ الأحداث للواجهة (Riverpod) -----
  static final StreamController<RemoteMessage> _foregroundController =
      StreamController<RemoteMessage>.broadcast();
  static final StreamController<RemoteMessage> _openedController =
      StreamController<RemoteMessage>.broadcast();

  static Future<void>? _initFuture;
  static Future<void>? _syncFuture;
  static Future<String?>? _tokenFuture;

  static StreamSubscription<String>? _tokenRefreshSub;
  static StreamSubscription<RemoteMessage>? _foregroundSub;
  static StreamSubscription<RemoteMessage>? _openedSub;

  static String? _fcmToken;
  static String? _lastError;
  static bool _messagingReady = false;
  static bool _backgroundHandlerRegistered = false;

  // منع تكرار عرض نفس الإشعار (SnackBar)
  static String? _lastShownKey;
  static DateTime? _lastShownAt;

  // منع تنفيذ التنقّل لنفس الرسالة مرتين (getInitialMessage + onMessageOpenedApp)
  static final Set<String> _handledOpenedKeys = <String>{};

  /// إشعارات وصلت والتطبيق مفتوح — تستخدمها الواجهة لتحديث القائمة والعدّاد
  static Stream<RemoteMessage> get foregroundMessages =>
      _foregroundController.stream;

  /// إشعارات نقر عليها المستخدم (تطبيق مفتوح أو مغلق)
  static Stream<RemoteMessage> get openedMessages => _openedController.stream;

  /// التوكن الحالي للجهاز
  static String? get fcmToken => _fcmToken;

  /// هل استُكملت تهيئة المراسلة بنجاح؟
  static bool get isMessagingReady => _messagingReady;

  /// هل يستطيع السيرفر الوصول لهذا الجهاز حالياً؟
  static bool get pushAvailable =>
      _messagingReady && (_fcmToken?.isNotEmpty ?? false);

  /// آخر خطأ حدث (للتشخيص)
  static String? get lastError => _lastError;

  /// تسجيل معالج رسائل الخلفية — يجب أن يسبق استقبال أي رسالة خلفية.
  /// آمن للاستدعاء أكثر من مرة.
  static void registerBackgroundHandler() {
    if (kIsWeb || _backgroundHandlerRegistered) {
      return;
    }

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _backgroundHandlerRegistered = true;
    } catch (e) {
      _lastError = e.toString();
      _log('⚠️ تعذّر تسجيل معالج إشعارات الخلفية: $e');
    }
  }

  /// تهيئة Firebase والإشعارات — آمنة للاستدعاء المتكرر ولا تحجب الواجهة
  static Future<void> initialize() {
    return _initFuture ??= _initialize();
  }

  static Future<void> _initialize() async {
    try {
      try {
        await Firebase.initializeApp();
      } on FirebaseException catch (e) {
        // مهيّأة مسبقاً (iOS/Swift أو تهيئة سابقة) — نكمل بشكل طبيعي
        if (e.code != 'duplicate-app') {
          rethrow;
        }
        _log('ℹ️ Firebase مهيّأة مسبقاً، متابعة الإعداد');
      }

      registerBackgroundHandler();
      await _setupMessaging();
    } catch (e) {
      _lastError = e.toString();
      _log('⚠️ FirebaseNotificationService.initialize error: $e');
    }
  }

  /// إعداد الإشعارات وتسجيل المستمعين (مرة واحدة فقط)
  static Future<void> _setupMessaging() async {
    if (_messagingReady) {
      return;
    }

    try {
      if (!kIsWeb) {
        try {
          await _messaging.setAutoInitEnabled(true);
        } catch (e) {
          _log('ℹ️ setAutoInitEnabled: $e');
        }
      }

      await _requestPermission();

      // إشعارات iOS أثناء فتح التطبيق تُعرض بواسطة الواجهة نفسها (SnackBar)
      try {
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (e) {
        _log('ℹ️ presentation options: $e');
      }

      // تحديث التوكن تلقائياً عند تغيّره (يُرسل للسيرفر مرة واحدة)
      _tokenRefreshSub ??= _messaging.onTokenRefresh.listen(
        (newToken) {
          _log('🔑 تم تحديث توكن FCM');
          _fcmToken = newToken;
          unawaited(_persistToken(newToken));
          unawaited(_sendTokenToServer(newToken, force: true));
        },
        onError: (Object e) => _log('⚠️ onTokenRefresh error: $e'),
      );

      // إشعار وصل والتطبيق مفتوح
      _foregroundSub ??= FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
        onError: (Object e) => _log('⚠️ onMessage error: $e'),
      );

      // المستخدم نقر على الإشعار والتطبيق في الخلفية
      _openedSub ??= FirebaseMessaging.onMessageOpenedApp.listen(
        _handleOpenedMessage,
        onError: (Object e) => _log('⚠️ onMessageOpenedApp error: $e'),
      );

      _messagingReady = true;

      // لا نُعطّل الإقلاع بانتظار التوكن أو الشبكة
      unawaited(syncToken());
      unawaited(_consumeInitialMessage());
    } catch (e) {
      _lastError = e.toString();
      _log('⚠️ خطأ في إعداد إشعارات Firebase: $e');
    }
  }

  /// طلب إذن الإشعارات (أندرويد 13+ / iOS)
  static Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      _log(
        '🔔 حالة إذن الإشعارات: ${settings.authorizationStatus}'
        ' | تنبيه: ${settings.alert} | صوت: ${settings.sound}',
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _log('⚠️ المستخدم رفض الإشعارات — لن تُعرض الإشعارات الفورية');
      }
    } catch (e) {
      _lastError = e.toString();
      _log('⚠️ خطأ في طلب إذن الإشعارات: $e');
    }
  }

  /// طلب الإذن صراحة (يمكن استدعاؤها من شاشة الإعدادات)
  static Future<bool> requestPermission() async {
    await initialize();
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// إرسال توكن FCM للسيرفر — تُستدعى بعد تسجيل الدخول واستعادة الجلسة.
  ///
  /// تنفيذ متزامن واحد فقط (dedupe): استدعاءات متعددة في نفس اللحظة
  /// تنتظر العملية الجارية بدلاً من فتح عدة طلبات شبكة.
  static Future<void> syncToken({bool force = false}) async {
    final inFlight = _syncFuture;
    if (inFlight != null) {
      await inFlight;
      if (!force) {
        return;
      }
    }

    final future = _syncToken(force: force);
    _syncFuture = future;
    try {
      await future;
    } finally {
      if (identical(_syncFuture, future)) {
        _syncFuture = null;
      }
    }
  }

  static Future<void> _syncToken({bool force = false}) async {
    if (fcmApiClient == null) {
      _log('ℹ️ لا يوجد ApiClient بعد — تأجيل إرسال توكن FCM');
      return;
    }

    if (!await _ensureReady()) {
      _log('ℹ️ إشعارات Firebase غير جاهزة — تأجيل إرسال التوكن');
      return;
    }

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      _log('⚠️ لم يُعثر على توكن FCM — لن تصل الإشعارات لهذا الجهاز');
      return;
    }

    await _sendTokenToServer(token, force: force);
  }

  /// انتظار انتهاء التهيئة (دون إطلاقها من جديد)
  static Future<bool> _ensureReady() async {
    if (_messagingReady) {
      return true;
    }

    final init = _initFuture;
    if (init == null) {
      return false;
    }

    try {
      await init.timeout(const Duration(seconds: 15));
    } catch (e) {
      _log('⚠️ مهلة تهيئة إشعارات Firebase: $e');
    }

    return _messagingReady;
  }

  /// إرسال التوكن للسيرفر مرة واحدة فقط عند تغيّره (أو عند طلب صريح)
  static Future<bool> _sendTokenToServer(
    String token, {
    bool force = false,
  }) async {
    final client = fcmApiClient;
    if (client == null) {
      _log('⚠️ لا يوجد ApiClient بعد — تأجيل إرسال توكن FCM للسيرفر Render');
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final syncedToken = prefs.getString(_prefSyncedToken);
    final syncedAt = prefs.getInt(_prefSyncedAt) ?? 0;
    final age = DateTime.now().millisecondsSinceEpoch - syncedAt;
    final recentlySynced = syncedAt > 0 && age < _resyncInterval.inMilliseconds;

    if (!force && recentlySynced && syncedToken == token) {
      _log('ℹ️ تم مزامنة توكن FCM مسبقاً مع سيرفر Render');
      return true;
    }

    _log('🌐 جاري إرسال توكن FCM إلى سيرفر Render (${ApiClient.baseUrl}/user/fcm-token)...');
    final ok = await client.sendFcmToken(token);
    if (ok) {
      _log('✅ تم تسجيل توكن FCM بنجاح في قاعدة بيانات Render!');
      await prefs.setString(_prefSyncedToken, token);
      await prefs.setInt(
        _prefSyncedAt,
        DateTime.now().millisecondsSinceEpoch,
      );
    } else {
      _log('⚠️ لم يتم حفظ توكن FCM في Render (تحقق من تسجيل دخول المستخدم)');
    }

    return ok;
  }

  /// جلب التوكن مع منع تكرار العملية في نفس اللحظة
  static Future<String?> _getToken() {
    final running = _tokenFuture;
    if (running != null) {
      return running;
    }

    final future = _loadToken(attempts: _maxTokenAttempts).whenComplete(() {
      _tokenFuture = null;
    });
    _tokenFuture = future;
    return future;
  }

  static Future<String?> _loadToken({required int attempts}) async {
    if (!_messagingReady) {
      return _fcmToken;
    }

    // على iOS لا يُصدر FCM توكنه قبل وصول توكن APNs
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _waitForApns();
    }

    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        final token = await _messaging.getToken();
        if (token != null && token.isNotEmpty) {
          _fcmToken = token;
          unawaited(_persistToken(token));
          return token;
        }
      } catch (e) {
        _lastError = e.toString();
        _log('⚠️ getToken (محاولة ${attempt + 1}/$attempts): $e');
      }

      if (attempt < attempts - 1) {
        // 1s, 2s, 4s — تأخير تصاعدي دون إغراق الخدمة
        await Future<void>.delayed(Duration(seconds: 1 << attempt));
      }
    }

    return _fcmToken;
  }

  /// انتظار توكن APNs على iOS (حتى ثانيتين) قبل طلب توكن FCM
  static Future<void> _waitForApns() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final apns = await _messaging.getAPNSToken();
        if (apns != null && apns.isNotEmpty) {
          return;
        }
      } catch (e) {
        // المحاكي لا يملك APNs — نكمل بدونه
        _log('ℹ️ تعذّر قراءة توكن APNs: $e');
        return;
      }

      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }

  /// حفظ التوكن محلياً (لا يُوقف أي عملية إذا فشل)
  static Future<void> _persistToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefToken, token);
    } catch (e) {
      _log('⚠️ تعذّر حفظ توكن FCM محلياً: $e');
    }
  }

  /// آخر توكن محفوظ على الجهاز (يُستخدم قبل تهيئة Firebase)
  static Future<String?> storedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefToken);
    } catch (_) {
      return null;
    }
  }

  /// مفتاح فريد للرسالة لمنع المعالجة المزدوجة
  static String? _messageKey(RemoteMessage message) {
    final id = message.messageId;
    if (id != null && id.isNotEmpty) {
      return id;
    }

    final orderId = message.data['order_id']?.toString();
    final notifId = message.data['notification_id']?.toString();
    if (orderId == null && notifId == null) {
      return null;
    }

    return '${message.notification?.title}|${orderId ?? ''}|${notifId ?? ''}';
  }

  /// إشعار وصل والتطبيق مفتوح
  static void _handleForegroundMessage(RemoteMessage message) {
    _log('📬 إشعار وارد (Foreground): ${message.notification?.title} | ${message.notification?.body}');
    if (message.data.isNotEmpty) {
      _log('📦 بيانات الإشعار الوارد: ${message.data}');
    }

    // بثّ الحدث للواجهة لتحديث العدّاد والقائمة بدون طلب شبكة
    if (!_foregroundController.isClosed) {
      _foregroundController.add(message);
    }

    _showLocalNotification(message);
  }

  /// المستخدم نقر على الإشعار والتطبيق في الخلفية
  static void _handleOpenedMessage(RemoteMessage message) {
    final key = _messageKey(message);
    if (key != null && !_handledOpenedKeys.add(key)) {
      return; // عُولجت مسبقاً
    }

    _log('👆 تم النقر على الإشعار من شريط التنبيهات: ${message.notification?.title}');
    if (message.data.isNotEmpty) {
      _log('📦 بيانات الإشعار المنقور: ${message.data}');
    }

    if (!_openedController.isClosed) {
      _openedController.add(message);
    }

    _navigateFromMessage(message);
  }

  /// التطبيق كان مغلقاً بالكامل وفتحه المستخدم بضغط على الإشعار
  static Future<void> _consumeInitialMessage() async {
    try {
      final initial = await _messaging.getInitialMessage();
      if (initial == null) {
        return;
      }

      final key = _messageKey(initial);
      if (key != null) {
        _handledOpenedKeys.add(key);
      }

      _log('❄️ فتح التطبيق من حالة الإغلاق عبر إشعار: ${initial.notification?.title}');
      if (initial.data.isNotEmpty) {
        _log('📦 بيانات إشعار الإقلاع: ${initial.data}');
      }

      if (!_openedController.isClosed) {
        _openedController.add(initial);
      }

      _navigateFromMessage(initial, coldStart: true);
    } catch (e) {
      _log('⚠️ تعذّر قراءة رسالة الإقلاع: $e');
    }
  }

  /// عرض إشعار محلي أثناء فتح التطبيق (SnackBar)
  static void _showLocalNotification(RemoteMessage message) {
    if (kIsWeb) {
      return;
    }

    final title =
        message.notification?.title ?? message.data['title']?.toString() ?? '';
    final body =
        message.notification?.body ?? message.data['body']?.toString() ?? '';

    if (title.isEmpty && body.isEmpty) {
      return;
    }

    // نفس الرسالة قد تصل أكثر من مرة (إعادة محاولة من FCM) — نعرضها مرة واحدة
    final key = _messageKey(message) ?? '${message.hashCode}';
    final now = DateTime.now();
    if (_lastShownKey == key &&
        _lastShownAt != null &&
        now.difference(_lastShownAt!) < const Duration(seconds: 3)) {
      return;
    }

    final context = AppRouter.navigatorKey.currentContext;
    if (context == null) {
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }

    _lastShownKey = key;
    _lastShownAt = now;

    final width = MediaQuery.sizeOf(context).width;

    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        width: width > 640 ? 460 : null,
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFF1E293B),
        content: Row(
          children: [
            const Icon(
              Icons.notifications_active_outlined,
              color: Colors.amber,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  if (body.isNotEmpty)
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'عرض',
          textColor: Colors.amber,
          onPressed: () => _navigateFromMessage(message),
        ),
      ),
    );
  }

  /// تحديد الوجهة بناءً على بيانات الرسالة
  static void _navigateFromMessage(
    RemoteMessage message, {
    bool coldStart = false,
  }) {
    final route = (message.data['route'] ?? '').toString().trim();
    final orderId = (message.data['order_id'] ?? '').toString().trim();
    final notificationId =
        (message.data['notification_id'] ?? '').toString().trim();

    // صفحة تفاصيل الطلب تحتاج كائن Order كاملاً (extra)،
    // لذا نفتح قائمة الطلبات ويُكمل المستخدم بنفسه.
    if (route.startsWith('/') && !route.startsWith('/order-details')) {
      _navigate(route, coldStart: coldStart);
      return;
    }

    if (orderId.isNotEmpty) {
      _navigate('/orders', coldStart: coldStart);
      return;
    }

    if (notificationId.isNotEmpty) {
      _navigate('/notifications', coldStart: coldStart);
      return;
    }

    _navigate('/notifications', coldStart: coldStart);
  }

  static void _navigate(String location, {bool coldStart = false}) {
    void go() {
      try {
        if (coldStart) {
          AppRouter.router.go(location);
        } else {
          AppRouter.router.push(location);
        }
      } catch (e) {
        _log('⚠️ تعذّر الانتقال إلى $location: $e');
      }
    }

    if (coldStart) {
      // الإطار الأول لم يُبنَ بعد عند فتح التطبيق من إشعار
      WidgetsBinding.instance.addPostFrameCallback((_) => go());
    } else {
      go();
    }
  }

  /// فصل الجهاز عن الحساب الحالي عند تسجيل الخروج
  ///
  /// ينظّف علامات المزامنة المحلية حتى يُعاد إرسال التوكن للحساب التالي فوراً
  /// (وإلا سيبقى التوكن القديم مربوطاً بالمستخدم السابق في قاعدة البيانات).
  static Future<void> unregisterFromServer() async {
    try {
      final client = fcmApiClient;
      if (client != null) {
        await client.clearFcmToken();
      }
    } catch (e) {
      _log('⚠️ تعذّر حذف توكن FCM من السيرفر: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefSyncedToken);
      await prefs.remove(_prefSyncedAt);
    } catch (e) {
      _log('⚠️ تعذّر تنظيف حالة مزامنة التوكن: $e');
    }
  }

  /// الاشتراك في موضوع (topic) — لعرض الشرائح للإشعارات الجماعية
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      _log('✅ اشتراك في الموضوع: $topic');
    } catch (e) {
      _lastError = e.toString();
      _log('⚠️ تعذّر الاشتراك في الموضوع $topic: $e');
    }
  }

  /// إلغاء الاشتراك في موضوع
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      _log('✅ إلغاء الاشتراك في الموضوع: $topic');
    } catch (e) {
      _lastError = e.toString();
      _log('⚠️ تعذّر إلغاء الاشتراك من الموضوع $topic: $e');
    }
  }
}
