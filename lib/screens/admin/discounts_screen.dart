// ============================================
// شاشة الخصومات (Discounts Screen)
// إدارة أكواد الخصم والعروض والكوبونات
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/admin_models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common_widgets.dart';

class DiscountsScreen extends ConsumerStatefulWidget {
  const DiscountsScreen({super.key});

  @override
  ConsumerState<DiscountsScreen> createState() => _DiscountsScreenState();
}

class _DiscountsScreenState extends ConsumerState<DiscountsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = ['الكل', 'نشطة', 'منتهية', 'مجدولة'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الخصومات'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondaryLight,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDiscountsList(adminState.discounts),
          _buildDiscountsList(
              adminState.discounts.where((d) => d.status == DiscountStatus.active).toList()),
          _buildDiscountsList(
              adminState.discounts.where((d) => d.status == DiscountStatus.expired).toList()),
          _buildDiscountsList(
              adminState.discounts.where((d) => d.status == DiscountStatus.scheduled).toList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDiscountDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDiscountsList(List<Discount> discounts) {
    if (discounts.isEmpty) {
      return const EmptyState(
        icon: Icons.local_offer_outlined,
        title: 'لا توجد خصومات',
        subtitle: 'أضف كود خصم جديد',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: discounts.length,
      itemBuilder: (context, index) {
        final discount = discounts[index];
        return _DiscountCard(
          discount: discount,
          onEdit: () {},
          onDelete: () {
            _showDeleteConfirm(context, discount.code, () {
              ref.read(adminProvider.notifier).deleteDiscount(discount.id);
            });
          },
          onToggle: () {
            ref.read(adminProvider.notifier).toggleDiscountStatus(discount.id);
          },
        );
      },
    );
  }

  void _showAddDiscountDialog(BuildContext context) {
    final codeController = TextEditingController();
    final valueController = TextEditingController();
    final minOrderController = TextEditingController();
    final maxUsageController = TextEditingController();
    String discountType = 'نسبة مئوية';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('كود خصم جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  label: 'كود الخصم',
                  hint: 'SAVE10',
                  controller: codeController,
                  prefixIcon: const Icon(Icons.confirmation_number),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: discountType,
                  decoration: InputDecoration(
                    labelText: 'نوع الخصم',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    prefixIcon: const Icon(Icons.percent),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'نسبة مئوية', child: Text('نسبة مئوية')),
                    DropdownMenuItem(value: 'مبلغ ثابت', child: Text('مبلغ ثابت')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => discountType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: discountType == 'نسبة مئوية' ? 'نسبة الخصم (%)' : 'مبلغ الخصم (ر.ي)',
                  controller: valueController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'الحد الأدنى للطلب (ر.ي)',
                  controller: minOrderController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.shopping_cart),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'الحد الأقصى للاستخدام',
                  controller: maxUsageController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.people),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (codeController.text.isNotEmpty &&
                    valueController.text.isNotEmpty) {
                  ref.read(adminProvider.notifier).addDiscount(
                        code: codeController.text.toUpperCase(),
                        type: discountType,
                        value: double.tryParse(valueController.text) ?? 0,
                        minOrder: double.tryParse(minOrderController.text) ?? 0,
                        maxUsage: int.tryParse(maxUsageController.text) ?? 100,
                      );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تمت إضافة كود الخصم بنجاح'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(
      BuildContext context, String code, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف كود "$code"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
            },
            child: const Text(
              'حذف',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// بطاقة خصم (Discount Card)
// ============================================
class _DiscountCard extends StatelessWidget {
  final Discount discount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _DiscountCard({
    required this.discount,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    switch (discount.status) {
      case DiscountStatus.active:
        statusColor = AppColors.success;
        statusText = 'نشط';
        break;
      case DiscountStatus.expired:
        statusColor = AppColors.error;
        statusText = 'منتهي';
        break;
      case DiscountStatus.scheduled:
        statusColor = AppColors.warning;
        statusText = 'مجدول';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // رأس البطاقة
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_offer,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          discount.code,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          discount.type == 'نسبة مئوية'
                              ? 'خصم ${discount.value.toStringAsFixed(0)}%'
                              : 'خصم ${discount.value.toStringAsFixed(0)} ر.ي',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // تفاصيل الخصم
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow(
                  Icons.calendar_today,
                  'الفترة',
                  '${discount.startDate} - ${discount.endDate}',
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.shopping_cart,
                  'الحد الأدنى للطلب',
                  '${discount.minOrder.toStringAsFixed(0)} ر.ي',
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.people,
                  'الاستخدام',
                  '${discount.usedCount}/${discount.maxUsage}',
                ),
                const SizedBox(height: 12),
                // شريط التقدم
                Row(
                  children: [
                    const Text(
                      'نسبة الاستخدام',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: discount.maxUsage > 0
                            ? discount.usedCount / discount.maxUsage
                            : 0,
                        backgroundColor: AppColors.borderLight,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${discount.maxUsage > 0 ? ((discount.usedCount / discount.maxUsage) * 100).toStringAsFixed(0) : 0}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // أزرار الإجراءات
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  onPressed: onToggle,
                  icon: Icon(
                    discount.status == DiscountStatus.active
                        ? Icons.pause
                        : Icons.play_arrow,
                    size: 18,
                  ),
                  label: Text(
                    discount.status == DiscountStatus.active ? 'إيقاف' : 'تفعيل',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.warning,
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('تعديل'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('حذف'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondaryLight),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}