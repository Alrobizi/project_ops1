class ApiConfig {
  /// IP السيرفر على الشبكة المحلية (للجوال الحقيقي المتصل بنفس الشبكة).
  /// للمحاكي (Emulator) استبدل هذا الثابت بـ '10.0.2.2'.
  static const String serverHost = '192.168.100.15';

  static String get baseUrl => 'http://$serverHost:8009/api';

  static const String banners = '/banners';
  static const String categories = '/categories';
  static const String products = '/products';
}