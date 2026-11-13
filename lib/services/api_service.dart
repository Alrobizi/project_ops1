// ============================================
// طبقة الخدمات (API Service Layer)
// جاهزة للربط مع Laravel API باستخدام Dio
// ============================================

import 'package:flutter/foundation.dart' hide Category;
import 'package:dio/dio.dart';
import 'dart:async';
import '../models/models.dart';
import '../models/notification.dart';
import '../data/dummy_data.dart';
import 'firebase_notification_service.dart';

/// صفحة واحدة من قائمة الإشعارات (تدعم التحميل التدريجي والترقيم)
class NotificationPage {
  const NotificationPage({
    required this.notifications,
    required this.unreadCount,
    required this.page,
    required this.lastPage,
    required this.total,
  });

  final List<AppNotification> notifications;
  final int unreadCount;
  final int page;
  final int lastPage;
  final int total;

  /// هل توجد صفحات إضافية لم تُحمَّل بعد؟
  bool get hasMore => page < lastPage;
}

/// كلاس ApiClient يغلف Dio مع interceptor للتوكن
class ApiClient {
  /// رابط السيرفر السحابي المباشر (Render)
  static const String baseUrl = 'https://barakat-aden.onrender.com/api';
  static const String serverUrl = 'https://barakat-aden.onrender.com';

  static const bool useDummyData =
      false; // تغيير إلى true للعمل بالبيانات التجريبية بدون سيرفر

  late final Dio _dio;

  /// توكن المصادقة المشترك بين جميع نسخ ApiClient.
  /// بعض الخدمات (مثل إشعارات FCM) تُنشئ نسخة خاصة قبل تسجيل الدخول،
  /// ولو كان الحقل خاصاً بكل نسخة لبقي التوكن مفقوداً فيها.
  static String? _token;

  // ============================================
  // إعدادات الشبكة — مضبوطة على استضافة Render
  // ============================================
  //
  // Render (الخطة المجانية) يُنيم الخدمة بعد ~15 دقيقة خمول، وأول طلب بعد
  // النوم ينتظر 30–60 ثانية حتى تُقلع الحاوية (cold start)، وأحياناً يرد
  // بروكسي Render بـ 502/503 قبل أن يجهز التطبيق. لذلك:
  //   • receiveTimeout طويل لأن الخادم يستقبل الاتصال فوراً ثم يتأخّر بالرد.
  //   • الطلبات الآمنة الإعادة (GET وتوكن FCM) تُعاد تلقائياً عند 502/503/504
  //     أو عند مهلة الاستجابة، بدل إظهار خطأ لمستخدم لم يفعل شيئاً.

  static const Duration connectTimeout = Duration(seconds: 20);

  /// يجب أن يبقى أطول من إقلاع Render وأقصر من صبر المستخدم على شاشة معلّقة
  static const Duration receiveTimeout = Duration(seconds: 60);

  /// عدد محاولات GET (الأصلية + إعادة واحدة)
  ///
  /// محاولتان فقط: إعادة كافية لتجاوز 502 لحظة الإقلاع، ولا تُطيل انتظار
  /// المستخدم دقائق إن كان الخادم متوقفاً فعلاً (كل محاولة تنتظر حتى 60s).
  static const int _getAttempts = 2;

