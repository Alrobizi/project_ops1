// ============================================
// نماذج البيانات (Models)
// User, Product, Category, CartItem, Order, Address
// ============================================

import '../utils/url_helper.dart';

/// نموذج المستخدم
class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatar;
  final String? token;

  /// دور المستخدم: 'admin' أو 'customer'
  final String role;

  /// أقسام لوحة التحكم المسموحة للمستخدم
  /// (مصفوفة فارغة تعني وصول كامل لكل الأقسام)
  final List<String> adminPermissions;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatar,
    this.token,
    this.role = 'customer',
    this.adminPermissions = const [],
  });

  /// هل يمكن لهذا المستخدم فتح لوحة التحكم؟
  bool get canAccessAdminPanel => role == 'admin';

  /// هل يملك المستخدم صلاحية إدارة المنتجات (إضافة/تعديل/تصنيف)؟
  bool get canManageProducts =>
      role == 'admin' &&
      (adminPermissions.isEmpty || adminPermissions.contains('products'));

  /// هل يملك المستخدم صلاحية معينة على لوحة التحكم؟
  bool hasAdminPermission(String permission) =>
      role == 'admin' &&
      (adminPermissions.isEmpty || adminPermissions.contains(permission));

  /// صلاحيات مفاتيح أقسام لوحة التحكم
  static const Map<String, String> adminPermissionLabels = {
    'products': 'المنتجات',
    'orders': 'الطلبات',
    'customers': 'العملاء',
    'discounts': 'الخصومات',
    'reports': 'التقارير',
    'content': 'المحتوى',
    'marketing': 'التسويق',
    'settings': 'الإعدادات',
    'users': 'المستخدمون',
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        avatar: json['avatar'],
        token: json['token'],
        role: json['role'] ?? 'customer',
        adminPermissions: (json['admin_permissions'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'avatar': avatar,
        'token': token,
        'role': role,
        'admin_permissions': adminPermissions,
      };
}

/// نموذج المنتج
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? oldPrice;
  final String currency;
  final String image;
  final List<String> images;
  final String categoryId;
  final double rating;
  final int reviewsCount;
  final int stock;
  final List<String> colors;
  final List<String> sizes;
  final bool isFavorite;
  final bool isBestSeller;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.oldPrice,
    this.currency = 'YER',
    required this.image,
    this.images = const [],
    required this.categoryId,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.stock = 0,
    this.colors = const [],
    this.sizes = const [],
    this.isFavorite = false,
    this.isBestSeller = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        price: (json['price'] ?? 0).toDouble(),
        oldPrice: json['old_price']?.toDouble(),
        currency: json['currency'] ?? json['currency_symbol'] ?? 'SAR',
        image: fixImageUrl(json['image'] ?? ''),
        images: (json['images'] as List?)
                ?.map((e) => fixImageUrl(e.toString()))
                .toList() ??
            [],
        categoryId: json['category_id']?.toString() ?? '',
        rating: (json['rating'] ?? 0).toDouble(),
        reviewsCount: json['reviews_count'] ?? 0,
        stock: json['stock'] ?? 0,
        colors: List<String>.from(json['colors'] ?? []),
        sizes: List<String>.from(json['sizes'] ?? []),
        isFavorite: json['is_favorite'] ?? false,
        isBestSeller: json['is_best_seller'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'old_price': oldPrice,
        'currency': currency,
        'image': image,
        'images': images,
        'category_id': categoryId,
        'rating': rating,
        'reviews_count': reviewsCount,
        'stock': stock,
        'colors': colors,
        'sizes': sizes,
        'is_favorite': isFavorite,
        'is_best_seller': isBestSeller,
      };

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? oldPrice,
    String? currency,
    String? image,
    List<String>? images,
    String? categoryId,
    double? rating,
    int? reviewsCount,
    int? stock,
    List<String>? colors,
    List<String>? sizes,
    bool? isFavorite,
    bool? isBestSeller,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        oldPrice: oldPrice ?? this.oldPrice,
        currency: currency ?? this.currency,
        image: image ?? this.image,
        images: images ?? this.images,
        categoryId: categoryId ?? this.categoryId,
        rating: rating ?? this.rating,
        reviewsCount: reviewsCount ?? this.reviewsCount,
        stock: stock ?? this.stock,
        colors: colors ?? this.colors,
        sizes: sizes ?? this.sizes,
        isFavorite: isFavorite ?? this.isFavorite,
        isBestSeller: isBestSeller ?? this.isBestSeller,
      );
  /// رمز العملة المعروض (ر.س / ر.ي)
  String get currencySymbol {
    if (currency == 'YER' || currency == 'ر.ي' || currency == 'ريال يمني') {
      return 'ر.ي';
    }
    return 'ر.س';
  }
}

