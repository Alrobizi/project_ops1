// ============================================
// واجهة فلتر الموقع الجغرافي (Location Filter UI)
// قائمة منسدلة + خيار GPS للموقع الحالي
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/location/app_locations.dart';
import '../providers/app_providers.dart';
import '../services/location_service.dart';

/// فتح نافذة اختيار الموقع الجغرافي:
/// - "استخدام موقعي الحالي (GPS)" لجلب موقع المشتري تلقائياً
/// - قائمة المحافظات اليمنية (عدن أولاً) مع مديريات عدن الثمانية
Future<void> showLocationFilterSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const LocationFilterSheet(),
  );
}

class LocationFilterSheet extends ConsumerStatefulWidget {
  const LocationFilterSheet({super.key});

  @override
  ConsumerState<LocationFilterSheet> createState() => _LocationFilterSheetState();
}

class _LocationFilterSheetState extends ConsumerState<LocationFilterSheet> {
  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationFilterProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // مقبض النافذة
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // العنوان + حالة التحميل
            Row(
              children: [
                Icon(Icons.location_on, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'اختيار الموقع',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (location.isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'يتم ترتيب المنتجات حسب الأقرب لموقعك المختار',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),

            // =====================================================
            // خيار "استخدام موقعي الحالي" (Dynamic Geolocation - GPS)
            // =====================================================
            _GpsOptionCard(
              isActive: location.mode == LocationFilterMode.gps,
              onTap: _handleUseGps,
            ),

            // رسالة خطأ GPS إن وجدت
            if (location.error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location.error!,
                        style: const TextStyle(fontSize: 12, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // =====================================================
            // قائمة المحافظات اليمنية (عدن والمدن المجاورة/اليمنية)
            // =====================================================
            const Text(
              'اختر المحافظة (اليمن)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: yemenGovernorates.length,
                itemBuilder: (context, index) {
                  final governorate = yemenGovernorates[index];
                  final isSelected = location.governorate == governorate.name &&
                      location.mode == LocationFilterMode.defaultCity;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // صف المحافظة
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          ref
                              .read(locationFilterProvider.notifier)
                              .selectGovernorate(governorate.name);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondaryLight,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                governorate.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              const Spacer(),
                              // مسافة المحافظة عن الموقع الحالي
                              FutureBuilder<double>(
                                future: Future.value(LocationService.distanceKm(
                                  location.latitude,
                                  location.longitude,
                                  governorate.latitude,
                                  governorate.longitude,
                                )),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) return const SizedBox();
                                  return Text(
                                    formatDistance(snapshot.data!),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondaryLight,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // مديريات عدن الثمانية تظهر كشرائح عند اختيار عدن
                      if (governorate.isDefault) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(right: 30),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: adenDistricts.map((district) {
                              final isCitySelected =
                                  location.city == district.name &&
                                      location.governorate == 'عدن' &&
                                      location.mode == LocationFilterMode.defaultCity;
                              return GestureDetector(
                                onTap: () {
                                  ref
                                      .read(locationFilterProvider.notifier)
                                      .selectCity(district.name);
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isCitySelected
                                        ? AppColors.primary
                                        : AppColors.cardLight,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isCitySelected
                                          ? AppColors.primary
                                          : AppColors.borderLight,
                                    ),
                                  ),
                                  child: Text(
                                    district.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isCitySelected
                                          ? Colors.white
                                          : AppColors.textPrimaryLight,
                                      fontWeight: isCitySelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// معالج تفعيل "استخدام موقعي الحالي" عبر GPS
  Future<void> _handleUseGps() async {
    final notifier = ref.read(locationFilterProvider.notifier);
    final success = await notifier.useGpsLocation();

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: const Text('تم تحديد موقعك الحالي - سيتم عرض المنتجات القريبة أولاً'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
    // عند الفشل تبقى النافذة مفتوحة لعرض رسالة الخطأ داخلها
  }
}

/// ودجة فلتر الموقع المعروضة في رأس الشاشة الرئيسية:
/// تعرض الموقع الحالي (عدن - كريتر افتراضياً أو "موقعي الحالي")
/// وتفتح نافذة اختيار الموقع عند الضغط عليها.
class LocationFilterChip extends ConsumerWidget {
  const LocationFilterChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationFilterProvider);

    return GestureDetector(
      onTap: () => showLocationFilterSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              location.mode == LocationFilterMode.gps
                  ? Icons.my_location
                  : Icons.location_on_outlined,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Text(
                location.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة خيار "استخدام موقعي الحالي" (GPS)
class _GpsOptionCard extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _GpsOptionCard({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.1) : AppColors.cardLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.borderLight,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.my_location,
                size: 20,
                color: isActive ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'استخدام موقعي الحالي',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'تحديد موقعك تلقائياً عبر GPS وعرض المنتجات القريبة أولاً',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isActive ? Icons.check_circle : Icons.arrow_forward_ios,
              size: 18,
              color: isActive ? AppColors.primary : AppColors.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }
}