  /// انتظار بين المحاولات — الطلب الثاني غالباً يسبق الخادم وهو مُقلع
  static const List<Duration> _retryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 5),
  ];

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    // Interceptor لإرفاق التوكن في كل طلب
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // إذا انتهت صلاحية التوكن أو كان غير صالح - تسجيل الخروج التلقائي
        if (error.response?.statusCode == 401) {
          _token = null;
        }
        return handler.next(error);
      },
    ));
  }

  void setToken(String token) {
    _token = token;
    setFcmApiClient(this);
    FirebaseNotificationService.syncToken();
  }

  void clearToken() => _token = null;

  /// التوكن الحالي (يُستخدم عند استعادة بيانات المستخدم بعد إعادة التشغيل)
  String? get token => _token;

  /// هل الخطأ عابر (خادم Render ما زال يُقلع / بطء مؤقت) ويستحق إعادة الطلب؟
  ///
  /// لا نُعيد المحاولة على أخطاء الشبكة الحقيقية (لا إنترنت، فشل DNS)،
  /// حتى لا ينتظر المستخدم دقيقة كاملة ليعرف أن اتصاله مقطوع.
  static bool _isTransient(Object error) {
    if (error is! DioException) {
      return false;
    }

    if (error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return true;
    }

    if (error.type == DioExceptionType.badResponse) {
      final status = error.response?.statusCode;
      // 502/503/504 هي ردود بروكسي Render أثناء إقلاع الخدمة أو انشغالها
      return status == 502 || status == 503 || status == 504;
    }

    return false;
  }

  /// طلب GET — يُعاد تلقائياً إن كان الخادم ما زال يُقلع على Render.
  ///
  /// GET آمن للإعادة (idempotent) بخلاف POST/PATCH، لذلك لا نُعيد الطلبات
  /// المُعدِّلة هنا حتى لا يتكرّر إنشاء طلب شراء أو خصم محفظة مرتين.
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParams,
    int attempts = _getAttempts,
  }) async {
    final total = attempts < 1 ? 1 : attempts;

    for (var attempt = 1;; attempt++) {
      try {
        return await _dio.get(path, queryParameters: queryParams);
      } on DioException catch (e) {
        if (attempt >= total || !_isTransient(e)) {
          rethrow;
        }

        final delay = _retryDelays[attempt - 1];
        debugPrint(
          '⏳ إعادة محاولة GET $path (${attempt + 1}/$total) بعد '
          '${delay.inSeconds}s — '
          '${e.response?.statusCode ?? e.type.name}',
        );
        await Future<void>.delayed(delay);
      }
    }
  }

  /// إيقاظ الخادم في الخلفية قبل أول تفاعل للمستخدم.
  ///
  /// على Render ننام 15 دقيقة بعد آخر طلب، فإذا فتح المستخدم التطبيق بعد
  /// ساعة فإن أول طلب (تسجيل الدخول مثلاً) يدفع كامل زمن الإقلاع. إرسال
  /// طلب خفيف على نقطة عامة أثناء ظهور شاشة الدخول يجعل الإقلاع يحدث
  /// بالتوازي مع كتابة المستخدم لبياناته بدل أن ينتظره.
  ///
  /// لا ننتظر النتيجة ولا نُظهر أي خطأ — فشله لا يعني شيئاً.
  static void warmUp() {
    if (useDummyData) {
      return;
    }

    final dio = Dio(BaseOptions(
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: {'Accept': 'application/json'},
    ));

    unawaited(() async {
      try {
        await dio.get<dynamic>('$serverUrl/api/settings');
      } catch (_) {
        // مجرّد محاولة إيقاظ — أي استجابة (حتى خطأ) تعني أن الخدمة تعمل
      } finally {
        dio.close(force: true);
      }
    }());
  }

  // POST request
  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  // PATCH request
  Future<Response> patch(String path, {dynamic data}) async {
    return await _dio.patch(path, data: data);
  }

  // PUT request
  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  // DELETE request
  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }

  /// جلب الإعدادات العامة للمتجر من لوحة التحكم (مثل رقم الواتساب المخصص لاستلام الحوالات)
  Future<Map<String, dynamic>?> getPublicSettings() async {
    try {
      final response = await get('/settings');
      if (response.data != null && response.data['data'] != null) {
        return Map<String, dynamic>.from(response.data['data']);
      }
    } catch (_) {
      // يتم الرجوع للإعدادات المحلية كبديل عند تعذر الاتصال
    }
    return null;
  }

  /// إرسال توكن FCM للسيرفر (يتطلب تسجيل الدخول)
  ///
  /// يُرجع `true` عند نجاح الحفظ حتى نتمكن من تجنّب إعادة الإرسال
  /// في كل مرة يُفتح فيها التطبيق (انظر FirebaseNotificationService).
  ///
  /// يعمل في الخلفية بلا واجهة، لذا يُسمح له بمحاولات متعددة (مهلة 60s
  /// وفواصل إعادة) ليتجاوز إقلاع Render البطيء بدل أن يضيع توكن الجهاز
  /// ويبقى المستخدم بلا إشعارات طوال الجلسة.
  Future<bool> sendFcmToken(String fcmToken) async {
    if (_token == null || _token!.isEmpty) {
      debugPrint('⚠️ تخطي إرسال توكن FCM لعدم وجود توكن مصادقة حالي للمستخدم');
      return false;
    }

    const maxAttempts = 3;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final res = await _dio.post(
          '/user/fcm-token',
          data: {'fcm_token': fcmToken},
          options: Options(
            receiveTimeout: receiveTimeout,
            sendTimeout: const Duration(seconds: 30),
          ),
        );
        final status = res.statusCode ?? 0;
        debugPrint('✅ تم حفظ توكن FCM في حساب المستخدم بنجاح: $status');
        return status >= 200 && status < 300;
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        final retryable = attempt < maxAttempts && _isTransient(e);

        debugPrint(
          '❌ خطأ في إرسال توكن FCM للسيرفر: $status ${e.message} '
          '(محاولة $attempt/$maxAttempts)',
        );

        // 401/422/500 أخطاء حقيقية: إعادة المحاولة لن تغيّر النتيجة
        if (!retryable) {
          return false;
        }

        await Future<void>.delayed(_retryDelays[attempt - 1]);
      } catch (e) {
        debugPrint('❌ خطأ في إرسال توكن FCM للسيرفر: $e');
        return false;
      }
    }

    return false;
  }

  /// حذف توكن FCM من حساب المستخدم الحالي (قبل تسجيل الخروج)
  ///
  /// يمنع وصول إشعارات هذا الحساب إلى جهاز استخدمه شخص آخر بعد الخروج.
  /// على Render قد يفشل هذا الطلب أثناء نوم الخدمة، لكن الحماية لا تعتمد
  /// عليه وحده: الخادم يفصل التوكن أيضاً عند `POST /logout`، وعند ربط نفس
  /// التوكن بحساب آخر يُفصل تلقائياً عن الحساب السابق.
  Future<void> clearFcmToken() async {
    if (_token == null || _token!.isEmpty) {
      return;
    }

    try {
      await _dio.delete(
        '/user/fcm-token',
        options: Options(
          receiveTimeout: receiveTimeout,
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      debugPrint('✅ تم حذف توكن FCM من الحساب');
    } catch (e) {
      debugPrint('⚠️ تعذّر حذف توكن FCM من السيرفر: $e');
    }
  }

  /// جلب الإشعارات الخاصة بالمستخدم (مع تقسيم الصفحات)
  Future<NotificationPage> getNotifications({int page = 1}) async {
    final response = await get('/notifications', queryParams: {'page': page});
    final body = response.data;

    final raw = (body is Map && body['data'] is List)
        ? body['data'] as List
        : const <dynamic>[];

    final meta = (body is Map && body['meta'] is Map)
        ? Map<String, dynamic>.from(body['meta'] as Map)
        : const <String, dynamic>{};

    final notifications = <AppNotification>[];
    for (final item in raw) {
      if (item is Map) {
        final parsed = AppNotification.fromJson(
          Map<String, dynamic>.from(item),
        );
        if (parsed != null) {
          notifications.add(parsed);
        }
      }
    }

    return NotificationPage(
      notifications: notifications,
      unreadCount: _asInt(body is Map ? body['unread_count'] : null),
      page: _asInt(meta['current_page'], fallback: page),
      lastPage: _asInt(meta['last_page'], fallback: page),
      total: _asInt(meta['total']),
    );
  }

  /// تعليم إشعار كمقروء — يُرجع false إذا فشل الطلب
  /// (لتتمكن الواجهة من التراجع عن التحديث المتفائل)
  Future<bool> markNotificationAsRead(String id) async {
    try {
      await patch('/notifications/$id/read');
      return true;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // مقروء مسبقاً أو غير موجود: لا حاجة للتراجع في الواجهة
      if (status == 404 || status == 409) {
        return true;
      }
      debugPrint('❌ تعذّر تعليم الإشعار كمقروء: $status ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ تعذّر تعليم الإشعار كمقروء: $e');
      return false;
    }
  }

  /// تعليم كل الإشعارات كمقروءة — يُرجع false إذا فشل الطلب
  Future<bool> markAllNotificationsAsRead() async {
    try {
      await post('/notifications/read-all');
      return true;
    } catch (e) {
      debugPrint('❌ تعذّر تعليم كل الإشعارات كمقروءة: $e');
      return false;
    }
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  /// بدء عملية الدفع بالمحفظة
  Future<Map<String, dynamic>> initiateWalletPayment({
    required String orderId,
    required String walletCode,
  }) async {
    final response = await post('/payments/initiate', data: {
      'order_id': int.parse(orderId),
      'wallet_code': walletCode,
    });
    return Map<String, dynamic>.from(response.data['data']);
  }

  /// فحص حالة الطلب لعملية الـ Polling
  Future<Map<String, dynamic>> getOrderStatus(String orderId) async {
    final response = await get('/orders/$orderId/status');
    return Map<String, dynamic>.from(response.data['data']);
  }

  /// التحويل لـ الدفع عند الاستلام
  Future<Map<String, dynamic>> switchToCod(String orderId) async {
    final response = await post('/orders/$orderId/switch-to-cod');
    return Map<String, dynamic>.from(response.data['data']);
  }

  /// محاكاة نتيجة الدفع للاختبار
  Future<void> mockWebhook({
    required String orderId,
    required String action,
  }) async {
    await post('/payments/mock-webhook', data: {
      'order_id': int.parse(orderId),
      'action': action,
    });
  }
}

/// خدمة المصادقة
class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  /// تسجيل الدخول
  Future<User> login(String email, String password) async {
    if (ApiClient.useDummyData) {
      // محاكاة تأخير الشبكة
      await Future.delayed(const Duration(seconds: 1));

      // التحقق من البيانات
      if (email == 'test@test.com' && password == '123456') {
        return DummyData.currentUser;
      }
      throw Exception('بيانات الدخول غير صحيحة');
    }

    // الربط الحقيقي مع Laravel
    try {
      final response = await _apiClient.post('/login', data: {
        'email': email,
        'password': password,
      });
      final data = response.data['data'];
      final userJson = Map<String, dynamic>.from(data['user']);
      userJson['token'] = data['token'];
      _apiClient.setToken(data['token']);
      return User.fromJson(userJson);
    } on DioException catch (e) {
      // استخراج رسالة الخطأ الواضحة من ردّ الخادم
      final data = e.response?.data;
      if (data is Map) {
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) {
            throw Exception(first.first.toString());
          }
        }
        if (data['message'] != null) {
          throw Exception(data['message'].toString());
        }
      }
      throw Exception('تعذّر الاتصال بالخادم، تحقق من الاتصال وحاول مجدداً');
    }
  }

  /// تعيين توكن المصادقة يدوياً (عند استعادة الجلسة)
  void setToken(String token) => _apiClient.setToken(token);

  /// حذف توكن المصادقة (عند انتهاء الجلسة أو رفض التوكن)
  void clearToken() => _apiClient.clearToken();

  /// جلب بيانات المستخدم الحالي من الخادم.
  /// تشمل `role` و`admin_permissions`، لذلك تُستخدم لاستعادة الصلاحيات
  /// بعد إعادة تشغيل التطبيق بدلاً من الاعتماد على التوكن وحده.
  Future<User> getCurrentUser() async {
    if (ApiClient.useDummyData) {
      return DummyData.currentUser;
    }

    final response = await _apiClient.get('/user');
    final userJson = Map<String, dynamic>.from(response.data['data']);
    userJson['token'] = _apiClient.token;
    return User.fromJson(userJson);
  }

  /// إنشاء حساب
  Future<User> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (ApiClient.useDummyData) {
      await Future.delayed(const Duration(seconds: 1));
      return DummyData.currentUser;
    }

    final response = await _apiClient.post('/register', data: {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'password_confirmation': password,
    });
    final data = response.data['data'];
    final userJson = Map<String, dynamic>.from(data['user']);
    userJson['token'] = data['token'];
    _apiClient.setToken(data['token']);
    return User.fromJson(userJson);
  }

  /// تسجيل الدخول بواسطة Google
  Future<User> loginWithGoogle({
    String? idToken,
    String? accessToken,
    required String email,
    required String name,
    required String googleId,
    String? avatar,
  }) async {
    if (ApiClient.useDummyData) {
      await Future.delayed(const Duration(seconds: 1));
      return DummyData.currentUser;
    }

    final response = await _apiClient.post('/google-login', data: {
      // بيانات التحقق التي يعتمد عليها الخادم (يتحقق منها مع Google مباشرة).
      // على أندرويد/iOS يكون id_token متوفراً، وعلى الويب يكون access_token.
      if (idToken != null) 'id_token': idToken,
      if (accessToken != null) 'access_token': accessToken,
      // حقول إضافية للتوافق مع نسخ الخادم الأقدم — الخادم الحالي يتجاهلها
      'email': email,
      'name': name,
      'google_id': googleId,
      if (avatar != null) 'avatar': avatar,
    });
    final data = response.data['data'];
    final userJson = Map<String, dynamic>.from(data['user']);
    userJson['token'] = data['token'];
    _apiClient.setToken(data['token']);
    return User.fromJson(userJson);
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    try {
      if (!ApiClient.useDummyData) {
        // ١) فصل الجهاز عن الحساب: حذف توكن FCM قبل إبطال توكن المصادقة
        //    (وإلا ظل الجهاز يستقبل إشعارات هذا الحساب بعد خروج المستخدم)
        await FirebaseNotificationService.unregisterFromServer();
        // ٢) إبطال جلسة السيرفر
        await _apiClient.post('/logout');
      }
    } catch (_) {
      // نتجاهل أخطاء الخادم عند تسجيل الخروج حتى لا يتعطل تسجيل الخروج من التطبيق
    } finally {
      _apiClient.clearToken();
    }
  }

  /// تحديث الملف الشخصي للمستخدم
  Future<User> updateProfile({
    String? name,
    String? phone,
    String? email,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    if (email != null) data['email'] = email;

    final response = await _apiClient.put('/user', data: data);
    final userJson = Map<String, dynamic>.from(response.data['data']);
    userJson['token'] = _apiClient.token;
    return User.fromJson(userJson);
  }
}

