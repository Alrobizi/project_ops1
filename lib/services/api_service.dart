// ============================================
// طبقة الخدمات (API Service Layer)
// جاهزة للربط مع Laravel API باستخدام Dio
// ============================================

import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/models.dart';
import '../models/notification.dart';
import '../data/dummy_data.dart';

/// كلاس ApiClient يغلف Dio مع interceptor للتوكن
class ApiClient {
  /// IP السيرفر على الشبكة المحلية (للجوال الحقيقي المتصل بنفس الشبكة).
  /// للمحاكي (Emulator) استبدل هذا الثابت بـ '10.0.2.2'.
  static const String serverHost = '192.168.100.15';

  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      // إذا كان يعمل على محاكي أندرويد
      return 'http://10.0.2.2:8009/api';
    }
    return 'http://$serverHost:8009/api';
  }

  static const bool useDummyData =
      false; // تغيير إلى true للعمل بالبيانات التجريبية بدون سيرفر

  late final Dio _dio;
  String? _token;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
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
        // معالجة الأخطاء هنا
        return handler.next(error);
      },
    ));
  }

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;

  // GET request
  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) async {
    return await _dio.get(path, queryParameters: queryParams);
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
  Future<void> sendFcmToken(String fcmToken) async {
    try {
      await _dio.post('/user/fcm-token', data: {'fcm_token': fcmToken});
    } catch (e) {
      // تجاهل الخطأ إذا لم يكن المستخدم مسجلاً دخوله
    }
  }

  /// جلب الإشعارات الخاصة بالمستخدم
  Future<Map<String, dynamic>> getNotifications() async {
    final response = await get('/notifications');
    return {
      'notifications': (response.data['data'] as List)
          .map((e) => AppNotification.fromJson(e))
          .toList(),
      'unread_count': response.data['unread_count'] ?? 0,
    };
  }

  /// تعليم إشعار كمقروء
  Future<void> markNotificationAsRead(String id) async {
    await patch('/notifications/$id/read');
  }

  /// تعليم كل الإشعارات كمقروءة
  Future<void> markAllNotificationsAsRead() async {
    await post('/notifications/read-all');
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
        await _apiClient.post('/logout');
      }
    } catch (_) {
      // نتجاهل أخطاء الخادم عند تسجيل الخروج حتى لا يتعطل تسجيل الخروج من التطبيق
    } finally {
      _apiClient.clearToken();
    }
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

    final response = await _apiClient.get('/orders');
    return (response.data['data'] as List)
        .map((e) => Order.fromJson(e))
        .toList();
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

    final response = await _apiClient.post('/orders', data: {
      'items': items
          .map((e) => {
                'product_id': int.parse(e.product.id),
                'quantity': e.quantity,
                if (e.selectedColor.isNotEmpty) 'color': e.selectedColor,
                if (e.selectedSize.isNotEmpty) 'size': e.selectedSize,
              })
          .toList(),
      'address_id': int.parse(address.id),
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
        {'id': 1, 'title': 'تخفيضات الصيف', 'image': '', 'link': '', 'sort_order': 1},
        {'id': 2, 'title': 'منتجات جديدة', 'image': '', 'link': '', 'sort_order': 2},
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
        {'id': 1, 'title': 'تخفيضات الصيف', 'image': '', 'link': '/summer-sale', 'sort_order': 1, 'is_active': true},
        {'id': 2, 'title': 'منتجات جديدة', 'image': '', 'link': '/new-arrivals', 'sort_order': 2, 'is_active': true},
        {'id': 3, 'title': 'عرض الجمعة', 'image': '', 'link': '/friday-deals', 'sort_order': 3, 'is_active': false},
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
    return Product.fromJson(
        Map<String, dynamic>.from(response.data['data']));
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
    return Product.fromJson(
        Map<String, dynamic>.from(response.data['data']));
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