/// نموذج التصنيف
class Category {
  final String id;
  final String name;
  final String? slug;
  final String icon;
  final String? image;
  final String? parentId;
  final String type; // 'main', 'sub', 'marketing'
  final String? badge;
  final int sortOrder;
  final bool isActive;
  final List<Category> children;
  final int? productsCount;

  Category({
    required this.id,
    required this.name,
    this.slug,
    required this.icon,
    this.image,
    this.parentId,
    this.type = 'main',
    this.badge,
    this.sortOrder = 0,
    this.isActive = true,
    this.children = const [],
    this.productsCount,
  });

  bool get isMainCategory => type == 'main' && parentId == null;
  bool get isSubcategory => type == 'sub' || parentId != null;
  bool get isMarketing => type == 'marketing';
  bool get hasChildren => children.isNotEmpty;

  factory Category.fromJson(Map<String, dynamic> json) {
    final children = (json['children'] as List?)
            ?.map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      slug: json['slug'],
      icon: json['icon'] ?? '',
      image: json['image'] != null && json['image'].toString().isNotEmpty
          ? fixImageUrl(json['image'].toString())
          : null,
      parentId: json['parent_id']?.toString(),
      type: json['type'] ?? 'main',
      badge: json['badge'],
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      children: children,
      productsCount: json['products_count'] != null
          ? (json['products_count'] as num).toInt()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'icon': icon,
        'image': image,
        'parent_id': parentId,
        'type': type,
        'badge': badge,
        'sort_order': sortOrder,
        'is_active': isActive,
        'children': children.map((e) => e.toJson()).toList(),
        'products_count': productsCount,
      };

  Category copyWith({
    String? id,
    String? name,
    String? slug,
    String? icon,
    String? image,
    String? parentId,
    String? type,
    String? badge,
    int? sortOrder,
    bool? isActive,
    List<Category>? children,
    int? productsCount,
  }) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        slug: slug ?? this.slug,
        icon: icon ?? this.icon,
        image: image ?? this.image,
        parentId: parentId ?? this.parentId,
        type: type ?? this.type,
        badge: badge ?? this.badge,
        sortOrder: sortOrder ?? this.sortOrder,
        isActive: isActive ?? this.isActive,
        children: children ?? this.children,
        productsCount: productsCount ?? this.productsCount,
      );
}

/// نموذج عنصر السلة
class CartItem {
  final String id;
  final Product product;
  final int quantity;
  final String selectedColor;
  final String selectedSize;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.selectedColor,
    required this.selectedSize,
  });

  double get totalPrice => product.price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id']?.toString() ?? '',
        product: Product.fromJson(json['product'] ?? {}),
        quantity: json['quantity'] ?? 1,
        selectedColor: json['selected_color'] ?? '',
        selectedSize: json['selected_size'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'product': product.toJson(),
        'quantity': quantity,
        'selected_color': selectedColor,
        'selected_size': selectedSize,
      };

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    String? selectedColor,
    String? selectedSize,
  }) =>
      CartItem(
        id: id ?? this.id,
        product: product ?? this.product,
        quantity: quantity ?? this.quantity,
        selectedColor: selectedColor ?? this.selectedColor,
        selectedSize: selectedSize ?? this.selectedSize,
      );
}

/// حالة الطلب
enum OrderStatus {
  pending('قيد المعالجة', 'pending'),
  processing('قيد المعالجة', 'processing'),
  shipped('قيد الشحن', 'shipped'),
  delivered('مكتمل', 'delivered'),
  cancelled('ملغي', 'cancelled');

