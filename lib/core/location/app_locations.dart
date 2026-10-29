// ============================================
// الإعدادات الافتراضية للموقع الجغرافي للتطبيق
// Default Location Settings - اليمن / عدن
// ============================================
// ملاحظة: تم إلغاء أي إعدادات سابقة تعتمد المدن السعودية
// (الرياض / جدة) وتعيين اليمن - عدن (جنوب اليمن) كموقع افتراضي رئيسي
// لكافة الفلاتر وقوائم العرض في التطبيق.
// ============================================

/// نموذج موقع جغرافي موحد (محافظة / مدينة / مديرية / متجر)
class AppLocation {
  final String id;
  final String name;
  final String governorate;
  final double latitude;
  final double longitude;
  final bool isDefault;

  const AppLocation({
    required this.id,
    required this.name,
    required this.governorate,
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
  });
}

/// ============================================
/// الإعدادات الافتراضية (Default Settings)
/// ============================================
class AppLocationDefaults {
  AppLocationDefaults._();

  // الدولة الافتراضية: اليمن (جنوب اليمن)
  static const String country = 'اليمن';

  // المدينة الافتراضية الرئيسية: عدن
  static const String defaultGovernorate = 'عدن';

  // المديرية الافتراضية داخل عدن (مركز المتجر الرئيسي)
  static const String defaultCity = 'كريتر';

  // إحداثيات الموقع الافتراضي (عدن - كريتر) - تستخدم في الفلاتر
  // والفرز حسب الأقرب (Nearest First) عندما لا يكون GPS مفعلاً.
  static const double defaultLatitude = 12.7917;
  static const double defaultLongitude = 45.0067;

  /// اسم الموقع الافتراضي الكامل كما يظهر في واجهة المستخدم
  static const String defaultLabel = 'عدن - كريتر';

  /// موقع المتجر/البائع الرئيسي (متجر بركة عدن) - يستخدم في
  /// حساب المسافة وتقدير تكلفة وزمن التوصيل للمشتري.
  static const AppLocation storeLocation = AppLocation(
    id: 'store_main',
    name: 'متجر بركة عدن (الفرع الرئيسي)',
    governorate: 'عدن',
    latitude: defaultLatitude,
    longitude: defaultLongitude,
    isDefault: true,
  );
}

/// ============================================
/// المحافظات اليمنية (اليمن فقط - بدون أي مدن سعودية)
/// مرتبة بحيث تكون عدن أولاً ثم المحافظات المجاورة (لحج، أبين، تعز...)
/// الإحداثيات تقريبية لمراكز المحافظات وتستخدم في الفرز حسب الأقرب.
/// ============================================
const List<AppLocation> yemenGovernorates = [
  // ★ الافتراضي: عدن
  AppLocation(
    id: 'gov_aden',
    name: 'عدن',
    governorate: 'عدن',
    latitude: 12.7855,
    longitude: 45.0187,
    isDefault: true,
  ),
  // المحافظات المجاورة لعدن
  AppLocation(id: 'gov_lahj', name: 'لحج', governorate: 'لحج', latitude: 13.0306, longitude: 44.7667),
  AppLocation(id: 'gov_abyan', name: 'أبين', governorate: 'أبين', latitude: 13.6294, longitude: 45.0306),
  AppLocation(id: 'gov_dhale', name: 'ضالع', governorate: 'ضالع', latitude: 15.1733, longitude: 44.7400),
  AppLocation(id: 'gov_taqiz', name: 'تعز', governorate: 'تعز', latitude: 13.5789, longitude: 44.0219),
  // باقي المحافظات اليمنية
  AppLocation(id: 'gov_sanaa', name: 'صنعاء', governorate: 'صنعاء', latitude: 15.3694, longitude: 44.1910),
  AppLocation(id: 'gov_hodeidah', name: 'الحديدة', governorate: 'الحديدة', latitude: 14.7978, longitude: 42.9545),
  AppLocation(id: 'gov_ibb', name: 'إب', governorate: 'إب', latitude: 13.9661, longitude: 44.1847),
  AppLocation(id: 'gov_dhamar', name: 'ذمار', governorate: 'ذمار', latitude: 14.5400, longitude: 44.4000),
  AppLocation(id: 'gov_shabwa', name: 'شبوة', governorate: 'شبوة', latitude: 14.5333, longitude: 46.8500),
  AppLocation(id: 'gov_hadramout', name: 'حضرموت', governorate: 'حضرموت', latitude: 14.5426, longitude: 49.1272),
  AppLocation(id: 'gov_mareb', name: 'مأرب', governorate: 'مأرب', latitude: 15.4625, longitude: 45.3266),
  AppLocation(id: 'gov_baidha', name: 'البيضاء', governorate: 'البيضاء', latitude: 14.3469, longitude: 45.5653),
  AppLocation(id: 'gov_raidah', name: 'الجوف', governorate: 'الجوف', latitude: 16.6000, longitude: 45.5000),
  AppLocation(id: 'gov_amran', name: 'عمران', governorate: 'عمران', latitude: 15.6608, longitude: 43.9903),
  AppLocation(id: 'gov_sada', name: 'صعدة', governorate: 'صعدة', latitude: 16.9400, longitude: 43.7600),
  AppLocation(id: 'gov_raymah', name: 'ريمة', governorate: 'ريمة', latitude: 14.6100, longitude: 43.6300),
  AppLocation(id: 'gov_mahrah', name: 'المهرّة', governorate: 'المهرّة', latitude: 16.5625, longitude: 52.2000),
  AppLocation(id: 'gov_socotra', name: 'سقطرى', governorate: 'سقطرى', latitude: 12.5000, longitude: 53.9167),
];

