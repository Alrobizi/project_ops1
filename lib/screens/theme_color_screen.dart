// ============================================
// شاشة اختيار لون التطبيق (Theme Color Screen)
// تتضمن مكتبة ألوان متكاملة (flutter_colorpicker)
// تسمح للمستخدم باختيار لونه المفضل وتطبيقه على كافة الفلاتر واجهات التطبيق
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../providers/app_providers.dart';

/// كلاس يعبر عن لون جاهز مسبقاً في مكتبة الألوان
class AppColorOption {
  final String name;
  final Color color;
  final Color darkColor;
  final String category;

  const AppColorOption({
    required this.name,
    required this.color,
    required this.darkColor,
    this.category = 'كلاسيكي',
  });
}

/// قائمة الألوان المميزة المتاحة كخيارات سريعة
const List<AppColorOption> appColorPresets = [
  AppColorOption(name: 'بنفسجي ملكي', color: Color(0xFF7C3AED), darkColor: Color(0xFF5B21B6), category: 'الأصل'),
  AppColorOption(name: 'أزرق كلاسيك', color: Color(0xFF2563EB), darkColor: Color(0xFF1D4ED8), category: 'هادئ'),
  AppColorOption(name: 'أخضر زمردي', color: Color(0xFF059669), darkColor: Color(0xFF047857), category: 'طبيعة'),
  AppColorOption(name: 'أحمر ياقوتي', color: Color(0xFFDC2626), darkColor: Color(0xFFB91C1C), category: 'قوي'),
  AppColorOption(name: 'برتقالي دافئ', color: Color(0xFFEA580C), darkColor: Color(0xFFC2410C), category: 'حيوي'),
  AppColorOption(name: 'وردي جذاب', color: Color(0xFFDB2777), darkColor: Color(0xFFBE185D), category: 'عصري'),
  AppColorOption(name: 'سماوي منعش', color: Color(0xFF0284C7), darkColor: Color(0xFF0369A1), category: 'هادئ'),
  AppColorOption(name: 'نيلي فاخر', color: Color(0xFF4F46E5), darkColor: Color(0xFF4338CA), category: 'ملك'),
  AppColorOption(name: 'تركوازي بحري', color: Color(0xFF0D9488), darkColor: Color(0xFF0F766E), category: 'طبيعة'),
  AppColorOption(name: 'ذهبي متألق', color: Color(0xFFD97706), darkColor: Color(0xFFB45309), category: 'فاخر'),
  AppColorOption(name: 'عنابي داكن', color: Color(0xFF881337), darkColor: Color(0xFF4C0519), category: 'فاخر'),
  AppColorOption(name: 'زيتي كلاسيكي', color: Color(0xFF3F6212), darkColor: Color(0xFF1E293B), category: 'طبيعة'),
];

class ThemeColorScreen extends ConsumerStatefulWidget {
  const ThemeColorScreen({super.key});

  @override
  ConsumerState<ThemeColorScreen> createState() => _ThemeColorScreenState();
}

class _ThemeColorScreenState extends ConsumerState<ThemeColorScreen> with SingleTickerProviderStateMixin {
  late Color _currentColor;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // جلب اللون الحالي للتطبيق من Riverpod Provider
    final initialTheme = ref.read(themeColorProvider);
    _currentColor = initialTheme.primaryColor;

    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// تحويل اللون إلى كود Hex
  String _toHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  /// فتح نافذة مكتبة الألوان التفاعلية (Full Color Picker Dialog)
  void _openCustomColorPickerDialog() {
    Color tempColor = _currentColor;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.palette, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'عجلة الألوان المخصصة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              onColorChanged: (color) {
                tempColor = color;
              },
              pickerAreaHeightPercent: 0.7,
              enableAlpha: false,
              displayThumbColor: true,
              labelTypes: const [ColorLabelType.hex, ColorLabelType.rgb],
              pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(16)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: tempColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                setState(() {
                  _currentColor = tempColor;
                });
                Navigator.of(context).pop();
              },
              child: const Text('تأكيد الاختيار'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مكتبة الألوان والثيم'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // ============================================
          // 1. بطاقة معاينة اللون الحي (Live Interactive Preview)
          // ============================================
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _currentColor,
                    HSLColor.fromColor(_currentColor).withLightness(
                      (HSLColor.fromColor(_currentColor).lightness - 0.25).clamp(0.0, 1.0)
                    ).toColor(),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _currentColor.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'معاينة واجهة التطبيق',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Text(
                          _toHex(_currentColor),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.style, color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'اللون المفضل لديك',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // عينة من عناصر الواجهة بالفلاتر
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.shopping_bag, size: 16),
                        label: const Text('أزرار الشراء'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _currentColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.filter_alt, size: 16),
                        label: const Text('فلاتر البحث'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      Chip(
                        avatar: const Icon(Icons.check_circle, color: Colors.white, size: 16),
                        label: const Text('نشط الان', style: TextStyle(color: Colors.white, fontSize: 12)),
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ============================================
          // 2. شريط التبويب (Tabs: الألوان الجاهزة / التخصيص الكامل)
          // ============================================
          TabBar(
            controller: _tabController,
            labelColor: _currentColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: _currentColor,
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.grid_view), text: 'مكتبة الألوان'),
              Tab(icon: Icon(Icons.color_lens), text: 'منتقي الألوان'),
            ],
          ),

          // ============================================
          // 3. محتوى التبويبات
          // ============================================
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // التبويب الأول: شبكة الألوان الجاهزة
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'تشكيلة الألوان الجاهزة',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${appColorPresets.length} لون متاح',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.95,
                        ),
                        itemCount: appColorPresets.length,
                        itemBuilder: (context, index) {
                          final preset = appColorPresets[index];
                          final isSelected = _currentColor.toARGB32() == preset.color.toARGB32();

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentColor = preset.color;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected ? preset.color.withValues(alpha: 0.08) : AppColors.cardLight,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? preset.color : Colors.grey.withValues(alpha: 0.2),
                                  width: isSelected ? 2.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: preset.color.withValues(alpha: 0.25),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                    : [],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: preset.color,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: preset.color.withValues(alpha: 0.35),
                                          blurRadius: 6,
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
                                    preset.name,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? preset.color : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // التبويب الثاني: أدوات flutter_colorpicker والتخصيص المباشر
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // زر فتح نافذة عجلة الألوان التفاعلية
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _currentColor,
                            child: const Icon(Icons.colorize, color: Colors.white),
                          ),
                          title: const Text('فتـح عجلة الألوان الكاملة (Wheel)'),
                          subtitle: const Text('اختر أي لون مخصص بدقة عالية جداً'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _openCustomColorPickerDialog,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // منتقي المربعات السريع (BlockPicker)
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'لوحة درجات Material Design',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 12),
                              BlockPicker(
                                pickerColor: _currentColor,
                                onColorChanged: (color) {
                                  setState(() {
                                    _currentColor = color;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ============================================
          // 4. زر التطبيق والحفظ السفلي
          // ============================================
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () async {
                  // حفظ اللون في State & SharedPreferences
                  await ref.read(themeColorProvider.notifier).setColor(_currentColor);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم تطبيق اللون الجديد (${_toHex(_currentColor)}) بنجاح على التطبيق'),
                        backgroundColor: _currentColor,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    context.pop();
                  }
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  'تطبيق وحفظ اللون المفضل',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}