/// خدمة المنتجات
class ProductService {
  final ApiClient _apiClient;

  ProductService(this._apiClient);

  /// جلب كل المنتجات
  Future<List<Product>> getProducts({String? categoryId}) async {
    if (ApiClient.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (categoryId != null) {
        return DummyData.products
            .where((p) => p.categoryId == categoryId)
            .toList();
      }
      return DummyData.products;
    }

    final response = await _apiClient.get('/products', queryParams: {
      if (categoryId != null) 'category_id': categoryId,
    });
    return (response.data['data'] as List)
        .map((e) => Product.fromJson(e))
        .toList();
  }

  /// جلب منتج واحد
  Future<Product> getProduct(String id) async {
    if (ApiClient.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 300));
      return DummyData.products.firstWhere((p) => p.id == id);
    }

    final response = await _apiClient.get('/products/$id');
    return Product.fromJson(response.data['data']);
  }

  /// جلب الأفضل مبيعاً
  Future<List<Product>> getBestSellers() async {
    if (ApiClient.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 300));
      return DummyData.products.where((p) => p.isBestSeller).toList();
    }

    final response = await _apiClient.get('/products', queryParams: {
      'best_seller': true,
    });
    return (response.data['data'] as List)
        .map((e) => Product.fromJson(e))
        .toList();
  }
}

