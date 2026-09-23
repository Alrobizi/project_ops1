// ============================================
// نماذج لوحة التحكم (Admin Models)
// Campaign, Ad, Promotion, Customer, Discount, Banner, Page, etc.
// ============================================

/// نموذج حملة تسويقية
class Campaign {
  final String id;
  final String title;
  final String type;
  final double budget;
  final int views;
  final int clicks;
  final bool isActive;

  Campaign({
    required this.id,
    required this.title,
    required this.type,
    this.budget = 0,
    this.views = 0,
    this.clicks = 0,
    this.isActive = true,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) => Campaign(
        id: json['id']?.toString() ?? '',
        title: json['title'] ?? '',
        type: json['type'] ?? '',
        budget: (json['budget'] ?? 0).toDouble(),
        views: json['views'] ?? 0,
        clicks: json['clicks'] ?? 0,
        isActive: json['is_active'] ?? true,
      );
}

/// نموذج إعلان
class Ad {
  final String id;
  final String title;
  final String platform;
  final String startDate;
  final String endDate;
  final bool isActive;

  Ad({
    required this.id,
    required this.title,
    this.platform = '',
    this.startDate = '',
    this.endDate = '',
    this.isActive = true,
  });

  factory Ad.fromJson(Map<String, dynamic> json) => Ad(
        id: json['id']?.toString() ?? '',
        title: json['title'] ?? '',
        platform: json['platform'] ?? '',
        startDate: json['start_date'] ?? '',
        endDate: json['end_date'] ?? '',
        isActive: json['is_active'] ?? true,
      );
}

/// نموذج عرض ترويجي
class Promotion {
  final String id;
  final String title;
  final String code;
  final int discountPercent;
  final int usedCount;
  final int maxUsage;
  final bool isActive;

  Promotion({
    required this.id,
    required this.title,
    this.code = '',
    this.discountPercent = 0,
    this.usedCount = 0,
    this.maxUsage = 100,
    this.isActive = true,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) => Promotion(
        id: json['id']?.toString() ?? '',
        title: json['title'] ?? '',
        code: json['code'] ?? '',
        discountPercent: json['discount_percent'] ?? 0,
        usedCount: json['used_count'] ?? 0,
        maxUsage: json['max_usage'] ?? 100,
        isActive: json['is_active'] ?? true,
      );
}

/// نموذج عميل
class Customer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String city;
  final String registerDate;
  final String lastOrderDate;
  final int ordersCount;
  final double totalSpent;
  final bool isActive;
  final bool isVip;
  final bool isNew;

  Customer({
    required this.id,
    required this.name,
    this.email = '',
    this.phone = '',
    this.city = '',
    this.registerDate = '',
    this.lastOrderDate = '',
    this.ordersCount = 0,
    this.totalSpent = 0,
    this.isActive = true,
    this.isVip = false,
    this.isNew = false,
  });

  double get averageOrderValue =>
      ordersCount > 0 ? totalSpent / ordersCount : 0;

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        city: json['city'] ?? '',
        registerDate: json['register_date'] ?? '',
        lastOrderDate: json['last_order_date'] ?? '',
        ordersCount: json['orders_count'] ?? 0,
        totalSpent: (json['total_spent'] ?? 0).toDouble(),
        isActive: json['is_active'] ?? true,
        isVip: json['is_vip'] ?? false,
        isNew: json['is_new'] ?? false,
      );
}

/// حالة الخصم
enum DiscountStatus { active, expired, scheduled }

/// نموذج خصم
class Discount {
  final String id;
  final String code;
  final String type;
  final double value;
  final double minOrder;
  final int usedCount;
  final int maxUsage;
  final String startDate;
  final String endDate;
  final DiscountStatus status;

  Discount({
    required this.id,
    required this.code,
    this.type = 'نسبة مئوية',
    this.value = 0,
    this.minOrder = 0,
    this.usedCount = 0,
    this.maxUsage = 100,
    this.startDate = '',
    this.endDate = '',
    this.status = DiscountStatus.active,
  });

  factory Discount.fromJson(Map<String, dynamic> json) => Discount(
        id: json['id']?.toString() ?? '',
        code: json['code'] ?? '',
        type: json['type'] ?? 'نسبة مئوية',
        value: (json['value'] ?? 0).toDouble(),
        minOrder: (json['min_order'] ?? 0).toDouble(),
        usedCount: json['used_count'] ?? 0,
        maxUsage: json['max_usage'] ?? 100,
        startDate: json['start_date'] ?? '',
        endDate: json['end_date'] ?? '',
        status: DiscountStatus.values.firstWhere(
          (e) => e.name == (json['status'] ?? 'active'),
          orElse: () => DiscountStatus.active,
        ),
      );
}

/// نموذج بانر
class BannerItem {
  final String id;
  final String title;
  final String link;
  final String image;
  final int sortOrder;
  final bool isActive;

  BannerItem({
    required this.id,
    required this.title,
    this.link = '',
    this.image = '',
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) => BannerItem(
        id: json['id']?.toString() ?? '',
        title: json['title'] ?? '',
        link: json['link'] ?? '',
        image: json['image'] ?? '',
        sortOrder:
            json['sort_order'] is num ? (json['sort_order'] as num).toInt() : 0,
        isActive: json['is_active'] ?? true,
      );
}

/// نموذج صفحة
class PageItem {
  final String id;
  final String title;
  final String content;

  PageItem({
    required this.id,
    required this.title,
    this.content = '',
  });

  factory PageItem.fromJson(Map<String, dynamic> json) => PageItem(
        id: json['id']?.toString() ?? '',
        title: json['title'] ?? '',
        content: json['content'] ?? '',
      );
}

/// نموذج إشعار
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String date;

