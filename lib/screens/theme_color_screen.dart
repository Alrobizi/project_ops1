// ============================================
// شاشة اختيار لون التطبيق (Theme Color Screen)
// مكتبة الألوان لاختيار اللون المناسب للتطبيق
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../providers/app_providers.dart';

/// قائمة الألوان المتاحة للتطبيق
class AppColorOption {
  final String name;
  final Color color;
  final Color darkColor;

  const AppColorOption({
    required this.name,
    required this.color,
    required this.darkColor,
  });
}

/// الألوان المتاحة
const List<AppColorOption> appColorOptions = [
  AppColorOption(name: 'بنفسجي', color: Color(0xFF7C3AED), darkColor: Color(0xFF5B21B6)),
  AppColorOption(name: 'أزرق', color: Color(0xFF3B82F6), darkColor: Color(0xFF1D4ED8)),
  AppColorOption(name: 'أخضر', color: Color(0xFF10B981), darkColor: Color(0xFF047857)),
  AppColorOption(name: 'أحمر', color: Color(0xFFEF4444), darkColor: Color(0xFFB91C1C)),
  AppColorOption(name: 'برتقالي', color: Color(0xFFF59E0B), darkColor: Color(0xFFB45309)),
  AppColorOption(name: 'وردي', color: Color(0xFFEC4899), darkColor: Color(0xFFBE185D)),
  AppColorOption(name: 'سماوي', color: Color(0xFF06B6D4), darkColor: Color(0xFF0E7490)),
  AppColorOption(name: 'نيلي', color: Color(0xFF6366F1), darkColor: Color(0xFF4338CA)),
  AppColorOption(name: 'تركوازي', color: Color(0xFF14B8A6), darkColor: Color(0xFF0F766E)),
  AppColorOption(name: 'ذهبي', color: Color(0xFFFBBF24), darkColor: Color(0xFFB45309)),
  AppColorOption(name: 'رمادي', color: Color(0xFF6B7280), darkColor: Color(0xFF374151)),
  AppColorOption(name: 'بني', color: Color(0xFF8B5CF6), darkColor: Color(0xFF6D28D9)),
];

class ThemeColorScreen extends ConsumerStatefulWidget {
  const ThemeColorScreen({super.key});

  @override
  ConsumerState<ThemeColorScreen> createState() => _ThemeColorScreenState();
}

class _ThemeColorScreenState extends ConsumerState<ThemeColorScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final selectedColor = appColorOptions[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('لون التطبيق'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معاينة اللون
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [selectedColor.color, selectedColor.darkColor],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'معاينة اللون',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedColor.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'زر رئيسي',
                          style: TextStyle(
                            color: selectedColor.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white),
                        ),
                        child: const Text(
                          'زر ثانوي',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // عنوان القسم
            const Text(
              'اختر لون التطبيق',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'اختر اللون الذي يناسب هوية متجرك',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),
            // شبكة الألوان
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: appColorOptions.length,
              itemBuilder: (context, index) {
                final option = appColorOptions[index];
                final isSelected = _selectedIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = index);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? option.color : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // دائرة اللون
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: option.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: option.color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 24)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          option.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? option.color : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // زر الحفظ
            ElevatedButton(
              onPressed: () {
                // حفظ اللون المحدد
                ref.read(themeColorProvider.notifier).setColor(selectedColor.color);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم تغيير لون التطبيق إلى ${selectedColor.name}'),
                    backgroundColor: selectedColor.color,
                  ),
                );
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedColor.color,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'حفظ اللون',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}