/// خدمة التصنيفات
class CategoryService {
  final ApiClient _apiClient;

  CategoryService(this._apiClient);

  Future<List<Category>> getCategories() async {
    if (ApiClient.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 300));
      return DummyData.categories;
    }

    final response = await _apiClient.get('/categories');
    return (response.data['data'] as List)
        .map((e) => Category.fromJson(e))
        .toList();
  }

  Future<List<Category>> getMarketingSections() async {
    if (ApiClient.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 300));
      return DummyData.marketingSections;
    }

    final response = await _apiClient.get('/categories/marketing');
    return (response.data['data'] as List)
        .map((e) => Category.fromJson(e))
        .toList();
  }

  Future<Category> getCategory(String id) async {
    if (ApiClient.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 300));
      return DummyData.categories.firstWhere(
        (c) => c.id == id,
        orElse: () => Category(id: '', name: '', icon: ''),
      );
    }

    final response = await _apiClient.get('/categories/$id');
    return Category.fromJson(response.data['data']);
  }
}

/// خدمة الطلبات
class OrderService {
  final ApiClient _apiClient;

  OrderService(this._apiClient);

  /// جلب طلبات المستخدم
  Future<List<Order>> getOrders() async {
    if (ApiClient.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return DummyData.orders;
    }

    try {
      final response = await _apiClient.get('/orders');
      final data = response.data['data'];
      if (data == null || data is! List) return [];
      return data.map((e) => Order.fromJson(e)).toList();
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401) {
        throw Exception('انتهت جلسة تسجيل الدخول، يرجى إعادة تسجيل الدخول');
      }
      if (code == 422) {
        throw Exception('خطأ في البيانات المرسلة، يرجى إعادة المحاولة');
      }
      throw Exception('تعذر تحميل الطلبات، تحقق من الاتصال وأعد المحاولة');
    }
  }

  /// جلب طلب واحد
  Future<Order> getOrder(String id) async {
    if (ApiClient.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 300));
      return DummyData.orders.firstWhere((o) => o.id == id);
    }

    final response = await _apiClient.get('/orders/$id');
    return Order.fromJson(response.data['data']);
  }

  /// إنشاء طلب جديد
  Future<Order> createOrder({
    required List<CartItem> items,
    required Address address,
    required String paymentMethod,
    String? orderType,
  }) async {
    final type = orderType ??
        (paymentMethod.contains('أم فلوس')
            ? 'حوالة - محفظة أم فلوس'
            : paymentMethod.contains('القطيبي')
                ? 'حوالة - محفظة القطيبي'
                : paymentMethod.contains('حوالة')
                    ? 'إرسال حوالة مباشرة'
                    : 'طلب شراء عادي');

    if (ApiClient.useDummyData) {
      await Future.delayed(const Duration(seconds: 1));

      final subtotal = items.fold<double>(
        0,
        (sum, item) => sum + item.totalPrice,
      );
      final shipping = subtotal >= 200 ? 0.0 : 25.0;

      return Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        orderNumber:
            'ORD-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        orderType: type,
        date: DateTime.now(),
        items: items,
        subtotal: subtotal,
        shipping: shipping,
        total: subtotal + shipping,
        status: OrderStatus.pending,
        address: address,
        paymentMethod: paymentMethod,
      );
    }

    final addressId = int.tryParse(address.id);
    final response = await _apiClient.post('/orders', data: {
      'items': items
          .map((e) => {
                'product_id': int.tryParse(e.product.id) ?? e.product.id,
                'quantity': e.quantity,
                if (e.selectedColor.isNotEmpty) 'color': e.selectedColor,
                if (e.selectedSize.isNotEmpty) 'size': e.selectedSize,
              })
          .toList(),
      if (addressId != null) 'address_id': addressId,
      'address': {
        'governorate': address.governorate,
        'city': address.city,
        'district': address.district,
        'street': address.street,
        'phone': address.phone,
        'latitude': address.latitude,
        'longitude': address.longitude,
        'is_gps_location': address.isGpsLocation,
      },
      'payment_method': paymentMethod,
      'order_type': type,
    });
    return Order.fromJson(response.data['data']);
  }
}

