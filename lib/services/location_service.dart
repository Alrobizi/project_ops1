// ============================================
// خدمة معالجة الموقع الجغرافي (Location Handlers)
// GPS - المسافة - تكلفة وزمن التوصيل
// ============================================

import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/location/app_locations.dart';

/// نتيجة جلب الموقع عبر GPS
class GpsResult {
  final bool success;
  final Position? position;
  final String? errorMessage;

  const GpsResult({
    required this.success,
    this.position,
    this.errorMessage,
  });
}

/// عرض توصيل مُقدَّر (تكلفة + زمن) بناءً على المسافة
/// بين موقع البائع وموقع المشتري
class DeliveryQuote {
  final double distanceKm;
  final double fee;
  final String etaLabel;

  const DeliveryQuote({
    required this.distanceKm,
    required this.fee,
    required this.etaLabel,
  });
}

/// ============================================
/// خدمة الموقع الجغرافي الديناميكي (Dynamic Geolocation)
/// ============================================
class LocationService {
  LocationService._();

  // ---------------- الإعدادات الافتراضية للتوصيل ----------------
  // (قابلة للتعديل حسب تعرفة المتجر الفعلية بالريال اليمني)
  static const double baseFee = 500;           // تعرفة أساسية داخل عدن
  static const double perKmFee = 100;          // تعرفة إضافية لكل كيلومتر
  static const double sameCityFlatFee = 500;   // تعرفة ثابتة داخل نفس المدينة
  static const double freeShippingThreshold = 20000; // مجاناً فوق هذا المبلغ

  // ---------------------------------------------------------------
  // 1) التحديد الجغرافي الديناميكي (Dynamic Geolocation - GPS)
  // ---------------------------------------------------------------

  /// جلب موقع المستخدم الحالي عبر GPS بعد التأكد من الأذونات والخدمة.
  /// يُستخدم لخيار "استخدام موقعي الحالي" وعرض المنتجات القريبة
  /// (Nearest First) عند منح الإذن.
  static Future<GpsResult> getCurrentPosition() async {
    // التأكد من أن خدمات الموقع (GPS) مفعّلة على الجهاز
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const GpsResult(
        success: false,
        errorMessage: 'خدمات الموقع (GPS) غير مفعّلة، يرجى تفعيلها من الإعدادات',
      );
    }

