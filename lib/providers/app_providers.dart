// ============================================
// إدارة الحالة (State Management) باستخدام Riverpod
// Auth, Cart, Wishlist, Orders
// ============================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart' show DioException, DioExceptionType;
import 'package:firebase_messaging/firebase_messaging.dart' show RemoteMessage;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';
import '../models/admin_models.dart';
import '../models/notification.dart';
import '../core/theme/app_colors.dart';
import '../core/auth/google_auth_config.dart';
import '../core/location/app_locations.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/firebase_notification_service.dart';

// ============================================
// Providers للخدمات
// ============================================

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  setFcmApiClient(client);
  return client;
});
final authServiceProvider =
    Provider<AuthService>((ref) => AuthService(ref.watch(apiClientProvider)));
final productServiceProvider = Provider<ProductService>(
    (ref) => ProductService(ref.watch(apiClientProvider)));
final categoryServiceProvider = Provider<CategoryService>(
    (ref) => CategoryService(ref.watch(apiClientProvider)));
final orderServiceProvider =
    Provider<OrderService>((ref) => OrderService(ref.watch(apiClientProvider)));

// ============================================
// Auth State & Provider
// ============================================

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthNotifier(this._authService) : super(AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null || token.isEmpty) {
      return;
    }

    _authService.setToken(token);
    state = state.copyWith(isAuthenticated: true);
    FirebaseNotificationService.syncToken();

    // استعادة بيانات المستخدم نفسها (وليس التوكن فقط) حتى لا تختفي
    // صلاحيات لوحة التحكم عند إعادة تشغيل التطبيق.
    await refreshUser();
  }

  /// إعادة تحميل بيانات المستخدم الحالي وصلاحياته من الخادم.
  /// تُستدعى عند بدء التشغيل (استعادة الجلسة) ويمكن استدعاؤها بعد
  /// تعديل الصلاحيات من لوحة التحكم.
  Future<void> refreshUser() async {
    if (!state.isAuthenticated) {
      return;
    }

    try {
      final user = await _authService.getCurrentUser();
      state = state.copyWith(user: user, isAuthenticated: true);
    } on DioException catch (e) {
      // التوكن منتهٍ أو ملغى => إنهاء الجلسة المحلية
      if (e.response?.statusCode == 401) {
        try {
          await _storage.delete(key: 'auth_token');
        } catch (_) {}
        _authService.clearToken();
        state = AuthState();
      }
      // أخطاء الشبكة المؤقتة: نُبقي الجلسة ونكمل بالبيانات المتاحة
    } catch (_) {
      // نتجاهل أي خطأ آخر (تعذّر الاتصال...) ونُبقي الجلسة
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.login(email, password);
      await _storage.write(
          key: 'auth_token', value: user.token ?? 'dummy_token');
      state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: true,
      );
      FirebaseNotificationService.syncToken();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      await _storage.write(
          key: 'auth_token', value: user.token ?? 'dummy_token');
      state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final GoogleSignInAccount? googleUser =
          await _createGoogleSignIn().signIn();

      if (googleUser == null) {
        // المستخدم أغلق نافذة Google دون اختيار حساب
        state = state.copyWith(isLoading: false);
        return;
      }

      // الحصول على بيانات التحقق التي سيتأكد منها الخادم لدى Google.
      // على الويب تكون القيمة المتوفرة عادةً هي accessToken،
      // وعلى أندرويد/iOS يكون idToken متوفراً.
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null && accessToken == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'تعذر الحصول على بيانات التحقق من Google، حاول مرة أخرى',
        );
        return;
      }

      final user = await _authService.loginWithGoogle(
        idToken: idToken,
        accessToken: accessToken,
        email: googleUser.email,
        name: googleUser.displayName ?? googleUser.email.split('@').first,
        googleId: googleUser.id,
        avatar: googleUser.photoUrl,
      );

      await _storage.write(
          key: 'auth_token', value: user.token ?? 'dummy_token');
      state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: true,
      );
      FirebaseNotificationService.syncToken();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error:
            'فشل تسجيل الدخول بواسطة Google: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  /// إنشاء نسخة GoogleSignIn بإعدادات صحيحة لكل منصة.
  ///
  /// على الويب لا تدعم الحزمة serverClientId إطلاقاً (تُطلق خطأ)،
  /// ويجب تمرير clientId أو وجود وسم
  /// <meta name="google-signin-client_id"> في index.html.
  /// على أندرويد/iOS يُستخدم serverClientId ليكون معرّف توكن Google
  /// موجّهاً لخادمنا (Web client ID).
  GoogleSignIn _createGoogleSignIn() {
    return GoogleSignIn(
      clientId: kIsWeb ? GoogleAuthConfig.webClientId : null,
      serverClientId: kIsWeb ? null : GoogleAuthConfig.webClientId,
      scopes: GoogleAuthConfig.scopes,
    );
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {}

    try {
      final googleSignIn = _createGoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (_) {}

    try {
      await _storage.delete(key: 'auth_token');
    } catch (_) {}

    state = AuthState();
  }

  /// تحديث بيانات الملف الشخصي وحفظها بالسيرفر
  Future<bool> updateProfile(
      {String? name, String? phone, String? email}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedUser = await _authService.updateProfile(
        name: name,
        phone: phone,
        email: email,
      );
      state = state.copyWith(
        user: updatedUser,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

// ============================================
// Cart State & Provider
// ============================================

class CartState {
  final List<CartItem> items;
  final double subtotal;
  final double shipping;
  final double total;
  final int itemsCount;

  CartState({
    this.items = const [],
    this.subtotal = 0,
    this.shipping = 0,
    this.total = 0,
    this.itemsCount = 0,
  });

  String get currencySymbol {
    if (items.isNotEmpty) {
      return items.first.product.currencySymbol;
    }
    return 'ر.ي';
  }

  CartState copyWith({
    List<CartItem>? items,
    double? subtotal,
    double? shipping,
    double? total,
    int? itemsCount,
  }) =>
      CartState(
        items: items ?? this.items,
        subtotal: subtotal ?? this.subtotal,
        shipping: shipping ?? this.shipping,
        total: total ?? this.total,
        itemsCount: itemsCount ?? this.itemsCount,
      );
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());

  static const double freeShippingThreshold = 200;
  static const double shippingCost = 25;

  void addItem(Product product,
      {int quantity = 1, String color = '', String size = ''}) {
    final existingIndex = state.items.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.selectedColor == color &&
          item.selectedSize == size,
    );

    List<CartItem> newItems;
    if (existingIndex >= 0) {
      newItems = [...state.items];
      newItems[existingIndex] = newItems[existingIndex].copyWith(
        quantity: newItems[existingIndex].quantity + quantity,
      );
    } else {
      newItems = [
        ...state.items,
        CartItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          product: product,
          quantity: quantity,
          selectedColor: color,
          selectedSize: size,
        ),
      ];
    }

    _updateCart(newItems);
  }

  void removeItem(String itemId) {
    final newItems = state.items.where((item) => item.id != itemId).toList();
    _updateCart(newItems);
  }

  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }

    final newItems = state.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    _updateCart(newItems);
  }

  void clearCart() {
    state = CartState();
  }

  void _updateCart(List<CartItem> items) {
    final subtotal =
        items.fold<double>(0, (sum, item) => sum + item.totalPrice);
    final shipping = subtotal >= freeShippingThreshold ? 0.0 : shippingCost;
    final total = subtotal + shipping;
    final itemsCount = items.fold(0, (sum, item) => sum + item.quantity);

    state = state.copyWith(
      items: items,
      subtotal: subtotal,
      shipping: shipping,
      total: total,
      itemsCount: itemsCount,
    );
  }

  double get remainingForFreeShipping =>
      freeShippingThreshold - state.subtotal > 0
          ? freeShippingThreshold - state.subtotal
          : 0;
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

// ============================================
// Wishlist State & Provider
// ============================================

class WishlistState {
  final List<Product> items;
  final Set<String> productIds;

  WishlistState({
    this.items = const [],
    this.productIds = const {},
  });

  WishlistState copyWith({
    List<Product>? items,
    Set<String>? productIds,
  }) =>
      WishlistState(
        items: items ?? this.items,
        productIds: productIds ?? this.productIds,
      );
}

class WishlistNotifier extends StateNotifier<WishlistState> {
  WishlistNotifier() : super(WishlistState());

  void toggleFavorite(Product product) {
    if (state.productIds.contains(product.id)) {
      // إزالة من المفضلة
      final newItems = state.items.where((p) => p.id != product.id).toList();
      final newIds = {...state.productIds}..remove(product.id);
      state = state.copyWith(items: newItems, productIds: newIds);
    } else {
      // إضافة للمفضلة
      final newItems = [...state.items, product.copyWith(isFavorite: true)];
      final newIds = {...state.productIds, product.id};
      state = state.copyWith(items: newItems, productIds: newIds);
    }
  }