/// خدمة الإدارة (Admin) - تتصل بالسيرفر الحقيقي
class AdminService {
  final ApiClient _apiClient;

  AdminService(this._apiClient);

  /// جلب بيانات الإحصائيات للوحة التحكم من السيرفر
  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _apiClient.get('/admin/dashboard');
    return Map<String, dynamic>.from(response.data['data']);
  }

  /// جلب قائمة العملاء من السيرفر (لاختيار مستخدم معين للإشعار)
  Future<List<Map<String, dynamic>>> getCustomers() async {
    final response = await _apiClient.get('/admin/customers');
    final List data = response.data['data'] as List;
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// إرسال إشعار عبر السيرفر (لمستخدم معين عبر userId أو لجميع المستخدمين إذا كان null)
  Future<Map<String, dynamic>> sendNotification({
    required String title,
    String body = '',
    String type = 'general',
    int? userId,
  }) async {
    final response = await _apiClient.post('/admin/notifications', data: {
      'title': title,
      'body': body,
      'type': type,
      if (userId != null) 'user_id': userId,
    });
    return Map<String, dynamic>.from(response.data);
  }
}

/// خدمة البانرات (Banners)
/// - للعميل: GET /banners (بدون توكن)
/// - للأدمن: GET/POST /admin/banners, DELETE /admin/banners/{id}, PATCH /admin/banners/{id}/toggle
class BannerService {
  final ApiClient _apiClient;

