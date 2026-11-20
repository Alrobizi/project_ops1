// ============================================
// نافذة الفرز والفلترة المتقدمة + قسم العروض السريعة (نمط SHEIN)
// Product Filter & Sort Sheet + Flash Sale Section
// ============================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../providers/app_providers.dart';

/// فتح نافذة الفرز والفلترة المتقدمة بنمط SHEIN
void showProductFilterSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const _ProductFilterSheetBody(),
  );
}

class _ProductFilterSheetBody extends ConsumerStatefulWidget {
  const _ProductFilterSheetBody();

  @override
  ConsumerState<_ProductFilterSheetBody> createState() =>
      _ProductFilterSheetBodyState();
}

class _ProductFilterSheetBodyState
    extends ConsumerState<_ProductFilterSheetBody> {
  late ProductSortOption _sortOption;
  late bool _onlyDiscounted;
  late bool _onlyInStock;
  late TextEditingController _minPriceCtrl;
  late TextEditingController _maxPriceCtrl;

  @override
  void initState() {
    super.initState();
    final state = ref.read(productsProvider);
    _sortOption = state.sortOption;
    _onlyDiscounted = state.onlyDiscounted;
    _onlyInStock = state.onlyInStock;
    _minPriceCtrl = TextEditingController(
      text: state.minPrice != null ? state.minPrice!.toStringAsFixed(0) : '',
    );
    _maxPriceCtrl = TextEditingController(
      text: state.maxPrice != null ? state.maxPrice!.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الفرز والفلترة',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(productsProvider.notifier).resetFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('إعادة ضبط'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'ترتيب حسب',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ProductSortOption.values.map((option) {
                final selected = _sortOption == option;
                return ChoiceChip(
                  label: Text(option.label),
                  selected: selected,
                  selectedColor: primary.withValues(alpha: 0.16),
                  labelStyle: TextStyle(
                    color: selected ? primary : AppColors.textPrimaryLight,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) => setState(() => _sortOption = option),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              'نطاق السعر',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPriceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'الحد الأدنى',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('—'),
                ),
                Expanded(
                  child: TextField(
                    controller: _maxPriceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'الحد الأقصى',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('العروض والخصومات فقط'),
              subtitle: const Text('إظهار المنتجات التي عليها تخفيض فقط'),
              value: _onlyDiscounted,
              activeThumbColor: primary,
              onChanged: (v) => setState(() => _onlyDiscounted = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('المتوفر في المخزون فقط'),
              value: _onlyInStock,
              activeThumbColor: primary,
              onChanged: (v) => setState(() => _onlyInStock = v),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  final minP = double.tryParse(_minPriceCtrl.text.trim());
                  final maxP = double.tryParse(_maxPriceCtrl.text.trim());
                  ref.read(productsProvider.notifier).applyFilters(
                        sortOption: _sortOption,
                        onlyDiscounted: _onlyDiscounted,
                        onlyInStock: _onlyInStock,
                        minPrice: minP,
                        maxPrice: maxP,
                        clearPriceRange: minP == null && maxP == null,
                      );
                  Navigator.pop(context);
                },
                child: const Text(
                  'تطبيق الفلترة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// قسم العروض السريعة (Flash Sale) بعدّاد تنازلي يومي بنمط SHEIN
class FlashSaleSection extends ConsumerStatefulWidget {
  const FlashSaleSection({super.key});

  @override
  ConsumerState<FlashSaleSection> createState() => _FlashSaleSectionState();
}

class _FlashSaleSectionState extends ConsumerState<FlashSaleSection> {
  Timer? _timer;
  Duration _remaining = _timeUntilMidnight();

  static Duration _timeUntilMidnight() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tomorrow.difference(now);
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _remaining = _timeUntilMidnight());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final discounted = ref.watch(productsProvider.notifier).discountedProducts;
    if (discounted.isEmpty) return const SizedBox.shrink();

    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on, color: Color(0xFFEF4444), size: 22),
                const SizedBox(width: 4),
                const Text(
                  'عروض اليوم السريعة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_two(hours)}:${_two(minutes)}:${_two(seconds)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                ref.read(productsProvider.notifier).applyFilters(
                      onlyDiscounted: true,
                      sortOption: ProductSortOption.biggestDiscount,
                    );
              },
              child: const Text('الكل'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 215,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: discounted.length > 10 ? 10 : discounted.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = discounted[index];
              final pct = product.discountPercent ?? 0;
              return GestureDetector(
                onTap: () => context.push('/product/${product.id}'),
                child: Container(
                  width: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(14),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: product.image,
                              height: 130,
                              width: 140,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                height: 130,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),
                          if (pct > 0)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '-$pct%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '${product.price.toStringAsFixed(0)} ${product.currencySymbol}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                if (product.oldPrice != null)
                                  Flexible(
                                    child: Text(
                                      product.oldPrice!.toStringAsFixed(0),
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[400],
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