/// ============================================
/// مديريات عدن الثمانية (جنوب اليمن) - قائمة العرض الافتراضية
/// الإحداثيات تقريبية لمراكز المديريات.
/// ============================================
const List<AppLocation> adenDistricts = [
  // ★ الافتراضي: كريتر (مركز المتجر الرئيسي)
  AppLocation(
    id: 'aden_crater',
    name: 'كريتر',
    governorate: 'عدن',
    latitude: 12.7917,
    longitude: 45.0067,
    isDefault: true,
  ),
  AppLocation(id: 'aden_tawahi', name: 'التواهي', governorate: 'عدن', latitude: 12.7750, longitude: 45.0353),
  AppLocation(id: 'aden_maalla', name: 'المعلا', governorate: 'عدن', latitude: 12.7855, longitude: 45.0235),
  AppLocation(id: 'aden_khormaksar', name: 'خور مكسر', governorate: 'عدن', latitude: 12.7969, longitude: 45.0356),
  AppLocation(id: 'aden_shaikh_othman', name: 'الشيخ عثمان', governorate: 'عدن', latitude: 12.7822, longitude: 45.0569),
  AppLocation(id: 'aden_mansoura', name: 'المنصورة', governorate: 'عدن', latitude: 12.7853, longitude: 45.0631),
  AppLocation(id: 'aden_dar_saad', name: 'دار سعد', governorate: 'عدن', latitude: 12.7586, longitude: 45.0586),
  AppLocation(id: 'aden_bureiqa', name: 'بورمياء', governorate: 'عدن', latitude: 12.7667, longitude: 45.0556),
];

/// أداة مساعدة للبحث عن المواقع ضمن القوائم
class AppLocationResolver {
  AppLocationResolver._();

  /// البحث عن محافظة بالاسم (مع الرجوع للافتراضي عدن)
  static AppLocation findGovernorate(String name) {
    return yemenGovernorates.firstWhere(
      (g) => g.name == name,
      orElse: () => yemenGovernorates.first,
    );
  }

  /// البحث عن مديرية/مدينة بالاسم (مع الرجوع للافتراضي كريتر)
  static AppLocation findCity(String name) {
    return adenDistricts.firstWhere(
      (d) => d.name == name,
      orElse: () => adenDistricts.first,
    );
  }

  /// الموقع الافتراضي للتطبيق (عدن - كريتر)
  static AppLocation get defaultLocation => adenDistricts.first;
}