  BannerService(this._apiClient);

  /// جلب البانرات المفعّلة للعميل (مرتبة حسب sort_order)
  Future<List<Map<String, dynamic>>> getBanners() async {
    if (ApiClient.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 300));
      return [
        {
          'id': 1,
          'title': 'تخفيضات الصيف',
          'image': '',
          'link': '',
          'sort_order': 1
        },
        {
          'id': 2,
          'title': 'منتجات جديدة',
          'image': '',
          'link': '',
          'sort_order': 2
        },
      ];
    }

    final response = await _apiClient.get('/banners');
    final List data = response.data['data'] as List? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// جلب كل البانرات للوحة التحكم (الأدمن)
  Future<List<Map<String, dynamic>>> getAdminBanners() async {
    if (ApiClient.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 300));
      return [
        {
          'id': 1,
          'title': 'تخفيضات الصيف',
          'image': '',
          'link': '/summer-sale',
          'sort_order': 1,
          'is_active': true
        },
        {
          'id': 2,
          'title': 'منتجات جديدة',
          'image': '',
          'link': '/new-arrivals',
          'sort_order': 2,
          'is_active': true
        },
        {
          'id': 3,
          'title': 'عرض الجمعة',
          'image': '',
          'link': '/friday-deals',
          'sort_order': 3,
          'is_active': false
        },
      ];
    }

    final response = await _apiClient.get('/admin/banners');
    final List data = response.data['data'] as List? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// إضافة بانر جديد (الأدمن)
  Future<Map<String, dynamic>> createBanner({
    required String title,
    String link = '',
    String? image,
  }) async {
    final response = await _apiClient.post('/admin/banners', data: {
      'title': title,
      'link': link,
      if (image != null && image.isNotEmpty) 'image': image,
      'is_active': true,
    });
    return Map<String, dynamic>.from(response.data['data']);
  }

  /// حذف بانر (الأدمن)
  Future<void> deleteBanner(String id) async {
    await _apiClient.delete('/admin/banners/$id');
  }

  /// تفعيل/إيقاف بانر (الأدمن)
  Future<Map<String, dynamic>> toggleBanner(String id) async {
    final response = await _apiClient.patch('/admin/banners/$id/toggle');
    return Map<String, dynamic>.from(response.data['data']);
  }
}