  final String arabicName;
  final String englishName;
  const OrderStatus(this.arabicName, this.englishName);

  static OrderStatus fromString(String status) {
    return OrderStatus.values.firstWhere(
      (e) => e.englishName == status || e.arabicName == status,
      orElse: () => OrderStatus.pending,
    );
  }
}

/// نموذج الطلب
class Order {
  final String id;
  final String orderNumber;
  final String orderType;
  final DateTime date;
  final List<CartItem> items;
  final double subtotal;
  final double shipping;
  final double total;
  final OrderStatus status;
  final Address address;
  final String paymentMethod;

  Order({
    required this.id,
    required this.orderNumber,
    this.orderType = 'طلب شراء',
    required this.date,
    required this.items,
    required this.subtotal,
    required this.shipping,
    required this.total,
    required this.status,
    required this.address,
    required this.paymentMethod,
  });

  int get itemsCount => items.fold(0, (sum, item) => sum + item.quantity);

  String get currencySymbol {
    if (items.isNotEmpty) {
      return items.first.product.currencySymbol;
    }
    return 'ر.ي';
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final method = json['payment_method'] ?? '';
    String defaultType = 'طلب شراء عادي';
    if (method.toString().contains('أم فلوس') || method.toString() == 'am_flous') {
      defaultType = 'حوالة - محفظة أم فلوس';
    } else if (method.toString().contains('القطيبي') || method.toString() == 'qutaibi') {
      defaultType = 'حوالة - محفظة القطيبي';
    } else if (method.toString().contains('حوالة')) {
      defaultType = 'إرسال حوالة مباشرة';
    }

    return Order(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number'] ?? '',
      orderType: json['order_type'] ?? json['type'] ?? defaultType,
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      items: (json['items'] as List?)
              ?.map((e) => CartItem.fromJson(e))
              .toList() ??
          [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      shipping: (json['shipping'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      status: OrderStatus.fromString(json['status'] ?? 'pending'),
      address: Address.fromJson(json['address'] ?? {}),
      paymentMethod: method,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_number': orderNumber,
        'order_type': orderType,
        'date': date.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
        'subtotal': subtotal,
        'shipping': shipping,
        'total': total,
        'status': status.englishName,
        'address': address.toJson(),
        'payment_method': paymentMethod,
      };
}

/// نموذج العنوان
class Address {
  final String id;
  final String city;
  final String district;
  final String street;
  final String phone;
  final bool isDefault;

  Address({
    required this.id,
    required this.city,
    required this.district,
    required this.street,
    required this.phone,
    this.isDefault = false,
  });

  String get fullAddress => '$city، $district، $street';

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['id']?.toString() ?? '',
        city: json['city'] ?? '',
        district: json['district'] ?? '',
        street: json['street'] ?? '',
        phone: json['phone'] ?? '',
        isDefault: json['is_default'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'city': city,
        'district': district,
        'street': street,
        'phone': phone,
        'is_default': isDefault,
      };

  Address copyWith({
    String? id,
    String? city,
    String? district,
    String? street,
    String? phone,
    bool? isDefault,
  }) =>
      Address(
        id: id ?? this.id,
        city: city ?? this.city,
        district: district ?? this.district,
        street: street ?? this.street,
        phone: phone ?? this.phone,
        isDefault: isDefault ?? this.isDefault,
      );
}

/// نموذج البانر (AppBanner) - يظهر كسلايدر في الصفحة الرئيسية
class AppBanner {
  final String id;
  final String title;
  final String image;
  final String link;
  final int sortOrder;

  AppBanner({
    required this.id,
    required this.title,
    this.image = '',
    this.link = '',
    this.sortOrder = 0,
  });

  factory AppBanner.fromJson(Map<String, dynamic> json) => AppBanner(
        id: json['id']?.toString() ?? '',
        title: json['title'] ?? '',
        image: json['image'] ?? '',
        link: json['link'] ?? '',
        sortOrder: json['sort_order'] is num ? (json['sort_order'] as num).toInt() : 0,
      );
}