  bool isFavorite(String productId) => state.productIds.contains(productId);
}

final wishlistProvider =
    StateNotifierProvider<WishlistNotifier, WishlistState>((ref) {
  return WishlistNotifier();
});

// ============================================
// Orders State & Provider
// ============================================

class OrdersState {
  final List<Order> orders;
  final bool isLoading;
  final String? error;

  OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
  });

  OrdersState copyWith({
    List<Order>? orders,
    bool? isLoading,
    String? error,
  }) =>
      OrdersState(
        orders: orders ?? this.orders,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrderService _orderService;

  OrdersNotifier(this._orderService) : super(OrdersState());

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final orders = await _orderService.getOrders();
      state = state.copyWith(orders: orders, isLoading: false);
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<Order?> createOrder({
    required List<CartItem> items,
    required Address address,
    required String paymentMethod,
    String? orderType,
  }) async {
    try {
      final order = await _orderService.createOrder(
        items: items,
        address: address,
        paymentMethod: paymentMethod,
        orderType: orderType,
      );
      state = state.copyWith(orders: [order, ...state.orders]);
      return order;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  List<Order> getOrdersByStatus(OrderStatus? status) {
    if (status == null) return state.orders;
    return state.orders.where((o) => o.status == status).toList();
  }
}

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  final isAuth = ref.watch(authProvider.select((s) => s.isAuthenticated));
  final notifier = OrdersNotifier(ref.watch(orderServiceProvider));
  // جلب الطلبات فقط عند تسجيل الدخول وليس بشكل أعمى
  if (isAuth) {
    Future.microtask(() => notifier.loadOrders());
  }
  return notifier;
});

// ============================================
// Products State & Provider
// ============================================

class ProductsState {
  final List<Product> products;
  final List<Category> categories;
  final List<Category> marketingSections;
  final bool isLoading;
  final String? error;
  final String? selectedCategoryId;
  final String? selectedSubcategoryId;
  final String searchQuery;

  // ----- فلتر الموقع الجغرافي (اليمن - عدن افتراضياً + GPS) -----
  // نقطة المرجع لفرز المنتجات حسب الأقرب (Nearest First)
  final bool useGpsLocation;
  final double userLatitude;
  final double userLongitude;
  final String filterGovernorate;
  final String filterCity;

  ProductsState({
    this.products = const [],
    this.categories = const [],
    this.marketingSections = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategoryId,
    this.selectedSubcategoryId,
    this.searchQuery = '',
    this.useGpsLocation = false,
    this.userLatitude = AppLocationDefaults.defaultLatitude,
    this.userLongitude = AppLocationDefaults.defaultLongitude,
    this.filterGovernorate = AppLocationDefaults.defaultGovernorate,
    this.filterCity = AppLocationDefaults.defaultCity,
  });

  /// التصنيفات الرئيسية فقط (بدون الأقسام الفرعية)
  List<Category> get mainCategories =>
      categories.where((c) => c.isMainCategory).toList();

  /// الحصول على الأقسام الفرعية لتصنيف معين
  List<Category> getSubcategories(String? categoryId) {
    if (categoryId == null) return [];
    final category = categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => Category(id: '', name: '', icon: ''),
    );
    return category.children;
  }

  /// الحصول على التصنيف المحدد حالياً
  Category? get selectedCategory {
    if (selectedCategoryId == null) return null;
    return categories.firstWhere(
      (c) => c.id == selectedCategoryId,
      orElse: () => Category(id: '', name: '', icon: ''),
    );
  }

  ProductsState copyWith({
    List<Product>? products,
    List<Category>? categories,
    List<Category>? marketingSections,
    bool? isLoading,
    String? error,
    String? selectedCategoryId,
    String? selectedSubcategoryId,
    String? searchQuery,
    bool? useGpsLocation,
    double? userLatitude,
    double? userLongitude,
    String? filterGovernorate,
    String? filterCity,
  }) =>
      ProductsState(
        products: products ?? this.products,
        categories: categories ?? this.categories,
        marketingSections: marketingSections ?? this.marketingSections,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
        selectedSubcategoryId:
            selectedSubcategoryId ?? this.selectedSubcategoryId,
        searchQuery: searchQuery ?? this.searchQuery,
        useGpsLocation: useGpsLocation ?? this.useGpsLocation,
        userLatitude: userLatitude ?? this.userLatitude,
        userLongitude: userLongitude ?? this.userLongitude,
        filterGovernorate: filterGovernorate ?? this.filterGovernorate,
        filterCity: filterCity ?? this.filterCity,
      );
}

class ProductsNotifier extends StateNotifier<ProductsState> {
  final ProductService _productService;
  final CategoryService _categoryService;

