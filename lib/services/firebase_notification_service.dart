// ============================================
// خدمة إشعارات Firebase (Firebase Notification Service)
// إدارة الإشعارات الفورية والرسائل
// ============================================

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../app_router.dart';
import 'api_service.dart';

/// ApiClient عام لإرسال توكن FCM للسيرفر
ApiClient? fcmApiClient;

/// تعيين ApiClient المستخدم لإرسال توكن FCM (يُستدعى من main.dart)
void setFcmApiClient(ApiClient client) {
  fcmApiClient = client;
}

/// إرسال التوكن للسيرفر إذا كان المستخدم مسجلاً دخوله
Future<void> _sendTokenToServer(String token) async {
  try {
    await fcmApiClient?.sendFcmToken(token);
  } catch (e) {
    debugPrint('❌ فشل إرسال توكن FCM للسيرفر: $e');
  }
}

/// معالجة الإشعارات في الخلفية
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 إشعار في الخلفية: ${message.notification?.title}');
  debugPrint('📄 الرسالة: ${message.notification?.body}');
}

class FirebaseNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;

  /// تهيئة Firebase
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      await _setupMessaging();
    } catch (e) {
      debugPrint('⚠️ FirebaseNotificationService.initialize error: $e');
    }
  }

  /// إعداد الإشعارات
  static Future<void> _setupMessaging() async {
    // معالج الإشعارات في الخلفية
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // طلب إذن الإشعارات وتفعيل خيارات الواجهة
    await _requestPermission();

    // الحصول على التوكن
    await _getToken();

    // الاستماع للإشعارات عند فتح التطبيق
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 إشعار جديد وارد: ${message.notification?.title}');
      debugPrint('📄 الرسالة: ${message.notification?.body}');
      _showLocalNotification(message);
    });

    // الاستماع للإشعارات عند النقر عليها
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📩 تم فتح الإشعار: ${message.notification?.title}');
      _handleNotificationTap(message);
    });

    // معالجة الإشعار عند فتح التطبيق من الإشعار
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('📩 تم فتح التطبيق من إشعار: ${initialMessage.notification?.title}');
      _handleNotificationTap(initialMessage);
    }
  }

  /// طلب إذن الإشعارات
  static Future<void> _requestPermission() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // تمكين عرض التنبيهات والأصوات داخل التطبيق فورياً على iOS
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ تم منح إذن الإشعارات');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('⚠️ إذن مؤقت للإشعارات');
      } else {
        debugPrint('❌ تم رفض إذن الإشعارات');
      }
    } catch (e) {
      debugPrint('❌ خطأ في طلب إذن الإشعارات: $e');
    }
  }

  /// الحصول على توكن FCM وإرساله للسيرفر
  static Future<void> _getToken() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apns = await _messaging.getAPNSToken().timeout(
          const Duration(seconds: 3),
          onTimeout: () => null,
        );
        if (apns == null) {
          debugPrint('⚠️ APNs token not available on iOS (sideloaded/simulator). Skipping FCM token.');
          return;
        }
      }
      _fcmToken = await _messaging.getToken().timeout(
        const Duration(seconds: 4),
        onTimeout: () => null,
      );
      debugPrint('🔑 FCM Token: $_fcmToken');
      if (_fcmToken != null) {
        await _sendTokenToServer(_fcmToken!);
      }
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على التوكن: $e');
    }

    // الاستماع لتحديثات التوكن وإرسالها للسيرفر
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      debugPrint('🔑 FCM Token refreshed: $newToken');
      _sendTokenToServer(newToken);
    });
  }

  /// الحصول على توكن FCM الحالي
  static String? get fcmToken => _fcmToken;

  /// مزامنة التوكن يدويًا وإرساله للسيرفر (عند تسجيل الدخول)
  static Future<void> syncToken() async {
    if (_fcmToken == null) {
      await _getToken();
    } else {
      await _sendTokenToServer(_fcmToken!);
    }
  }

  /// عرض إشعار محلي/شريط تنبيه فور ورود إشعار والتطبيق مفتوح
  static void _showLocalNotification(RemoteMessage message) {
    debugPrint('📱 عرض إشعار محلي: ${message.notification?.title}');
    final title = message.notification?.title ?? message.data['title'] ?? 'إشعار جديد من بركات عدن';
    final body = message.notification?.body ?? message.data['body'] ?? '';

    final context = AppRouter.navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              const Icon(Icons.notifications_active, color: Color(0xFF38BDF8), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (body.isNotEmpty)
                      Text(
                        body,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'عرض',
            textColor: const Color(0xFF38BDF8),
            onPressed: () => _handleNotificationTap(message),
          ),
        ),
      );
    }
  }

  /// معالجة النقر على الإشعار وتوجيه المستخدم للجهة المناسبة
  static void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] ?? 'general';
    final orderId = data['order_id'];
    final route = data['route'];

    debugPrint('🔗 النقر على الإشعار: نوع=$type، طلب=$orderId، مسار=$route');

    try {
      if (orderId != null && orderId.toString().isNotEmpty) {
        // توجيه العميل إلى صفحة طلباته لمتابعة مسار شحنته
        AppRouter.router.push('/orders');
      } else if (route != null && route.toString().isNotEmpty && route != '/') {
        AppRouter.router.push(route.toString());
      } else {
        AppRouter.router.push('/notifications');
      }
    } catch (e) {
      debugPrint('❌ تعذر التوجيه من الإشعار: $e');
      try {
        AppRouter.router.push('/notifications');
      } catch (_) {}
    }
  }

  /// الاشتراك في موضوع (Topic)
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ تم الاشتراك في الموضوع: $topic');
    } catch (e) {
      debugPrint('❌ خطأ في الاشتراك: $e');
    }
  }

  /// إلغاء الاشتراك في موضوع
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ تم إلغاء الاشتراك في الموضوع: $topic');
    } catch (e) {
      debugPrint('❌ خطأ في إلغاء الاشتراك: $e');
    }
  }
}