    // طلب الإذن من المستخدم (ينبثق مربع منح الصلاحية تلقائياً)
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const GpsResult(
          success: false,
          errorMessage: 'تم رفض إذن الموقع، لا يمكن تحديد موقعك الحالي',
        );
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return const GpsResult(
        success: false,
        errorMessage: 'الإذن مرفوض نهائياً، يرجى تفعيله من إعدادات التطبيق',
      );
    }

    // جلب الإحداثيات بدقة عالية مع مهلة زمنية معقولة
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return GpsResult(success: true, position: position);
    } catch (e) {
      return GpsResult(success: false, errorMessage: 'تعذر تحديد الموقع: $e');
    }
  }

  /// فتح إعدادات التطبيق لتفعيل الإذن المرفوض نهائياً
  static Future<void> openAppPermissionSettings() =>
      Geolocator.openAppSettings();

  // ---------------------------------------------------------------
  // 2) حساب المسافة (Haversine) بين موقعين
  // ---------------------------------------------------------------

  /// المسافة بين نقطتين بالكيلومترات (صيغة Haversine)
  static double distanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _degToRad(lat2 - lat1);
    final double dLng = _degToRad(lng2 - lng1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// المسافة من الموقع الافتراضي للتطبيق (عدن - كريتر)
  static double distanceFromDefault(double lat, double lng) =>
      distanceKm(lat, lng, AppLocationDefaults.defaultLatitude,
          AppLocationDefaults.defaultLongitude);

  static double _degToRad(double deg) => deg * math.pi / 180.0;

  // ---------------------------------------------------------------
  // 3) تقدير تكلفة وزمن التوصيل (ربط موقع البائع والمشتري)
  // ---------------------------------------------------------------

  /// تقدير عرض التوصيل بناءً على المسافة بين موقع البائع
  /// وموقع المشتري المحدد، مع دعم مجانية الشحن حسب قيمة الطلب.
  static DeliveryQuote estimateDelivery({
    required double distanceKm,
    required double subtotal,
    String? sellerCity,
    String? buyerCity,
    double? feeOverride,
  }) {
    final String eta = _etaLabel(distanceKm);

    // مجانية التوصيل عند تجاوز حد الشحن المجاني
    if (subtotal >= freeShippingThreshold) {
      return DeliveryQuote(distanceKm: distanceKm, fee: 0, etaLabel: eta);
    }

    // تكلفة ممرَّرة من الخادم إن توفرت
    if (feeOverride != null) {
      return DeliveryQuote(distanceKm: distanceKm, fee: feeOverride, etaLabel: eta);
    }

    // حساب التعرفة: ثابتة داخل نفس المدينة، وإلا أساسي + لكل كم
    final bool sameCity =
        sellerCity != null && buyerCity != null && sellerCity == buyerCity;
    final double rawFee =
        sameCity ? sameCityFlatFee : baseFee + perKmFee * distanceKm;

    // تقريب التعرفة لأقرب 50 ريال يمني
    final double fee = (rawFee / 50).roundToDouble() * 50;

    return DeliveryQuote(distanceKm: distanceKm, fee: fee, etaLabel: eta);
  }

  /// وصف الزمن المتوقع للتوصيل حسب المسافة
  static String _etaLabel(double km) {
    if (km <= 10) return 'من 30 دقيقة إلى ساعة';
    if (km <= 50) return 'من ساعتين إلى 4 ساعات';
    if (km <= 200) return 'من يوم إلى يومين';
    return 'من يومين إلى 4 أيام';
  }

  // ---------------------------------------------------------------
  // 4) حفظ واسترجاع الموقع المختار (SharedPreferences)
  // ---------------------------------------------------------------

  static const String _keyUseGps = 'location_use_gps';
  static const String _keyGovernorate = 'location_governorate';
  static const String _keyCity = 'location_city';
  static const String _keyLat = 'location_lat';
  static const String _keyLng = 'location_lng';

  /// حفظ اختيار المستخدم للموقع (GPS أو مدينة مختارة)
  static Future<void> persistLocation({
    required bool useGps,
    required String governorate,
    required String city,
    required double latitude,
    required double longitude,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseGps, useGps);
    await prefs.setString(_keyGovernorate, governorate);
    await prefs.setString(_keyCity, city);
    await prefs.setDouble(_keyLat, latitude);
    await prefs.setDouble(_keyLng, longitude);
  }

  /// استرجاع الموقع المحفوظ مسبقاً (أو null عند أول تشغيل:
  /// عندها يستخدم التطبيق الافتراضي: اليمن - عدن - كريتر)
  static Future<SavedLocation?> loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final hasLat = prefs.getDouble(_keyLat) != null;
    if (!hasLat) return null;
    return SavedLocation(
      useGps: prefs.getBool(_keyUseGps) ?? false,
      governorate:
          prefs.getString(_keyGovernorate) ?? AppLocationDefaults.defaultGovernorate,
      city: prefs.getString(_keyCity) ?? AppLocationDefaults.defaultCity,
      latitude: prefs.getDouble(_keyLat) ?? AppLocationDefaults.defaultLatitude,
      longitude: prefs.getDouble(_keyLng) ?? AppLocationDefaults.defaultLongitude,
    );
  }
}

/// الموقع المحفوظ لجلسة المستخدم
class SavedLocation {
  final bool useGps;
  final String governorate;
  final String city;
  final double latitude;
  final double longitude;

  const SavedLocation({
    required this.useGps,
    required this.governorate,
    required this.city,
    required this.latitude,
    required this.longitude,
  });

  String get label => useGps ? 'موقعي الحالي' : '$governorate - $city';
}

/// أداة تنسيق لعرض المسافة بشكل مختصر (مثال: 2.4 كم أو 850 م)
String formatDistance(double km) {
  if (km < 1) return '${(km * 1000).round()} م';
  return '${km.toStringAsFixed(1)} كم';
}