  ProductsNotifier(this._productService, this._categoryService)
      : super(ProductsState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final categories = await _categoryService.getCategories();
      final marketingSections = await _categoryService.getMarketingSections();
      final products = await _productService.getProducts();
      state = state.copyWith(
        categories: categories,
        marketingSections: marketingSections,
        products: products,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void selectCategory(String? categoryId) {
    state = state.copyWith(
      selectedCategoryId: categoryId,
      selectedSubcategoryId: null,
    );
  }

  void selectSubcategory(String? subcategoryId) {
    state = state.copyWith(selectedSubcategoryId: subcategoryId);
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// الحصول على الأقسام الفرعية للتصنيف المحدد
  List<Category> get selectedSubcategories {
    if (state.selectedCategoryId == null) return [];
    return state.getSubcategories(state.selectedCategoryId);
  }

  /// تطبيق فلتر الموقع الجغرافي (يُستدعى من locationFilterProvider):
  /// - عند تفعيل GPS: فرز المنتجات من الأقرب لموقع المشتري أولاً
  /// - عند اختيار محافظة/مديرية: الفرز حسب المسافة من نقطة المركز
  void applyLocationFilter({
    required double? userLat,
    required double? userLng,
    required bool useGps,
    required String governorate,
    required String city,
  }) {
    state = state.copyWith(
      useGpsLocation: useGps,
      userLatitude: userLat ?? AppLocationDefaults.defaultLatitude,
      userLongitude: userLng ?? AppLocationDefaults.defaultLongitude,
      filterGovernorate: governorate,
      filterCity: city,
    );
  }

  /// المسافة بين موقع المشتري (GPS أو المدينة المختارة)
  /// وموقع البائع لمنتج معين بالكيلومترات
  double distanceToSeller(Product product) {
    return LocationService.distanceKm(
      state.userLatitude,
      state.userLongitude,
      product.sellerLatitude,
      product.sellerLongitude,
    );
  }

  List<Product> get filteredProducts {
    var result = state.products;

    // فلترة حسب القسم الفرعي إذا تم تحديده
    if (state.selectedSubcategoryId != null) {
      result = result
          .where((p) => p.categoryId == state.selectedSubcategoryId)
          .toList();
    }
    // فلترة حسب التصنيف الرئيسي وأقسامه الفرعية
    else if (state.selectedCategoryId != null) {
      final category = state.categories.firstWhere(
        (c) => c.id == state.selectedCategoryId,
        orElse: () => Category(id: '', name: '', icon: ''),
      );

      // جمع كل معرفات الأقسام الفرعية + المعرف الرئيسي
      final categoryIds = <String>{state.selectedCategoryId!};
      for (final child in category.children) {
        categoryIds.add(child.id);
      }

      result = result.where((p) => categoryIds.contains(p.categoryId)).toList();
    }

    if (state.searchQuery.isNotEmpty) {
      result = result
          .where((p) =>
              p.name.contains(state.searchQuery) ||
              p.description.contains(state.searchQuery))
          .toList();
    }

    // ----- فرز حسب الموقع الجغرافي (Location Filter) -----
    // المنتجات الأقرب لموقع المشتري (GPS أو المدينة المختارة) تظهر أولاً،
    // ثم كسر التعادل بالتقييم الأعلى.
    final userLat = state.userLatitude;
    final userLng = state.userLongitude;
    result = [...result]..sort((a, b) {
        final distA = LocationService.distanceKm(
            userLat, userLng, a.sellerLatitude, a.sellerLongitude);
        final distB = LocationService.distanceKm(
            userLat, userLng, b.sellerLatitude, b.sellerLongitude);
        final cmp = distA.compareTo(distB);
        if (cmp != 0) return cmp;
        return b.rating.compareTo(a.rating);
      });

    return result;
  }

  List<Product> get bestSellers =>
      state.products.where((p) => p.isBestSeller).toList();
}

final productsProvider =
    StateNotifierProvider<ProductsNotifier, ProductsState>((ref) {
  return ProductsNotifier(
    ref.watch(productServiceProvider),
    ref.watch(categoryServiceProvider),
  );
});

// ============================================
// Location Filter State & Provider
// فلتر الموقع الجغرافي (اليمن - عدن افتراضياً + GPS)
// ============================================

/// أنماط فلترة الموقع المدعومة:
/// - [defaultCity]: الموقع الافتراضي (عدن - كريتر) أو مدينة مختارة
/// - [gps]: موقع المستخدم الحالي عبر GPS (المنتجات الأقرب أولاً)
enum LocationFilterMode { defaultCity, gps }

class LocationFilterState {
  final LocationFilterMode mode;
  final String country;
  final String governorate;
  final String city;
  final double latitude;
  final double longitude;
  final bool isLoading;
  final String? error;

  const LocationFilterState({
    this.mode = LocationFilterMode.defaultCity,
    this.country = AppLocationDefaults.country,
    this.governorate = AppLocationDefaults.defaultGovernorate,
    this.city = AppLocationDefaults.defaultCity,
    this.latitude = AppLocationDefaults.defaultLatitude,
    this.longitude = AppLocationDefaults.defaultLongitude,
    this.isLoading = false,
    this.error,
  });

  /// وسم الموقع كما يظهر في شريط الفلتر بالواجهة
  String get label => mode == LocationFilterMode.gps
      ? 'موقعي الحالي (GPS)'
      : '$governorate - $city';

  /// هل الفلتر على الوضع الافتراضي (عدن - كريتر) دون أي تخصيص؟
  bool get isDefault =>
      mode == LocationFilterMode.defaultCity &&
      governorate == AppLocationDefaults.defaultGovernorate &&
      city == AppLocationDefaults.defaultCity;

  LocationFilterState copyWith({
    LocationFilterMode? mode,
    String? country,
    String? governorate,
    String? city,
    double? latitude,
    double? longitude,
    bool? isLoading,
    String? error,
  }) =>
      LocationFilterState(
        mode: mode ?? this.mode,
        country: country ?? this.country,
        governorate: governorate ?? this.governorate,
        city: city ?? this.city,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

/// مزود حالة فلتر الموقع:
/// يبدأ من الموقع الافتراضي (اليمن - عدن - كريتر)، ويدعم
/// "استخدام موقعي الحالي" عبر GPS، ومزامنة الفلتر مع المنتجات.
class LocationFilterNotifier extends StateNotifier<LocationFilterState> {
  final Ref _ref;

  LocationFilterNotifier(this._ref) : super(const LocationFilterState()) {
    _restoreSavedLocation();
  }

  /// استرجاع الموقع المحفوظ من آخر جلسة (أو الافتراضي عدن)
  Future<void> _restoreSavedLocation() async {
    try {
      final saved = await LocationService.loadSavedLocation();
      if (saved == null || saved.useGps) return; // الافتراضي: عدن - كريتر
      state = LocationFilterState(
        mode: LocationFilterMode.defaultCity,
        governorate: saved.governorate,
        city: saved.city,
        latitude: saved.latitude,
        longitude: saved.longitude,
      );
      _syncWithProducts();
    } catch (_) {
      // أي فشل يترك الحالة الافتراضية (عدن - كريتر)
    }
  }

  /// تفعيل "استخدام موقعي الحالي" عبر GPS:
  /// يطلب الإذن، يجلب الإحداثيات، ثم يفرز المنتجات حسب الأقرب.
  Future<bool> useGpsLocation() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await LocationService.getCurrentPosition();

    if (!result.success || result.position == null) {
      state = state.copyWith(
        isLoading: false,
        error: result.errorMessage ?? 'تعذر تحديد الموقع',
      );
      return false;
    }

    final position = result.position!;
    state = state.copyWith(
      mode: LocationFilterMode.gps,
      isLoading: false,
      error: null,
      latitude: position.latitude,
      longitude: position.longitude,
    );
    _syncWithProducts();

    // حفظ نمط GPS (المدينة تبقى آخر مدينة مختارة للعرض)
    await LocationService.persistLocation(
      useGps: true,
      governorate: state.governorate,
      city: state.city,
      latitude: position.latitude,
      longitude: position.longitude,
    );
    return true;
  }

  /// اختيار محافظة يمنية من القائمة المنسدلة (عدن أولاً)
  Future<void> selectGovernorate(String name) async {
    final location = AppLocationResolver.findGovernorate(name);
    state = state.copyWith(
      mode: LocationFilterMode.defaultCity,
      governorate: location.name,
      // عند اختيار محافظة نستخدم مركزها كنقطة مرجعية للفرز
      city: location.name == AppLocationDefaults.defaultGovernorate
          ? AppLocationDefaults.defaultCity
          : location.name,
      latitude: location.latitude,
      longitude: location.longitude,
      error: null,
    );
    _syncWithProducts();
    await _persistCurrent();
  }

  /// اختيار مدينة/مديرية (مديريات عدن الثمانية)
  Future<void> selectCity(String name) async {
    final location = AppLocationResolver.findCity(name);
    state = state.copyWith(
      mode: LocationFilterMode.defaultCity,
      city: location.name,
      latitude: location.latitude,
      longitude: location.longitude,
      error: null,
    );
    _syncWithProducts();
    await _persistCurrent();
  }

  /// الرجوع للموقع الافتراضي: اليمن - عدن - كريتر
  Future<void> resetToDefault() async {
    state = const LocationFilterState();
    _syncWithProducts();
    await _persistCurrent();
  }

  Future<void> _persistCurrent() => LocationService.persistLocation(
        useGps: state.mode == LocationFilterMode.gps,
        governorate: state.governorate,
        city: state.city,
        latitude: state.latitude,
        longitude: state.longitude,
      );

  /// مزامنة الفلتر مع مزود المنتجات (فرز الأقرب أولاً)
  void _syncWithProducts() {
    try {
      _ref.read(productsProvider.notifier).applyLocationFilter(
            userLat: state.latitude,
            userLng: state.longitude,
            useGps: state.mode == LocationFilterMode.gps,
            governorate: state.governorate,
            city: state.city,
          );
    } catch (_) {
      // مزود المنتجات قد لا يكون جاهزاً بعد - يُتجاهل بأمان
    }
  }
}

final locationFilterProvider =
    StateNotifierProvider<LocationFilterNotifier, LocationFilterState>((ref) {
  return LocationFilterNotifier(ref);
});

// ============================================
// Onboarding State
// ============================================

final onboardingCompletedProvider = StateProvider<bool>((ref) => false);

// ============================================
// Theme Color State & Provider (لون التطبيق)
// ============================================

class ThemeColorState {
  final Color primaryColor;
  final Color primaryAccent;

  ThemeColorState({
    this.primaryColor = const Color(0xFF7C3AED),
    this.primaryAccent = const Color(0xFF3B82F6),
  });

  ThemeColorState copyWith({
    Color? primaryColor,
    Color? primaryAccent,
  }) =>
      ThemeColorState(
        primaryColor: primaryColor ?? this.primaryColor,
        primaryAccent: primaryAccent ?? this.primaryAccent,
      );
}

class ThemeColorNotifier extends StateNotifier<ThemeColorState> {
  ThemeColorNotifier() : super(ThemeColorState()) {
    _loadThemeColor();
  }

  /// تطبيق اللون المختار على ألوان العلامة التجارية العامة في AppColors
  /// حتى تتغير كافة الأقسام والشاشات التي تستخدم هذه الألوان مباشرة
  void _applyToAppColors(Color color) {
    final hsl = HSLColor.fromColor(color);
    AppColors.primary = color;
    AppColors.primaryAccent =
        hsl.withLightness((hsl.lightness + 0.08).clamp(0.0, 1.0)).toColor();
    AppColors.secondaryAccent =
        hsl.withLightness((hsl.lightness + 0.20).clamp(0.0, 1.0)).toColor();
  }

  Future<void> _loadThemeColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final colorVal = prefs.getInt('app_primary_color');
      if (colorVal != null) {
        final color = Color(colorVal);
        state = state.copyWith(primaryColor: color);
        _applyToAppColors(color);
      }
    } catch (_) {}
  }

  Future<void> setColor(Color color) async {
    state = state.copyWith(primaryColor: color);
    _applyToAppColors(color);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('app_primary_color', color.toARGB32());
    } catch (_) {}
  }

  Future<void> setAccent(Color color) async {
    state = state.copyWith(primaryAccent: color);
  }
}

final themeColorProvider =
    StateNotifierProvider<ThemeColorNotifier, ThemeColorState>((ref) {
  return ThemeColorNotifier();
});

// ============================================
// Admin State & Provider (لوحة التحكم)
// ============================================

class AdminState {
  final bool isLoading;
  final String? error;

  // إحصائيات عامة
  final int totalOrders;
  final int totalCustomers;
  final int totalProducts;
  final double totalSales;
  final int activeCustomers;
  final int newCustomers;
  final double salesGrowth;
  final double ordersGrowth;
  final double averageOrderValue;
  final double conversionRate;
  final double retentionRate;