  NotificationItem({
    required this.id,
    required this.title,
    this.body = '',
    this.date = '',
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: json['id']?.toString() ?? '',
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        date: json['date'] ?? '',
      );
}

/// نموذج سؤال شائع
class FaqItem {
  final String id;
  final String question;
  final String answer;

  FaqItem({
    required this.id,
    required this.question,
    this.answer = '',
  });

  factory FaqItem.fromJson(Map<String, dynamic> json) => FaqItem(
        id: json['id']?.toString() ?? '',
        question: json['question'] ?? '',
        answer: json['answer'] ?? '',
      );
}

/// نقطة بيانات المبيعات
class SalesDataPoint {
  final String label;
  final double value;

  SalesDataPoint({required this.label, required this.value});
}

/// مبيعات التصنيف
class CategorySales {
  final String categoryName;
  final double sales;
  final double percentage;

  CategorySales({
    required this.categoryName,
    required this.sales,
    this.percentage = 0,
  });
}

/// مبيعات المنتج
class ProductSales {
  final String name;
  final int unitsSold;
  final double revenue;
  final int stock;

  ProductSales({
    required this.name,
    this.unitsSold = 0,
    this.revenue = 0,
    this.stock = 0,
  });
}

/// طلب حديث
class RecentOrder {
  final String orderNumber;
  final String customerName;
  final double total;

  RecentOrder({
    required this.orderNumber,
    required this.customerName,
    this.total = 0,
  });
}

/// إعدادات المتجر
class StoreSettings {
  final String name;
  final String email;
  final String phone;
  final String address;
  final String description;
  final String currency;
  final String language;

  const StoreSettings({
    this.name = 'متجر',
    this.email = '',
    this.phone = '',
    this.address = '',
    this.description = '',
    this.currency = 'YER',
    this.language = 'ar',
  });

  StoreSettings copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? description,
    String? currency,
    String? language,
  }) =>
      StoreSettings(
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        description: description ?? this.description,
        currency: currency ?? this.currency,
        language: language ?? this.language,
      );
}

/// إعدادات الدفع
class PaymentSettings {
  final bool cashOnDelivery;
  final bool creditCard;
  final bool eWallet;
  final bool bankTransfer;
  final double minOrderAmount;
  final double transactionFee;

  const PaymentSettings({
    this.cashOnDelivery = true,
    this.creditCard = false,
    this.eWallet = false,
    this.bankTransfer = false,
    this.minOrderAmount = 0,
    this.transactionFee = 0,
  });

  PaymentSettings copyWith({
    bool? cashOnDelivery,
    bool? creditCard,
    bool? eWallet,
    bool? bankTransfer,
    double? minOrderAmount,
    double? transactionFee,
  }) =>
      PaymentSettings(
        cashOnDelivery: cashOnDelivery ?? this.cashOnDelivery,
        creditCard: creditCard ?? this.creditCard,
        eWallet: eWallet ?? this.eWallet,
        bankTransfer: bankTransfer ?? this.bankTransfer,
        minOrderAmount: minOrderAmount ?? this.minOrderAmount,
        transactionFee: transactionFee ?? this.transactionFee,
      );
}

/// شركة شحن
class ShippingCompany {
  final String id;
  final String name;
  final double cost;
  final bool isActive;

  ShippingCompany({
    required this.id,
    required this.name,
    this.cost = 0,
    this.isActive = true,
  });
}

/// إعدادات الشحن
class ShippingSettings {
  final double defaultCost;
  final double freeShippingThreshold;
  final int deliveryDays;
  final List<ShippingCompany> shippingCompanies;

  const ShippingSettings({
    this.defaultCost = 25,
    this.freeShippingThreshold = 200,
    this.deliveryDays = 3,
    this.shippingCompanies = const [],
  });

  ShippingSettings copyWith({
    double? defaultCost,
    double? freeShippingThreshold,
    int? deliveryDays,
    List<ShippingCompany>? shippingCompanies,
  }) =>
      ShippingSettings(
        defaultCost: defaultCost ?? this.defaultCost,
        freeShippingThreshold:
            freeShippingThreshold ?? this.freeShippingThreshold,
        deliveryDays: deliveryDays ?? this.deliveryDays,
        shippingCompanies: shippingCompanies ?? this.shippingCompanies,
      );
}

/// إعدادات الإشعارات
class NotificationSettings {
  final bool orderNotifications;
  final bool customerNotifications;
  final bool marketingNotifications;
  final bool stockNotifications;
  final bool pushNotifications;
  final bool emailNotifications;
  final bool smsNotifications;

  const NotificationSettings({
    this.orderNotifications = true,
    this.customerNotifications = true,
    this.marketingNotifications = false,
    this.stockNotifications = true,
    this.pushNotifications = true,
    this.emailNotifications = false,
    this.smsNotifications = false,
  });

  NotificationSettings copyWith({
    bool? orderNotifications,
    bool? customerNotifications,
    bool? marketingNotifications,
    bool? stockNotifications,
    bool? pushNotifications,
    bool? emailNotifications,
    bool? smsNotifications,
  }) =>
      NotificationSettings(
        orderNotifications: orderNotifications ?? this.orderNotifications,
        customerNotifications:
            customerNotifications ?? this.customerNotifications,
        marketingNotifications:
            marketingNotifications ?? this.marketingNotifications,
        stockNotifications: stockNotifications ?? this.stockNotifications,
        pushNotifications: pushNotifications ?? this.pushNotifications,
        emailNotifications: emailNotifications ?? this.emailNotifications,
        smsNotifications: smsNotifications ?? this.smsNotifications,
      );
}