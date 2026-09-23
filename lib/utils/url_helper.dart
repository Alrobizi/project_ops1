import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// دالة مساعدة لتصحيح روابط الصور
/// على محاكي أندرويد، يتم استبدال 127.0.0.1 و localhost وعنوان الـ LAN
/// الخاص بالخادم بـ 10.0.2.2 (العنوان الذي يصل به المحاكي إلى جهاز التطوير)
String fixImageUrl(String url) {
  if (url.isEmpty) return url;
  if (!kIsWeb && Platform.isAndroid) {
    url = url.replaceFirst('http://127.0.0.1:', 'http://10.0.2.2:');
    url = url.replaceFirst('http://localhost:', 'http://10.0.2.2:');
    // يجب أن يطابق serverHost في lib/services/api_service.dart
    url = url.replaceFirst('http://192.168.100.15:', 'http://10.0.2.2:');
  }
  return url;
}
