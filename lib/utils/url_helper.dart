/// دالة مساعدة لتصحيح روابط الصور وتوجيهها إلى السيرفر السحابي
String fixImageUrl(String url) {
  if (url.isEmpty) return url;
  if (url.startsWith('/')) {
    return 'https://barakat-aden.onrender.com$url';
  }
  // استبدال أي عناوين محلية قديمة برابط السيرفر المباشر
  url = url.replaceFirst(
    RegExp(r'http://(127\.0\.0\.1|localhost|10\.0\.2\.2|192\.168\.\d+\.\d+)(:\d+)?'),
    'https://barakat-aden.onrender.com',
  );
  return url;
}
