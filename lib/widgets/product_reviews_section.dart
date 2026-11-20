// ============================================
// قسم تقييمات ومراجعات العملاء + دليل المقاسات + عارض الصور المكبّر (نمط SHEIN)
// Product Reviews Section, Size Guide & Fullscreen Zoomable Gallery
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';

/// عارض صور المنتج بملء الشاشة مع التكبير باللمس (Pinch-to-Zoom)
class FullscreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullscreenImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.images.length}'),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.images[index],
                fit: BoxFit.contain,
                placeholder: (_, __) => const CircularProgressIndicator(
                  color: Colors.white,
                ),
                errorWidget: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// نافذة دليل المقاسات بنمط SHEIN
void showSizeGuideSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.straighten, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'دليل المقاسات (بالسنتيمتر)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: AppColors.borderLight),
            children: const [
              TableRow(
                decoration: BoxDecoration(color: Color(0xFFF3F4F6)),
                children: [
                  _SizeCell('المقاس', isHeader: true),
                  _SizeCell('الصدر', isHeader: true),
                  _SizeCell('الخصر', isHeader: true),
                  _SizeCell('الطول', isHeader: true),
                ],
              ),
              TableRow(children: [
                _SizeCell('S', isHeader: true),
                _SizeCell('86 - 90'),
                _SizeCell('66 - 70'),
                _SizeCell('135'),
              ]),
              TableRow(children: [
                _SizeCell('M', isHeader: true),
                _SizeCell('90 - 94'),
                _SizeCell('70 - 74'),
                _SizeCell('138'),
              ]),
              TableRow(children: [
                _SizeCell('L', isHeader: true),
                _SizeCell('94 - 100'),
                _SizeCell('74 - 80'),
                _SizeCell('141'),
              ]),
              TableRow(children: [
                _SizeCell('XL', isHeader: true),
                _SizeCell('100 - 106'),
                _SizeCell('80 - 86'),
                _SizeCell('144'),
              ]),
              TableRow(children: [
                _SizeCell('XXL', isHeader: true),
                _SizeCell('106 - 112'),
                _SizeCell('86 - 92'),
                _SizeCell('147'),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'ملاحظة: قد يختلف القياس بمقدار 1 إلى 2 سم حسب نوع القماش.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class _SizeCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  const _SizeCell(this.text, {this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

/// قسم تقييمات ومراجعات العملاء في صفحة تفاصيل المنتج
class ProductReviewsSection extends ConsumerStatefulWidget {
  final String productId;

  const ProductReviewsSection({super.key, required this.productId});

  @override
  ConsumerState<ProductReviewsSection> createState() =>
      _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends ConsumerState<ProductReviewsSection> {
  List<ProductReview> _reviews = [];
  Map<String, int> _fitCounts = {'small': 0, 'true_to_size': 0, 'large': 0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final data =
          await ref.read(apiClientProvider).getProductReviews(widget.productId);
      final list = (data['reviews'] as List? ?? [])
          .map((e) => ProductReview.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final summary = data['summary'] as Map? ?? {};
      final fit = summary['size_fit'] as Map? ?? {};
      if (mounted) {
        setState(() {
          _reviews = list;
          _fitCounts = {
            'small': int.tryParse(fit['small']?.toString() ?? '0') ?? 0,
            'true_to_size':
                int.tryParse(fit['true_to_size']?.toString() ?? '0') ?? 0,
            'large': int.tryParse(fit['large']?.toString() ?? '0') ?? 0,
          };
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openAddReviewDialog() {
    final isAuth = ref.read(authProvider).isAuthenticated;
    if (!isAuth) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء تسجيل الدخول لإضافة تقييمك'),
          backgroundColor: AppColors.error,
        ),
      );
      context.push('/login');
      return;
    }

    int selectedRating = 5;
    String selectedFit = 'true_to_size';
    final commentCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'أضف تقييمك للمنتج',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    return IconButton(
                      icon: Icon(
                        star <= selectedRating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: Colors.amber,
                        size: 36,
                      ),
                      onPressed: () =>
                          setSheetState(() => selectedRating = star),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'كيف كان المقاس؟',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('أصغر من المعتاد'),
                    selected: selectedFit == 'small',
                    onSelected: (_) =>
                        setSheetState(() => selectedFit = 'small'),
                  ),
                  ChoiceChip(
                    label: const Text('مناسب تماماً'),
                    selected: selectedFit == 'true_to_size',
                    onSelected: (_) =>
                        setSheetState(() => selectedFit = 'true_to_size'),
                  ),
                  ChoiceChip(
                    label: const Text('أكبر من المعتاد'),
                    selected: selectedFit == 'large',
                    onSelected: (_) =>
                        setSheetState(() => selectedFit = 'large'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'اكتب رأيك حول الخامة والجودة والمقاس...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setSheetState(() => isSubmitting = true);
                          try {
                            await ref
                                .read(apiClientProvider)
                                .submitProductReview(
                                  productId: widget.productId,
                                  rating: selectedRating,
                                  comment: commentCtrl.text.trim(),
                                  sizeFit: selectedFit,
                                );
                            if (ctx.mounted) Navigator.pop(ctx);
                            await _loadReviews();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('شكراً لك! تم حفظ تقييمك بنجاح'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            setSheetState(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تعذر إرسال التقييم حالياً'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'نشر التقييم',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalFit =
        (_fitCounts['small'] ?? 0) +
        (_fitCounts['true_to_size'] ?? 0) +
        (_fitCounts['large'] ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'آراء وتقييمات العملاء (${_reviews.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _openAddReviewDialog,
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text('أضف تقييمك'),
            ),
          ],
        ),
        if (totalFit > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ملاءمة المقاس حسب آراء المشترين',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _FitBar(
                  label: 'أصغر من المعتاد',
                  percent: (_fitCounts['small'] ?? 0) / totalFit,
                ),
                _FitBar(
                  label: 'مناسب تماماً',
                  percent: (_fitCounts['true_to_size'] ?? 0) / totalFit,
                  highlight: true,
                ),
                _FitBar(
                  label: 'أكبر من المعتاد',
                  percent: (_fitCounts['large'] ?? 0) / totalFit,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'لا توجد تقييمات بعد. كن أول من يقيّم هذا المنتج!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondaryLight),
            ),
          )
        else
          ..._reviews.take(5).map((r) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              r.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (r.isVerifiedPurchase) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'شراء موثق ✓',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          DateFormat('yyyy/MM/dd').format(r.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < r.rating ? Icons.star : Icons.star_border,
                            size: 14,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'المقاس: ${r.sizeFitLabel}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    if (r.comment.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        r.comment,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ],
                  ],
                ),
              )),
      ],
    );
  }
}

class _FitBar extends StatelessWidget {
  final String label;
  final double percent;
  final bool highlight;

  const _FitBar({
    required this.label,
    required this.percent,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 105,
            child: Text(label, style: const TextStyle(fontSize: 11)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  highlight ? AppColors.success : Colors.grey[600]!,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 34,
            child: Text(
              '${(percent * 100).round()}%',
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