  // التسويق
  final List<Campaign> campaigns;
  final List<Ad> ads;
  final List<Promotion> promotions;
  final int marketingViews;
  final int marketingClicks;
  final double marketingCtr;
  final int marketingConversions;

  // العملاء
  final List<Customer> customers;
  final List<Customer> topCustomers;

  // التقارير
  final List<SalesDataPoint> salesData;
  final List<CategorySales> salesByCategory;
  final List<ProductSales> topProducts;
  final List<ProductSales> lowStockProducts;
  final List<RecentOrder> recentOrders;

  // الخصومات
  final List<Discount> discounts;

  // المحتوى
  final List<BannerItem> banners;
  final List<PageItem> pages;
  final List<NotificationItem> notifications;
  final List<FaqItem> faqs;

  // الإعدادات
  final StoreSettings storeSettings;
  final PaymentSettings paymentSettings;
  final ShippingSettings shippingSettings;
  final NotificationSettings notificationSettings;

  AdminState({
    this.isLoading = false,
    this.error,
    this.totalOrders = 0,
    this.totalCustomers = 0,
    this.totalProducts = 0,
    this.totalSales = 0,
    this.activeCustomers = 0,
    this.newCustomers = 0,
    this.salesGrowth = 0,
    this.ordersGrowth = 0,
    this.averageOrderValue = 0,
    this.conversionRate = 0,
    this.retentionRate = 0,
    this.campaigns = const [],
    this.ads = const [],
    this.promotions = const [],
    this.marketingViews = 0,
    this.marketingClicks = 0,
    this.marketingCtr = 0,
    this.marketingConversions = 0,
    this.customers = const [],
    this.topCustomers = const [],
    this.salesData = const [],
    this.salesByCategory = const [],
    this.topProducts = const [],
    this.lowStockProducts = const [],
    this.recentOrders = const [],
    this.discounts = const [],
    this.banners = const [],
    this.pages = const [],
    this.notifications = const [],
    this.faqs = const [],
    this.storeSettings = const StoreSettings(),
    this.paymentSettings = const PaymentSettings(),
    this.shippingSettings = const ShippingSettings(),
    this.notificationSettings = const NotificationSettings(),
  });

  AdminState copyWith({
    bool? isLoading,
    String? error,
    int? totalOrders,
    int? totalCustomers,
    int? totalProducts,
    double? totalSales,
    int? activeCustomers,
    int? newCustomers,
    double? salesGrowth,
    double? ordersGrowth,
    double? averageOrderValue,
    double? conversionRate,
    double? retentionRate,
    List<Campaign>? campaigns,
    List<Ad>? ads,
    List<Promotion>? promotions,
    int? marketingViews,
    int? marketingClicks,
    double? marketingCtr,
    int? marketingConversions,
    List<Customer>? customers,
    List<Customer>? topCustomers,
    List<SalesDataPoint>? salesData,
    List<CategorySales>? salesByCategory,
    List<ProductSales>? topProducts,
    List<ProductSales>? lowStockProducts,
    List<RecentOrder>? recentOrders,
    List<Discount>? discounts,
    List<BannerItem>? banners,
    List<PageItem>? pages,
    List<NotificationItem>? notifications,
    List<FaqItem>? faqs,
    StoreSettings? storeSettings,
    PaymentSettings? paymentSettings,
    ShippingSettings? shippingSettings,
    NotificationSettings? notificationSettings,
  }) =>
      AdminState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        totalOrders: totalOrders ?? this.totalOrders,
        totalCustomers: totalCustomers ?? this.totalCustomers,
        totalProducts: totalProducts ?? this.totalProducts,
        totalSales: totalSales ?? this.totalSales,
        activeCustomers: activeCustomers ?? this.activeCustomers,
        newCustomers: newCustomers ?? this.newCustomers,
        salesGrowth: salesGrowth ?? this.salesGrowth,
        ordersGrowth: ordersGrowth ?? this.ordersGrowth,
        averageOrderValue: averageOrderValue ?? this.averageOrderValue,
        conversionRate: conversionRate ?? this.conversionRate,
        retentionRate: retentionRate ?? this.retentionRate,
        campaigns: campaigns ?? this.campaigns,
        ads: ads ?? this.ads,
        promotions: promotions ?? this.promotions,
        marketingViews: marketingViews ?? this.marketingViews,
        marketingClicks: marketingClicks ?? this.marketingClicks,
        marketingCtr: marketingCtr ?? this.marketingCtr,
        marketingConversions: marketingConversions ?? this.marketingConversions,
        customers: customers ?? this.customers,
        topCustomers: topCustomers ?? this.topCustomers,
        salesData: salesData ?? this.salesData,
        salesByCategory: salesByCategory ?? this.salesByCategory,
        topProducts: topProducts ?? this.topProducts,
        lowStockProducts: lowStockProducts ?? this.lowStockProducts,
        recentOrders: recentOrders ?? this.recentOrders,
        discounts: discounts ?? this.discounts,
        banners: banners ?? this.banners,
        pages: pages ?? this.pages,
        notifications: notifications ?? this.notifications,
        faqs: faqs ?? this.faqs,
        storeSettings: storeSettings ?? this.storeSettings,
        paymentSettings: paymentSettings ?? this.paymentSettings,
        shippingSettings: shippingSettings ?? this.shippingSettings,
        notificationSettings: notificationSettings ?? this.notificationSettings,
      );
}

class AdminNotifier extends StateNotifier<AdminState> {
  final AdminService _adminService;
  final BannerService _bannerService;

  AdminNotifier(this._adminService, this._bannerService) : super(AdminState()) {
    loadDashboard();
  }

  /// تحميل بيانات لوحة التحكم
  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (!ApiClient.useDummyData) {
        try {
          final data = await _adminService.getDashboard();
          state = state.copyWith(
            totalOrders: data['total_orders'] ?? state.totalOrders,
            totalCustomers: data['total_customers'] ?? state.totalCustomers,
            totalProducts: data['total_products'] ?? state.totalProducts,
            totalSales:
                (data['total_sales'] as num?)?.toDouble() ?? state.totalSales,
            activeCustomers: data['active_customers'] ?? state.activeCustomers,
            newCustomers: data['new_customers'] ?? state.newCustomers,
          );
        } catch (_) {
          // في حال كان الـ Admin API يتطلب صلاحيات Sanctum، نُبقي على البيانات الافتراضية
        }
      }

      // جلب البانرات الحقيقية من السيرفر (GET /admin/banners)
      List<BannerItem> banners = _dummyBanners;
      if (!ApiClient.useDummyData) {
        try {
          final bannersData = await _bannerService.getAdminBanners();
          if (bannersData.isNotEmpty) {
            banners = bannersData.map((e) => BannerItem.fromJson(e)).toList();
          }
        } catch (_) {
          // في حال الفشل نُبقي على البيانات الافتراضية
        }
      }

