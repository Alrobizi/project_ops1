// ============================================
// إعدادات المصادقة بواسطة Google
// تُستخدم في الويب (clientId) وفي أندرويد/iOS (serverClientId)
// ============================================

class GoogleAuthConfig {
  const GoogleAuthConfig._();

  /// معرّف عميل الويب (Web client ID) من Google Cloud Console.
  ///
  /// - على الويب: يُمرَّر كـ clientId (حزمة google_sign_in لا تدعم
  ///   serverClientId على الويب وتحتاج clientId أو وسم meta في index.html).
  /// - على أندرويد/iOS: يُمرَّر كـ serverClientId حتى يصدر Google
  ///   معرّف توكن (idToken) موجّه لخادمنا.
  ///
  /// ملاحظة: هذا المعرّف عام وليس سراً، ويجب إضافة أصل التطبيق
  /// (Authorized JavaScript origins) في Google Cloud Console.
  static const String webClientId =
      '866528014908-ubkmbauq5ffitlqvc1ffc37f0k92uff0.apps.googleusercontent.com';

  /// الصلاحيات المطلوبة من حساب Google
  static const List<String> scopes = <String>['email', 'profile'];
}
