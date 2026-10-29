import 'package:flutter/material.dart';

class AppColors {
  // ألوان العلامة التجارية — ديناميكية وتتغير عند اختيار لون جديد
  // من شاشة مكتبة الألوان (Theme Color Screen) عبر ThemeColorNotifier
  static Color primary = const Color(0xFF7C3AED); // بنفسجي (الافتراضي)
  static Color primaryAccent = const Color(0xFF3B82F6); // أزرق (مشتق)
  static Color secondaryAccent = const Color(0xFF8B5CF6); // بنفسجي فاتح (مشتق)

  /// درجة داكنة مشتقة تلقائياً من اللون الأساسي (تُستخدم في التدرجات اللونية)
  static Color get primaryDark => HSLColor.fromColor(primary)
      .withLightness((HSLColor.fromColor(primary).lightness - 0.18).clamp(0.0, 1.0))
      .toColor();

  static const Color backgroundLight = Color(0xFFFFFFFF); // أبيض
  static const Color cardLight = Color(0xFFF8FAFC); // رمادي فاتح للبطاقات
  static const Color textPrimaryLight = Color(0xFF1F2937);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E7EB);
  
  static const Color backgroundDark = Color(0xFF111827);
  static const Color cardDark = Color(0xFF1F2937);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color borderDark = Color(0xFF374151);
  
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
}