      state = state.copyWith(
        isLoading: false,
        totalOrders: ApiClient.useDummyData ? 1247 : state.totalOrders,
        totalCustomers: ApiClient.useDummyData ? 856 : state.totalCustomers,
        totalProducts: ApiClient.useDummyData ? 342 : state.totalProducts,
        totalSales: ApiClient.useDummyData ? 458200 : state.totalSales,
        activeCustomers: ApiClient.useDummyData ? 634 : state.activeCustomers,
        newCustomers: ApiClient.useDummyData ? 42 : state.newCustomers,
        salesGrowth: 12.5,
        ordersGrowth: 8.3,
        averageOrderValue: 367.5,
        conversionRate: 3.2,
        retentionRate: 74.5,
        campaigns: _dummyCampaigns,
        ads: _dummyAds,
        promotions: _dummyPromotions,
        marketingViews: 45200,
        marketingClicks: 3200,
        marketingCtr: 7.1,
        marketingConversions: 285,
        customers: _dummyCustomers,
        topCustomers: _dummyCustomers.take(5).toList(),
        salesData: _dummySalesData,
        salesByCategory: _dummyCategorySales,
        topProducts: _dummyTopProducts,
        lowStockProducts: _dummyLowStockProducts,
        recentOrders: _dummyRecentOrders,
        discounts: _dummyDiscounts,
        banners: banners,
        pages: _dummyPages,
        notifications: _dummyNotifications,
        faqs: _dummyFaqs,
        storeSettings: const StoreSettings(
          name: 'بركة عدن',
          email: 'info@store.com',
          phone: '772055335',
          address: 'عدن، اليمن',
          description: 'متجر إلكتروني متخصص في المنتجات الإلكترونية',
          currency: 'YER',
          language: 'ar',
        ),
        paymentSettings: const PaymentSettings(
          cashOnDelivery: true,
          creditCard: true,
          eWallet: false,
          bankTransfer: true,
          minOrderAmount: 50,
          transactionFee: 2.5,
        ),
        shippingSettings: ShippingSettings(
          defaultCost: 25,
          freeShippingThreshold: 200,
          deliveryDays: 3,
          shippingCompanies: [
            ShippingCompany(
                id: '1', name: 'شركة التوصيل السريع', cost: 25, isActive: true),
            ShippingCompany(
                id: '2', name: 'البريد اليمني', cost: 15, isActive: true),
            ShippingCompany(id: '3', name: 'أرامكس', cost: 35, isActive: false),
          ],
        ),
        notificationSettings: const NotificationSettings(
          orderNotifications: true,
          customerNotifications: true,
          marketingNotifications: false,
          stockNotifications: true,
          pushNotifications: true,
          emailNotifications: false,
          smsNotifications: true,
        ),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // عمليات التسويق
  void addCampaign(
      {required String title, required String type, double budget = 0}) {
    final campaign = Campaign(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      type: type,
      budget: budget,
    );
    state = state.copyWith(campaigns: [campaign, ...state.campaigns]);
  }

  void deleteCampaign(String id) {
    state = state.copyWith(
      campaigns: state.campaigns.where((c) => c.id != id).toList(),
    );
  }

  void deleteAd(String id) {
    state = state.copyWith(ads: state.ads.where((a) => a.id != id).toList());
  }

  void deletePromotion(String id) {
    state = state.copyWith(
      promotions: state.promotions.where((p) => p.id != id).toList(),
    );
  }

  // عمليات العملاء
  void toggleCustomerStatus(String id) {
    final customers = state.customers.map((c) {
      if (c.id == id) {
        return Customer(
          id: c.id,
          name: c.name,
          email: c.email,
          phone: c.phone,
          city: c.city,
          registerDate: c.registerDate,
          lastOrderDate: c.lastOrderDate,
          ordersCount: c.ordersCount,
          totalSpent: c.totalSpent,
          isActive: !c.isActive,
          isVip: c.isVip,
          isNew: c.isNew,
        );
      }
      return c;
    }).toList();
    state = state.copyWith(customers: customers);
  }

  // عمليات الخصومات
  void addDiscount({
    required String code,
    String type = 'نسبة مئوية',
    double value = 0,
    double minOrder = 0,
    int maxUsage = 100,
  }) {
    final discount = Discount(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      code: code,
      type: type,
      value: value,
      minOrder: minOrder,
      maxUsage: maxUsage,
      startDate: DateTime.now().toString().substring(0, 10),
      endDate: DateTime.now()
          .add(const Duration(days: 30))
          .toString()
          .substring(0, 10),
    );
    state = state.copyWith(discounts: [discount, ...state.discounts]);
  }

  void deleteDiscount(String id) {
    state = state.copyWith(
      discounts: state.discounts.where((d) => d.id != id).toList(),
    );
  }

  void toggleDiscountStatus(String id) {
    final discounts = state.discounts.map((d) {
      if (d.id == id) {
        return Discount(
          id: d.id,
          code: d.code,
          type: d.type,
          value: d.value,
          minOrder: d.minOrder,
          usedCount: d.usedCount,
          maxUsage: d.maxUsage,
          startDate: d.startDate,
          endDate: d.endDate,
          status: d.status == DiscountStatus.active
              ? DiscountStatus.expired
              : DiscountStatus.active,
        );
      }
      return d;
    }).toList();
    state = state.copyWith(discounts: discounts);
  }

  // عمليات المحتوى (البانرات - مرتبطة بالسيرفر)
  Future<void> addBanner({required String title, String link = ''}) async {
    try {
      final data = await _bannerService.createBanner(title: title, link: link);
      final banner = BannerItem.fromJson(data);
      state = state.copyWith(banners: [banner, ...state.banners], error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteBanner(String id) async {
    try {
      await _bannerService.deleteBanner(id);
      state = state.copyWith(
        banners: state.banners.where((b) => b.id != id).toList(),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> toggleBannerStatus(String id) async {
    try {
      final data = await _bannerService.toggleBanner(id);
      final updated = BannerItem.fromJson(data);
      final banners =
          state.banners.map((b) => b.id == id ? updated : b).toList();
      state = state.copyWith(banners: banners, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  void addPage({required String title, String content = ''}) {
    final page = PageItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
    );
    state = state.copyWith(pages: [page, ...state.pages]);
  }

  void deletePage(String id) {
    state = state.copyWith(
      pages: state.pages.where((p) => p.id != id).toList(),
    );
  }

  /// إرسال إشعار عبر السيرفر (لمستخدم معين عبر userId أو لجميع المستخدمين إذا كان null)
  Future<void> addNotification({
    required String title,
    String body = '',
    int? userId,
  }) async {
    try {
      await _adminService.sendNotification(
        title: title,
        body: body,
        userId: userId,
      );
      final notification = NotificationItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        date: DateTime.now().toString().substring(0, 10),
      );
      state = state.copyWith(
        notifications: [notification, ...state.notifications],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  void deleteNotification(String id) {
    state = state.copyWith(
      notifications: state.notifications.where((n) => n.id != id).toList(),
    );
  }

  void addFaq({required String question, String answer = ''}) {
    final faq = FaqItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      question: question,
      answer: answer,
    );
    state = state.copyWith(faqs: [faq, ...state.faqs]);
  }

  void deleteFaq(String id) {
    state = state.copyWith(faqs: state.faqs.where((f) => f.id != id).toList());
  }

  // عمليات الإعدادات
  void updateStoreSetting(String key, dynamic value) {
    final settings = state.storeSettings;
    StoreSettings newSettings;
    switch (key) {
      case 'currency':
        newSettings = settings.copyWith(currency: value as String);
        break;
      case 'language':
        newSettings = settings.copyWith(language: value as String);
        break;
      default:
        newSettings = settings;
    }
    state = state.copyWith(storeSettings: newSettings);
  }

  void updatePaymentSetting(String key, bool value) {
    final settings = state.paymentSettings;
    PaymentSettings newSettings;
    switch (key) {
      case 'cash_on_delivery':
        newSettings = settings.copyWith(cashOnDelivery: value);
        break;
      case 'credit_card':
        newSettings = settings.copyWith(creditCard: value);
        break;
      case 'e_wallet':
        newSettings = settings.copyWith(eWallet: value);
        break;
      case 'bank_transfer':
        newSettings = settings.copyWith(bankTransfer: value);
        break;
      default:
        newSettings = settings;
    }
    state = state.copyWith(paymentSettings: newSettings);
  }

  void toggleShippingCompany(String id) {
    final companies = state.shippingSettings.shippingCompanies.map((c) {
      if (c.id == id) {
        return ShippingCompany(
          id: c.id,
          name: c.name,
          cost: c.cost,
          isActive: !c.isActive,
        );
      }
      return c;
    }).toList();
    state = state.copyWith(
      shippingSettings: state.shippingSettings.copyWith(
        shippingCompanies: companies,
      ),
    );
  }

  void updateNotificationSetting(String key, bool value) {
    final settings = state.notificationSettings;
    NotificationSettings newSettings;
    switch (key) {
      case 'order':
        newSettings = settings.copyWith(orderNotifications: value);
        break;
      case 'customer':
        newSettings = settings.copyWith(customerNotifications: value);
        break;
      case 'marketing':
        newSettings = settings.copyWith(marketingNotifications: value);
        break;
      case 'stock':
        newSettings = settings.copyWith(stockNotifications: value);
        break;
      case 'push':
        newSettings = settings.copyWith(pushNotifications: value);
        break;
      case 'email':
        newSettings = settings.copyWith(emailNotifications: value);
        break;
      case 'sms':
        newSettings = settings.copyWith(smsNotifications: value);
        break;
      default:
        newSettings = settings;
    }
    state = state.copyWith(notificationSettings: newSettings);
  }

  // بيانات تجريبية
  static final List<Campaign> _dummyCampaigns = [
    Campaign(
        id: '1',
        title: 'تخفيضات الصيف',
        type: 'حملة إعلانية',
        budget: 5000,
        views: 12000,
        clicks: 850,
        isActive: true),
    Campaign(
        id: '2',
        title: 'عرض الجمعة البيضاء',
        type: 'عرض ترويجي',
        budget: 3000,
        views: 8500,
        clicks: 620,
        isActive: true),
    Campaign(
        id: '3',
        title: 'إطلاق المنتجات الجديدة',
        type: 'إعلان ممول',
        budget: 8000,
        views: 15000,
        clicks: 1200,
        isActive: false),
  ];

  static final List<Ad> _dummyAds = [
    Ad(
        id: '1',
        title: 'إعلان إنستغرام',
        platform: 'إنستغرام',
        startDate: '2026-07-01',
        endDate: '2026-07-31',
        isActive: true),
    Ad(
        id: '2',
        title: 'إعلان فيسبوك',
        platform: 'فيسبوك',
        startDate: '2026-07-15',
        endDate: '2026-08-15',
        isActive: true),
    Ad(
        id: '3',
        title: 'إعلان تيك توك',
        platform: 'تيك توك',
        startDate: '2026-06-01',
        endDate: '2026-06-30',
        isActive: false),
  ];

  static final List<Promotion> _dummyPromotions = [
    Promotion(
        id: '1',
        title: 'خصم العملاء الجدد',
        code: 'NEW10',
        discountPercent: 10,
        usedCount: 45,
        maxUsage: 100,
        isActive: true),
    Promotion(
        id: '2',
        title: 'عرض نهاية الموسم',
        code: 'END30',
        discountPercent: 30,
        usedCount: 78,
        maxUsage: 100,
        isActive: true),
    Promotion(
        id: '3',
        title: 'كود VIP',
        code: 'VIP50',
        discountPercent: 50,
        usedCount: 12,
        maxUsage: 50,
        isActive: false),
  ];

  static final List<Customer> _dummyCustomers = [
    Customer(
        id: '1',
        name: 'أحمد محمد',
        email: 'ahmed@email.com',
        phone: '777123456',
        city: 'صنعاء',
        registerDate: '2026-01-15',
        lastOrderDate: '2026-07-28',
        ordersCount: 12,
        totalSpent: 4500,
        isVip: true,
        isNew: false),
    Customer(
        id: '2',
        name: 'سارة علي',
        email: 'sara@email.com',
        phone: '777654321',
        city: 'عدن',
        registerDate: '2026-06-20',
        lastOrderDate: '2026-07-30',
        ordersCount: 3,
        totalSpent: 850,
        isVip: false,
        isNew: true),
    Customer(
        id: '3',
        name: 'خالد عبدالله',
        email: 'khaled@email.com',
        phone: '778111222',
        city: 'تعز',
        registerDate: '2026-03-10',
        lastOrderDate: '2026-07-25',
        ordersCount: 8,
        totalSpent: 3200,
        isVip: false,
        isNew: false),
    Customer(
        id: '4',
        name: 'فاطمة حسن',
        email: 'fatima@email.com',
        phone: '779333444',
        city: 'صنعاء',
        registerDate: '2026-07-01',
        lastOrderDate: '2026-07-29',
        ordersCount: 2,
        totalSpent: 450,
        isVip: false,
        isNew: true),
    Customer(
        id: '5',
        name: 'محمد سعيد',
        email: 'mohamed@email.com',
        phone: '770555666',
        city: 'الحديدة',
        registerDate: '2025-11-05',
        lastOrderDate: '2026-07-20',
        ordersCount: 15,
        totalSpent: 6800,
        isVip: true,
        isNew: false),
    Customer(
        id: '6',
        name: 'نورا أحمد',
        email: 'nora@email.com',
        phone: '771777888',
        city: 'إب',
        registerDate: '2026-05-12',
        lastOrderDate: '2026-07-15',
        ordersCount: 5,
        totalSpent: 1800,
        isVip: false,
        isNew: false),
  ];

  static final List<SalesDataPoint> _dummySalesData = [
    SalesDataPoint(label: 'يناير', value: 32000),
    SalesDataPoint(label: 'فبراير', value: 38000),
    SalesDataPoint(label: 'مارس', value: 35000),
    SalesDataPoint(label: 'أبريل', value: 42000),
    SalesDataPoint(label: 'مايو', value: 45000),
    SalesDataPoint(label: 'يونيو', value: 48000),
    SalesDataPoint(label: 'يوليو', value: 52000),
  ];

  static final List<CategorySales> _dummyCategorySales = [
    CategorySales(
        categoryName: 'الإلكترونيات', sales: 185000, percentage: 40.4),
    CategorySales(categoryName: 'الأزياء', sales: 120000, percentage: 26.2),
    CategorySales(categoryName: 'المنزل', sales: 78000, percentage: 17.0),
    CategorySales(categoryName: 'الجمال', sales: 45000, percentage: 9.8),
    CategorySales(categoryName: 'الرياضة', sales: 30200, percentage: 6.6),
  ];

  static final List<ProductSales> _dummyTopProducts = [
    ProductSales(
        name: 'سماعات بلوتوث', unitsSold: 245, revenue: 24500, stock: 50),
    ProductSales(name: 'ساعة ذكية', unitsSold: 180, revenue: 54000, stock: 30),
    ProductSales(name: 'حقيبة ظهر', unitsSold: 150, revenue: 12000, stock: 80),
    ProductSales(name: 'حذاء رياضي', unitsSold: 120, revenue: 18000, stock: 45),
    ProductSales(name: 'نظارات شمسية', unitsSold: 95, revenue: 9500, stock: 60),
  ];

  static final List<ProductSales> _dummyLowStockProducts = [
    ProductSales(name: 'ساعة ذكية', unitsSold: 180, revenue: 54000, stock: 5),
    ProductSales(
        name: 'سماعات بلوتوث', unitsSold: 245, revenue: 24500, stock: 3),
    ProductSales(name: 'كاميرا رقمية', unitsSold: 45, revenue: 22500, stock: 2),
  ];

  static final List<RecentOrder> _dummyRecentOrders = [
    RecentOrder(
        orderNumber: 'ORD-2026-001', customerName: 'أحمد محمد', total: 450),
    RecentOrder(
        orderNumber: 'ORD-2026-002', customerName: 'سارة علي', total: 1200),
    RecentOrder(
        orderNumber: 'ORD-2026-003', customerName: 'خالد عبدالله', total: 850),
    RecentOrder(
        orderNumber: 'ORD-2026-004', customerName: 'فاطمة حسن', total: 320),
    RecentOrder(
        orderNumber: 'ORD-2026-005', customerName: 'محمد سعيد', total: 2100),
  ];

  static final List<Discount> _dummyDiscounts = [
    Discount(
        id: '1',
        code: 'SAVE10',
        type: 'نسبة مئوية',
        value: 10,
        minOrder: 100,
        usedCount: 45,
        maxUsage: 100,
        startDate: '2026-07-01',
        endDate: '2026-08-31',
        status: DiscountStatus.active),
    Discount(
        id: '2',
        code: 'SUMMER20',
        type: 'نسبة مئوية',
        value: 20,
        minOrder: 200,
        usedCount: 78,
        maxUsage: 100,
        startDate: '2026-06-01',
        endDate: '2026-08-31',
        status: DiscountStatus.active),
    Discount(
        id: '3',
        code: 'WELCOME50',
        type: 'مبلغ ثابت',
        value: 50,
        minOrder: 300,
        usedCount: 100,
        maxUsage: 100,
        startDate: '2026-01-01',
        endDate: '2026-06-30',
        status: DiscountStatus.expired),
    Discount(
        id: '4',
        code: 'EID15',
        type: 'نسبة مئوية',
        value: 15,
        minOrder: 150,
        usedCount: 0,
        maxUsage: 200,
        startDate: '2026-08-10',
        endDate: '2026-08-20',
        status: DiscountStatus.scheduled),
  ];

  static final List<BannerItem> _dummyBanners = [
    BannerItem(
        id: '1',
        title: 'تخفيضات الصيف',
        link: '/summer-sale',
        sortOrder: 1,
        isActive: true),
    BannerItem(
        id: '2',
        title: 'منتجات جديدة',
        link: '/new-arrivals',
        sortOrder: 2,
        isActive: true),
    BannerItem(
        id: '3',
        title: 'عرض الجمعة',
        link: '/friday-deals',
        sortOrder: 3,
        isActive: false),
  ];

  static final List<PageItem> _dummyPages = [
    PageItem(
        id: '1',
        title: 'من نحن',
        content: 'متجر إلكتروني متخصص في بيع المنتجات الإلكترونية والأزياء...'),
    PageItem(
        id: '2',
        title: 'سياسة الاسترجاع',
        content: 'يمكنك إرجاع المنتج خلال 14 يوم من تاريخ الاستلام...'),
    PageItem(
        id: '3',
        title: 'الشروط والأحكام',
        content: 'باستخدامك للموقع فإنك توافق على الشروط التالية...'),
  ];

  static final List<NotificationItem> _dummyNotifications = [
    NotificationItem(
        id: '1',
        title: 'عرض خاص',
        body: 'خصم 20% على جميع المنتجات هذا الأسبوع!',
        date: '2026-07-28'),
    NotificationItem(
        id: '2',
        title: 'منتجات جديدة',
        body: 'تصفح أحدث المنتجات التي وصلت المتجر',
        date: '2026-07-25'),
    NotificationItem(
        id: '3',
        title: 'تذكير السلة',
        body: 'لديك منتجات في السلة بانتظار إتمام الطلب',
        date: '2026-07-20'),
  ];

  static final List<FaqItem> _dummyFaqs = [
    FaqItem(
        id: '1',
        question: 'كم تستغرق مدة التوصيل؟',
        answer: 'عادة ما يستغرق التوصيل من 2-5 أيام عمل حسب الموقع.'),
    FaqItem(
        id: '2',
        question: 'هل يمكنني إرجاع المنتج؟',
        answer: 'نعم، يمكنك إرجاع المنتج خلال 14 يوم من الاستلام.'),
    FaqItem(
        id: '3',
        question: 'ما هي طرق الدفع المتاحة؟',
        answer:
            'نوفر الدفع عند الاستلام والبطاقات الائتمانية والتحويل البنكي.'),
    FaqItem(
        id: '4',
        question: 'هل التوصيل مجاني؟',
        answer: 'التوصيل مجاني للطلبات التي تزيد عن 200 ر.ي.'),
  ];
}

final adminServiceProvider =
    Provider<AdminService>((ref) => AdminService(ref.watch(apiClientProvider)));

final adminProductServiceProvider = Provider<AdminProductService>(
    (ref) => AdminProductService(ref.watch(apiClientProvider)));

// ============================================
// إدارة المنتجات (Admin Products) — State & Provider
// ============================================

class AdminProductsState {
  final bool isLoading;
  final String? error;
  final List<Product> products;
  final List<Map<String, dynamic>> categories;
  final String? selectedCategoryId;
  final String search;

  const AdminProductsState({
    this.isLoading = false,
    this.error,
    this.products = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.search = '',
  });

  /// اسم التصنيف من المعرف
  String categoryNameOf(String categoryId) {
    for (final c in categories) {
      if (c['id'].toString() == categoryId) return c['name'].toString();
    }
    return 'غير مصنف';
  }

  AdminProductsState copyWith({
    bool? isLoading,
    String? error,
    List<Product>? products,
    List<Map<String, dynamic>>? categories,
    String? selectedCategoryId,
    String? search,
    bool clearError = false,
  }) =>
      AdminProductsState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        products: products ?? this.products,
        categories: categories ?? this.categories,
        selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
        search: search ?? this.search,
      );
}

class AdminProductsNotifier extends StateNotifier<AdminProductsState> {
  final AdminProductService _service;

  AdminProductsNotifier(this._service) : super(const AdminProductsState()) {
    load();
  }

  /// تحميل المنتجات والتصنيفات
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _service.getProducts(
          categoryId: state.selectedCategoryId,
          search: state.search,
        ),
        _service.getCategories(),
      ]);
      state = state.copyWith(
        isLoading: false,
        products: results[0] as List<Product>,
        categories: results[1] as List<Map<String, dynamic>>,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: extractApiErrorMessage(e),
      );
    }
  }

  Future<void> refresh() => load();

  void setCategoryFilter(String? categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId);
    load();
  }

  void setSearch(String value) {
    state = state.copyWith(search: value);
    load();
  }

  /// إضافة منتج جديد — يعيد null عند النجاح أو رسالة الخطأ
  Future<String?> createProduct({
    required String name,
    required double price,
    required String categoryId,
    String description = '',
    double? oldPrice,
    String currency = 'YER',
    String? image,
    int stock = 0,
    bool isActive = true,
  }) async {
    try {
      await _service.createProduct(
        name: name,
        price: price,
        categoryId: categoryId,
        description: description,
        oldPrice: oldPrice,
        currency: currency,
        image: image,
        stock: stock,
        isActive: isActive,
      );
      await load();
      return null;
    } catch (e) {
      return extractApiErrorMessage(e);
    }
  }

  /// تعديل منتج — يعيد null عند النجاح أو رسالة الخطأ
  Future<String?> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      await _service.updateProduct(id, data);
      await load();
      return null;
    } catch (e) {
      return extractApiErrorMessage(e);
    }
  }

  /// حذف منتج — يعيد null عند النجاح أو رسالة الخطأ
  Future<String?> deleteProduct(String id) async {
    try {
      await _service.deleteProduct(id);
      state = state.copyWith(
          products: state.products.where((p) => p.id != id).toList());
      return null;
    } catch (e) {
      return extractApiErrorMessage(e);
    }
  }

  /// إضافة تصنيف جديد — يعيد null عند النجاح أو رسالة الخطأ
  Future<String?> createCategory(String name) async {
    try {
      await _service.createCategory(name: name);
      await load();
      return null;
    } catch (e) {
      return extractApiErrorMessage(e);
    }
  }
}

final adminProductsProvider =
    StateNotifierProvider<AdminProductsNotifier, AdminProductsState>((ref) {
  return AdminProductsNotifier(ref.watch(adminProductServiceProvider));
});

// ============================================
// Banners State & Provider (بانرات الصفحة الرئيسية)
// ============================================

final bannerServiceProvider = Provider<BannerService>(
    (ref) => BannerService(ref.watch(apiClientProvider)));

class BannersState {
  final List<AppBanner> banners;
  final bool isLoading;
  final String? error;

  BannersState({
    this.banners = const [],
    this.isLoading = false,
    this.error,
  });

  BannersState copyWith({
    List<AppBanner>? banners,
    bool? isLoading,
    String? error,
  }) =>
      BannersState(
        banners: banners ?? this.banners,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

class BannersNotifier extends StateNotifier<BannersState> {
  final BannerService _bannerService;

  BannersNotifier(this._bannerService) : super(BannersState()) {
    fetchBanners();
  }

  /// جلب البانرات المفعّلة من السيرفر (GET /banners)
  Future<void> fetchBanners() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _bannerService.getBanners();
      state = state.copyWith(
        banners: data.map((e) => AppBanner.fromJson(e)).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> refresh() => fetchBanners();
}

final bannersProvider =
    StateNotifierProvider<BannersNotifier, BannersState>((ref) {
  return BannersNotifier(ref.watch(bannerServiceProvider));
});

// ============================================
// Notifications State & Provider
// ============================================

class NotificationsState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? error;
  final int page;
  final int lastPage;
  final DateTime? lastFetchedAt;

  NotificationsState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.error,
    this.page = 1,
    this.lastPage = 1,
    this.lastFetchedAt,
  });

  /// هل توجد صفحات إضافية لم تُحمَّل بعد؟
  bool get hasMore => page < lastPage;

  bool get isEmpty => notifications.isEmpty;

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    int? page,
    int? lastPage,
    DateTime? lastFetchedAt,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      page: page ?? this.page,
      lastPage: lastPage ?? this.lastPage,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier(this._apiClient) : super(NotificationsState());

  final ApiClient _apiClient;

  /// بعد هذه المدة تُعتبر القائمة قديمة وتحتاج تحديثاً
  static const Duration staleAfter = Duration(seconds: 30);

  /// تجميع عدة أحداث (إشعارات متتابعة) في طلب واحد
  static const Duration _debounceDelay = Duration(milliseconds: 600);

  Future<void>? _inFlight;
  Timer? _debounceTimer;
  bool _disposed = false;

  /// يزداد عند كل تفريغ (تسجيل خروج / تبديل حساب) لإبطال الطلبات الجارية،
  /// حتى لا تكتب نتيجة طلب قديم بيانات مستخدم سابق في حالة المستخدم الجديد.
  int _generation = 0;

  bool get _isStale {
    final at = state.lastFetchedAt;
    if (at == null) {
      return true;
    }
    return DateTime.now().difference(at) > staleAfter;
  }

  /// جلب الإشعارات مرة واحدة فقط عند الحاجة
  ///
  /// كانت النسخة السابقة تجلب من المُنشئ ومن initState في الشاشة معاً،
  /// فيحدث طلبان متتاليان في كل فتح للتطبيق.
  Future<void> ensureFresh() {
    if (state.notifications.isNotEmpty && !_isStale) {
      return Future.value();
    }
    return fetchNotifications();
  }

  /// تحديث مؤجّل (debounced) لا يُظهر مؤشر تحميل — يُستخدم بعد وصول إشعار
  Future<void> refreshQuietly() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      if (!_disposed) {
        unawaited(fetchNotifications(quiet: true));
      }
    });
    return Future.value();
  }

  /// تحديث عند عودة التطبيق للواجهة إذا مرّ وقت كافٍ
  Future<void> refreshIfStale() {
    if (!_isStale) {
      return Future.value();
    }
    return fetchNotifications(quiet: state.notifications.isNotEmpty);
  }

  /// جلب الإشعارات من السيرفر — طلب واحد في الوقت نفسه مهما تكرّرت الاستدعاءات
  Future<void> fetchNotifications(
      {bool quiet = false, bool force = false}) async {
    final running = _inFlight;
    if (running != null) {
      // ننتظر الطلب الجاري بدل تكديس طلبات متطابقة على الشبكة
      await running;
      if (!force) {
        return;
      }
    }

    final future = _fetch(quiet: quiet);
    _inFlight = future;
    try {
      await future;
    } finally {
      _inFlight = null;
    }
  }

  Future<void> _fetch({required bool quiet}) async {
    if (_disposed) {
      return;
    }

    final generation = _generation;

    // عند وجود بيانات مسبقة نُحدّث في الخلفية دون شاشة تحميل فارغة
    final background = quiet && state.notifications.isNotEmpty;
    state = state.copyWith(
      isLoading: !background,
      isRefreshing: background,
      clearError: true,
    );

    try {
      final result = await _apiClient.getNotifications(page: 1);
      if (_disposed || generation != _generation) {
        return;
      }

      state = NotificationsState(
        notifications: result.notifications,
        unreadCount: result.unreadCount,
        page: result.page,
        lastPage: result.lastPage,
        lastFetchedAt: DateTime.now(),
      );
    } catch (e) {
      if (_disposed || generation != _generation) {
        return;
      }
      final message = _errorMessage(e);
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: message,
        clearError: message == null,
      );
    }
  }

  /// رسالة خطأ عربية مفهومة (بدلاً من نص DioException للمستخدم)
  String? _errorMessage(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.connectionTimeout:
          return 'تعذّر الاتصال بالخادم، تحقّق من الإنترنت';
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          // الخادم مستضاف على Render ويستيقظ بعد خمول، فالطلب يصل لكن الرد يتأخر
          return 'الخادم يستغرق وقتاً في الاستجابة، أعد المحاولة بعد لحظات';
        default:
          break;
      }

      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        // الجلسة منتهية — يتولى AuthProvider إعادة التوجيه
        return null;
      }
      if (status == 502 || status == 503 || status == 504) {
        // بروكسي Render يرد بهذه الأكواد بينما الخدمة تُقلع
        return 'الخادم قيد التشغيل الآن، أعد المحاولة بعد لحظات';
      }
      if (status != null && status >= 500) {
        return 'خطأ في الخادم، حاول لاحقاً';
      }

      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }

      return 'تعذّر تحميل الإشعارات';
    }

    return e.toString().replaceAll('Exception: ', '');
  }

  /// تحديث العدّاد فوراً عند وصول إشعار (قبل أي طلب شبكة)
  void bumpUnread() {
    if (_disposed) {
      return;
    }
    state = state.copyWith(unreadCount: state.unreadCount + 1);
  }

  /// تعليم إشعار كمقروء — تحديث متفائل مع تراجع عند فشل الطلب
  Future<void> markAsRead(String id) async {
    final index = state.notifications.indexWhere((n) => n.id == id);
    if (index < 0 || _disposed) {
      return;
    }

    final original = state.notifications[index];
    if (original.isRead) {
      return;
    }

    final optimistic = [...state.notifications];
    optimistic[index] = original.copyWith(readAt: DateTime.now());
    state = state.copyWith(
      notifications: optimistic,
      unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
    );

    final ok = await _apiClient.markNotificationAsRead(id);
    if (!ok && !_disposed) {
      // فشل الطلب: نُرجع الحالة حتى لا تختفي علامة "غير مقروء" كذباً
      final rollback = [...state.notifications];
      final i = rollback.indexWhere((n) => n.id == id);
      if (i >= 0) {
        rollback[i] = original;
        state = state.copyWith(
          notifications: rollback,
          unreadCount: state.unreadCount + 1,
        );
      }
    }
  }

  /// تعليم كل الإشعارات كمقروءة — تحديث فوري مع تراجع عند الفشل
  Future<void> markAllAsRead() async {
    if (_disposed || state.unreadCount == 0) {
      return;
    }

    final previous = state;
    final now = DateTime.now();
    state = state.copyWith(
      notifications: previous.notifications
          .map((n) => n.isRead ? n : n.copyWith(readAt: now))
          .toList(),
      unreadCount: 0,
    );

    final ok = await _apiClient.markAllNotificationsAsRead();
    if (!ok && !_disposed) {
      state = previous;
    }
  }

  /// تحميل الصفحة التالية من الإشعارات (عند التمرير للأسفل)
  Future<void> loadMore() async {
    if (_disposed ||
        _inFlight != null ||
        !state.hasMore ||
        state.isLoadingMore ||
        state.isLoading) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearError: true);

    final generation = _generation;

    try {
      final next = await _apiClient.getNotifications(page: state.page + 1);
      if (_disposed || generation != _generation) {
        return;
      }

      final existingIds = state.notifications.map((n) => n.id).toSet();
      state = state.copyWith(
        notifications: [
          ...state.notifications,
          ...next.notifications.where((n) => !existingIds.contains(n.id)),
        ],
        unreadCount: next.unreadCount,
        page: next.page,
        lastPage: next.lastPage,
        isLoadingMore: false,
        lastFetchedAt: DateTime.now(),
      );
    } catch (e) {
      if (_disposed) {
        return;
      }
      final message = _errorMessage(e);
      state = state.copyWith(
        isLoadingMore: false,
        error: message,
        clearError: message == null,
      );
    }
  }

  /// تفريغ الحالة عند تسجيل الخروج
  void reset() {
    _generation++;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _inFlight = null;
    if (!_disposed) {
      state = NotificationsState();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(ref.watch(apiClientProvider));
});