/// استخراج رسالة الخطأ الواضحة من ردّ الخادم
String extractApiErrorMessage(dynamic error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          return first.first.toString();
        }
      }
      if (data['message'] != null) {
        return data['message'].toString();
      }
    }
    if (error.response?.statusCode == 403) {
      return 'ليس لديك صلاحية لإجراء هذه العملية';
    }
  }
  return 'تعذّر الاتصال بالخادم، تحقق من الاتصال وحاول مجدداً';
}

/// خدمة إدارة المنتجات والتصنيفات (لوحة التحكم)
/// تتطلب صلاحية "products" — GET/POST/PUT/DELETE /admin/products و /admin/categories
class AdminProductService {
  final ApiClient _apiClient;

  AdminProductService(this._apiClient);

  /// جلب كل المنتجات مع دعم البحث والفلترة بالتصنيف
  Future<List<Product>> getProducts({
    String? categoryId,
    String? search,
  }) async {
    if (ApiClient.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 300));
      var list = List<Product>.from(DummyData.products);
      if (categoryId != null && categoryId.isNotEmpty) {
        list = list.where((p) => p.categoryId == categoryId).toList();
      }
      if (search != null && search.trim().isNotEmpty) {
        final q = search.trim();
        list = list
            .where((p) => p.name.contains(q) || p.description.contains(q))
            .toList();
      }
      return list;
    }

    final response = await _apiClient.get('/admin/products', queryParams: {
      if (categoryId != null && categoryId.isNotEmpty)
        'category_id': categoryId,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      'per_page': 100,
    });
    return (response.data['data'] as List)
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// إضافة منتج جديد
  Future<Product> createProduct({
    required String name,
    required double price,
    required String categoryId,
    String description = '',
    double? oldPrice,
    String currency = 'YER',
    String? image,
    int stock = 0,
    bool isActive = true,
    bool isFeatured = false,
  }) async {
    if (ApiClient.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 300));
      final product = Product(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        description: description,
        price: price,
        oldPrice: oldPrice,
        currency: currency,
        image: image ?? '',
        categoryId: categoryId,
        stock: stock,
        isBestSeller: isFeatured,
      );
      DummyData.products.insert(0, product);
      return product;
    }

    final response = await _apiClient.post('/admin/products', data: {
      'category_id': int.parse(categoryId),
      'name': name,
      'description': description,
      'price': price,
      if (oldPrice != null) 'old_price': oldPrice,
      'currency': currency,
      if (image != null && image.isNotEmpty) 'image': image,
      'stock': stock,
      'is_active': isActive,
      'is_featured': isFeatured,
    });
    return Product.fromJson(Map<String, dynamic>.from(response.data['data']));
  }

  /// تعديل منتج (الاسم، السعر، التصنيف، المخزون...)
  Future<Product> updateProduct(String id, Map<String, dynamic> data) async {
    if (ApiClient.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 300));
      final index = DummyData.products.indexWhere((p) => p.id == id);
      if (index != -1) {
        final old = DummyData.products[index];
        final updated = Product(
          id: old.id,
          name: data['name'] ?? old.name,
          description: data['description'] ?? old.description,
          price: (data['price'] as num?)?.toDouble() ?? old.price,
          oldPrice: data.containsKey('old_price')
              ? (data['old_price'] as num?)?.toDouble()
              : old.oldPrice,
          currency: data['currency'] ?? old.currency,
          image: data['image'] ?? old.image,
          images: old.images,
          categoryId: data['category_id']?.toString() ?? old.categoryId,
          rating: old.rating,
          reviewsCount: old.reviewsCount,
          stock: (data['stock'] as num?)?.toInt() ?? old.stock,
          colors: old.colors,
          sizes: old.sizes,
          isFavorite: old.isFavorite,
          isBestSeller: data['is_featured'] ?? old.isBestSeller,
        );
        DummyData.products[index] = updated;
        return updated;
      }
      throw Exception('المنتج غير موجود');
    }

    final response = await _apiClient.put('/admin/products/$id', data: data);
    return Product.fromJson(Map<String, dynamic>.from(response.data['data']));
  }

  /// حذف منتج
  Future<void> deleteProduct(String id) async {
    if (ApiClient.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 300));
      DummyData.products.removeWhere((p) => p.id == id);
      return;
    }

    await _apiClient.delete('/admin/products/$id');
  }

  /// جلب قائمة التصنيفات (للالاختيار عند إضافة منتج)
  Future<List<Map<String, dynamic>>> getCategories() async {
    if (ApiClient.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 200));
      return DummyData.categories
          .map((c) => {
                'id': c.id,
                'name': c.name,
                'parent_id': null,
                'type': c.type,
                'is_active': c.isActive,
                'products_count': c.productsCount ?? 0,
              })
          .toList();
    }

    final response = await _apiClient.get('/admin/categories');
    final List data = response.data['data'] as List? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// إضافة تصنيف جديد
  Future<Map<String, dynamic>> createCategory({
    required String name,
    String type = 'main',
    String? parentId,
    String? icon,
  }) async {
    final response = await _apiClient.post('/admin/categories', data: {
      'name': name,
      'type': type,
      if (parentId != null && parentId.isNotEmpty) 'parent_id': parentId,
      if (icon != null && icon.isNotEmpty) 'icon': icon,
    });
    return Map<String, dynamic>.from(response.data['data']);
  }

  /// تعديل تصنيف
  Future<Map<String, dynamic>> updateCategory(
      String id, Map<String, dynamic> data) async {
    final response = await _apiClient.put('/admin/categories/$id', data: data);
    return Map<String, dynamic>.from(response.data['data']);
  }

  /// حذف تصنيف
  Future<void> deleteCategory(String id) async {
    await _apiClient.delete('/admin/categories/$id');
  }
}