/// عدّاد الإشعارات غير المقروءة فقط
///
/// يستمع لتغيّر العدّاد وحده (select) فلا يُعاد بناء شريط الرئيسية
/// عند كل تحديث لقائمة الإشعارات — وهي القائمة الأكثر تغيّراً في التطبيق.
final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider.select((state) => state.unreadCount));
});

/// جسر بين إشعارات Firebase الفورية وحالة التطبيق
///
/// يربط ثلاثة مصادر: الإشعار الوارد أثناء فتح التطبيق، النقر على إشعار،
/// وعودة التطبيق للواجهة — إضافةً إلى تغيّر حالة تسجيل الدخول.
class NotificationsBridge {
  NotificationsBridge(this._ref) {
    _foregroundSub =
        FirebaseNotificationService.foregroundMessages.listen(_onForeground);
    _openedSub = FirebaseNotificationService.openedMessages.listen(_onOpened);
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    _authSub = _ref.listen<AuthState>(authProvider, _onAuthChanged);

    // المزامنة الأولى تُؤجَّل لما بعد الإطار الأول حتى لا نُعدّل حالة
    // مزوّدين آخرين أثناء بناء الواجهة.
    Future.microtask(_syncWithAuth);
  }

  final Ref _ref;

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  ProviderSubscription<AuthState>? _authSub;
  AppLifecycleListener? _lifecycle;

  /// معرّف المستخدم المسجّل حالياً (null = زائر)
  String? _userId;

  NotificationsNotifier get _notifications =>
      _ref.read(notificationsProvider.notifier);

  void _onAuthChanged(AuthState? previous, AuthState next) {
    _syncWithAuth(next);
  }

  void _syncWithAuth([AuthState? override]) {
    final AuthState? state = override ?? _ref.read(authProvider);

    if (state == null || !state.isAuthenticated) {
      if (_userId != null) {
        _userId = null;
        _notifications.reset();
      }
      return;
    }

    final userId = state.user?.id.toString() ?? (state.isAuthenticated ? 'authenticated' : null);
    if (userId != null && userId == _userId) {
      return; // نفس المستخدم (تغيّر isLoading مثلاً)
    }

    _userId = userId;

    // مستخدم جديد/مختلف: نمسح قائمة السابق ثم نجلب قائمته
    _notifications.reset();
    unawaited(_notifications.fetchNotifications());

    // وإعادة ربط توكن الجهاز بالحساب الجديد
    unawaited(FirebaseNotificationService.syncToken(force: true));
  }

  void _onForeground(RemoteMessage message) {
    final auth = _ref.read(authProvider);
    if (!auth.isAuthenticated) {
      return; // لا يوجد مستخدم مصادق — لا عدّاد لتحديثه
    }
    _notifications.bumpUnread();
    unawaited(_notifications.refreshQuietly());
  }

  void _onOpened(RemoteMessage message) {
    final auth = _ref.read(authProvider);
    if (!auth.isAuthenticated) {
      return;
    }
    unawaited(_notifications.fetchNotifications(quiet: true, force: true));
  }

  void _onResume() {
    final auth = _ref.read(authProvider);
    if (!auth.isAuthenticated) {
      return;
    }
    unawaited(_notifications.refreshIfStale());
    unawaited(FirebaseNotificationService.syncToken());
  }

  void dispose() {
    _foregroundSub?.cancel();
    _openedSub?.cancel();
    _authSub?.close();
    _lifecycle?.dispose();
    _foregroundSub = null;
    _openedSub = null;
    _authSub = null;
    _lifecycle = null;
  }
}

final notificationsBridgeProvider = Provider<NotificationsBridge>((ref) {
  final bridge = NotificationsBridge(ref);
  ref.onDispose(bridge.dispose);
  return bridge;
});

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier(
    ref.watch(adminServiceProvider),
    ref.watch(bannerServiceProvider),
  );
});
