// ============================================
// شاشات السلة والدفع والطلبات
// Cart, Checkout, Orders, Order Details, Order Success
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import '../widgets/common_widgets.dart';
import '../data/dummy_data.dart';

// ============================================
// شاشة سلة المشتريات (Cart Screen)
// ============================================
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    if (cart.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('سلة المشتريات'),
          centerTitle: true,
        ),
        body: EmptyState(
          icon: Icons.shopping_cart_outlined,
          title: 'السلة فارغة',
          subtitle: 'أضف منتجات إلى السلة للمتابعة',
          buttonText: 'ابدأ التسوق',
          onButtonPressed: () => context.go('/home'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('سلة المشتريات'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // بانر الشحن المجاني
          if (cartNotifier.remainingForFreeShipping > 0)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_shipping,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'أضف منتجات بقيمة ${cartNotifier.remainingForFreeShipping.toStringAsFixed(0)} ${cart.currencySymbol} للوصول للشحن المجاني',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: cart.subtotal / CartNotifier.freeShippingThreshold,
                    backgroundColor: AppColors.borderLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          // قائمة المنتجات
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return _CartItemCard(
                  item: item,
                  onQuantityChanged: (quantity) {
                    cartNotifier.updateQuantity(item.id, quantity);
                  },
                  onRemove: () {
                    cartNotifier.removeItem(item.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم حذف المنتج من السلة'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // ملخص الطلب
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                _SummaryRow(
                  label: 'المجموع الفرعي',
                  value: '${cart.subtotal.toStringAsFixed(0)} ${cart.currencySymbol}',
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'الشحن',
                  value: cart.shipping == 0
                      ? 'مجاناً'
                      : '${cart.shipping.toStringAsFixed(0)} ${cart.currencySymbol}',
                  valueColor: cart.shipping == 0 ? AppColors.success : null,
                ),
                const Divider(height: 24),
                _SummaryRow(
                  label: 'الإجمالي',
                  value: '${cart.total.toStringAsFixed(0)} ${cart.currencySymbol}',
                  isTotal: true,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'إتمام الطلب 🔒',
                  onPressed: () {
                    final isAuthenticated =
                        ref.read(authProvider).isAuthenticated;
                    if (!isAuthenticated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('الرجاء تسجيل الدخول لإتمام الطلب'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      context.push('/login');
                      return;
                    }
                    context.push('/checkout');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // صورة المنتج
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: item.product.image,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
          const SizedBox(width: 12),
          // تفاصيل المنتج
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (item.selectedColor.isNotEmpty || item.selectedSize.isNotEmpty)
                  Text(
                    'اللون: ${item.selectedColor} / المقاس: ${item.selectedSize}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.product.price.toStringAsFixed(0)} ${item.product.currencySymbol}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                    QuantitySelector(
                      quantity: item.quantity,
                      maxQuantity: item.product.stock,
                      onChanged: onQuantityChanged,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // زر الحذف
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal
                ? AppColors.textPrimaryLight
                : AppColors.textSecondaryLight,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: FontWeight.bold,
            color: valueColor ??
                (isTotal ? AppColors.primary : AppColors.textPrimaryLight),
          ),
        ),
      ],
    );
  }
}

// ============================================
// شاشة إتمام الطلب (Checkout Screen)
// ============================================
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  Address? _selectedAddress;
  String _paymentMethod = 'محفظة أم فلوس';
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _paymentOptions = [
    {
      'id': 'محفظة أم فلوس',
      'title': 'محفظة أم فلوس',
      'subtitle': 'خدمة دفع مباشر - تحويل آلي',
      'badge': 'دفع مباشر',
      'asset': 'assets/images/mfloos_logo.jpg',
      'color': const Color(0xFF6B3BA7),
      'accountInfo': 'رقم محفظة أم فلوس المتجر: 770000000',
    },
    {
      'id': 'محفظة القطيبي',
      'title': 'محفظة القطيبي',
      'subtitle': 'خدمة دفع مباشر (بنك القطيبي)',
      'badge': 'دفع مباشر',
      'asset': 'assets/images/qutaibi_logo.jpg',
      'color': const Color(0xFF8CC63F),
      'accountInfo': 'حساب القطيبي (لحظات): 12345678 - باسم المتجر',
    },
    {
      'id': 'إرسال حوالة مباشرة',
      'title': 'إرسال حوالة مباشرة',
      'subtitle': 'عبر شركات الصرافة والتحويلات',
      'badge': 'حوالة مصرفية',
      'icon': Icons.swap_horiz_rounded,
      'color': Colors.blue.shade700,
      'accountInfo': 'تحويل باسم: متجر النخبة الإلكتروني (صنعاء/عدن)',
    },
    {
      'id': 'الدفع عند الاستلام',
      'title': 'الدفع عند الاستلام',
      'subtitle': 'الدفع نقداً فور وصول الطلب',
      'badge': 'نقداً',
      'icon': Icons.payments_outlined,
      'color': Colors.amber.shade800,
      'accountInfo': null,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedAddress = DummyData.addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => DummyData.addresses.first,
    );
  }

  Future<void> _launchWhatsApp(Order order) async {
    const String adminPhone = '+967770000000';
    final itemsList = order.items
        .map((e) =>
            '  • ${e.product.name} × ${e.quantity} (${e.totalPrice.toStringAsFixed(0)} ${e.product.currencySymbol})')
        .join('\n');

    final String messageText = '''
📦 *طلب جديد - متجرنا الإلكتروني*
----------------------------------
🔢 *رقم الطلب:* ${order.orderNumber}
🏷️ *نوع الطلب:* ${order.orderType}
💳 *طريقة الدفع:* ${order.paymentMethod}
💰 *المبلغ الإجمالي:* ${order.total.toStringAsFixed(0)} ${order.currencySymbol}
----------------------------------
👤 *بيانات العميل:*
• الهاتف: ${order.address.phone}
• العنوان: ${order.address.city} - ${order.address.fullAddress}
----------------------------------
🛒 *قائمة المنتجات:*
$itemsList
----------------------------------
📄 *ملاحظة:* تم تسجيل هذا الطلب بنجاح في لوحة التحكم، يرجى إرفاق صورة/إشعار التحويل هنا لتأكيد الاعتماد.
''';

    final Uri whatsappUri = Uri.parse(
        "https://wa.me/$adminPhone?text=${Uri.encodeComponent(messageText)}");

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _confirmOrder() async {
    final isAuthenticated = ref.read(authProvider).isAuthenticated;
    if (!isAuthenticated) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء تسجيل الدخول لإتمام الطلب'),
          backgroundColor: AppColors.error,
        ),
      );
      context.push('/login');
      return;
    }

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار عنوان التوصيل'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    String orderType = 'طلب شراء عادي';
    if (_paymentMethod == 'محفظة أم فلوس') {
      orderType = 'حوالة - محفظة أم فلوس';
    } else if (_paymentMethod == 'محفظة القطيبي') {
      orderType = 'حوالة - محفظة القطيبي';
    } else if (_paymentMethod == 'إرسال حوالة مباشرة') {
      orderType = 'إرسال حوالة مباشرة';
    } else {
      orderType = 'الدفع عند الاستلام';
    }

    final cart = ref.read(cartProvider);
    final order = await ref.read(ordersProvider.notifier).createOrder(
          items: cart.items,
          address: _selectedAddress!,
          paymentMethod: _paymentMethod,
          orderType: orderType,
        );

    if (order != null && mounted) {
      if (_paymentMethod != 'الدفع عند الاستلام') {
        // إرسال تفاصيل الحوالة والطلب آلياً للواتساب واللوحة
        await _launchWhatsApp(order);
      }

      setState(() => _isProcessing = false);
      ref.read(cartProvider.notifier).clearCart();
      if (!mounted) return;
      context.pushReplacement('/order-success', extra: order);
    } else {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final selectedOption = _paymentOptions.firstWhere(
      (opt) => opt['id'] == _paymentMethod,
      orElse: () => _paymentOptions.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('إتمام الطلب'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان التوصيل
            const Text(
              'عنوان التوصيل',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...DummyData.addresses.map((address) {
              final isSelected = _selectedAddress?.id == address.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedAddress = address),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              address.city,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              address.fullAddress,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                            Text(
                              address.phone,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                ),
              );
            }),
            // زر إضافة عنوان جديد
            OutlinedButton.icon(
              onPressed: () {
                // TODO: إضافة عنوان جديد
              },
              icon: const Icon(Icons.add),
              label: const Text('إضافة عنوان جديد'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // طريقة الدفع UI/UX التفاعلية
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'طريقة الدفع والتحويل',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'خيارات الدفع المباشر',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // عرض أزرار وبطاقات طرق الدفع
            ..._paymentOptions.map((opt) {
              final String id = opt['id'];
              final bool isSelected = _paymentMethod == id;
              final Color brandColor = opt['color'] ?? AppColors.primary;
              final String? assetPath = opt['asset'];
              final IconData? iconData = opt['icon'];

              return GestureDetector(
                onTap: () => setState(() => _paymentMethod = id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? brandColor.withOpacity(0.08)
                        : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? brandColor : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: brandColor.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      // شعار المحفظة أو الأيقونة
                      Container(
                        width: 52,
                        height: 52,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? brandColor
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: assetPath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  assetPath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.account_balance_wallet,
                                          color: brandColor, size: 28),
                                ),
                              )
                            : Icon(iconData ?? Icons.payment,
                                color: brandColor, size: 28),
                      ),
                      const SizedBox(width: 14),
                      // الاسم والوصف
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  opt['title'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? brandColor
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: brandColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    opt['badge'] ?? '',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: brandColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              opt['subtitle'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // مؤشر التحديد
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? brandColor : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? brandColor
                                : Colors.grey.shade400,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }),

            // صندوق معلومات المحفظة المحددة والتحويل
            if (selectedOption['accountInfo'] != null) ...[
              Container(
                margin: const EdgeInsets.only(top: 4, bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade900),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedOption['accountInfo']!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'سيتم توجيهك مباشرة للواتساب لإرسال الإشعار وتثبيت الطلب في لوحة التحكم.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            // ملخص الطلب
            const Text(
              'ملخص الطلب',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'عدد المنتجات',
                    value: '${cart.itemsCount}',
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'المجموع الفرعي',
                    value:
                        '${cart.subtotal.toStringAsFixed(0)} ${cart.currencySymbol}',
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'الشحن',
                    value: cart.shipping == 0
                        ? 'مجاناً'
                        : '${cart.shipping.toStringAsFixed(0)} ${cart.currencySymbol}',
                  ),
                  const Divider(height: 24),
                  _SummaryRow(
                    label: 'الإجمالي',
                    value:
                        '${cart.total.toStringAsFixed(0)} ${cart.currencySymbol}',
                    isTotal: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // زر تأكيد الطلب
            CustomButton(
              text: _paymentMethod == 'الدفع عند الاستلام'
                  ? 'تأكيد الطلب'
                  : 'تأكيد الطلب وإرسال الحوالة عبر واتساب 📲',
              onPressed: _isProcessing ? null : _confirmOrder,
              isLoading: _isProcessing,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// شاشة نجاح الطلب (Order Success Screen)
// ============================================
class OrderSuccessScreen extends StatelessWidget {
  final Order order;

  const OrderSuccessScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة النجاح
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 80,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'تم تأكيد طلبك بنجاح! 🎉',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'رقم الطلب: ${order.orderNumber}',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'الإجمالي: ${order.total.toStringAsFixed(0)} ${order.currencySymbol}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 48),
              CustomButton(
                text: 'تتبع طلبي',
                onPressed: () => context.pushReplacement('/orders'),
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'العودة للرئيسية',
                isOutlined: true,
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// شاشة طلباتي (Orders Screen)
// ============================================
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = [
    'الكل',
    'قيد المعالجة',
    'قيد الشحن',
    'مكتمل',
    'ملغي',
  ];

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
    final ordersState = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلباتي'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondaryLight,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: ordersState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(ordersState.orders),
                _buildOrdersList(
                  ordersState.orders
                      .where((o) =>
                          o.status == OrderStatus.pending ||
                          o.status == OrderStatus.processing)
                      .toList(),
                ),
                _buildOrdersList(
                  ordersState.orders
                      .where((o) => o.status == OrderStatus.shipped)
                      .toList(),
                ),
                _buildOrdersList(
                  ordersState.orders
                      .where((o) => o.status == OrderStatus.delivered)
                      .toList(),
                ),
                _buildOrdersList(
                  ordersState.orders
                      .where((o) => o.status == OrderStatus.cancelled)
                      .toList(),
                ),
              ],
            ),
    );
  }

  Widget _buildOrdersList(List<Order> orders) {
    if (orders.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'لا توجد طلبات',
        subtitle: 'ستظهر طلباتك هنا',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _OrderCard(order: order);
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/order-details/${order.id}', extra: order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                OrderStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              DateFormat('yyyy/MM/dd').format(order.date),
              style: const TextStyle(
                color: AppColors.textSecondaryLight,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${order.itemsCount} منتج',
              style: const TextStyle(
                color: AppColors.textSecondaryLight,
                fontSize: 13,
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الإجمالي',
                  style: TextStyle(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                Text(
                  '${order.total.toStringAsFixed(0)} ${order.currencySymbol}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// شاشة تفاصيل الطلب (Order Details Screen)
// ============================================
class OrderDetailsScreen extends StatelessWidget {
  final Order order;

  const OrderDetailsScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('طلب ${order.orderNumber}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // حالة الطلب
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  OrderStatusBadge(status: order.status),
                  const SizedBox(height: 12),
                  Text(
                    'تاريخ الطلب: ${DateFormat('yyyy/MM/dd').format(order.date)}',
                    style: const TextStyle(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // خط زمني لحالة الطلب
            const Text(
              'تتبع الطلب',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTimeline(),
            const SizedBox(height: 24),
            // المنتجات
            const Text(
              'المنتجات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...order.items.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: item.product.image,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'الكمية: ${item.quantity}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${item.totalPrice.toStringAsFixed(0)} ${item.product.currencySymbol}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 24),
            // العنوان
            const Text(
              'عنوان التوصيل',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.address.fullAddress,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.address.phone,
                    style: const TextStyle(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // طريقة ونوع الدفع
            const Text(
              'تفاصيل نوع الطلب والدفع',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('طريقة الدفع: ',
                          style: TextStyle(color: AppColors.textSecondaryLight)),
                      Text(
                        order.paymentMethod,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('نوع الطلب: ',
                          style: TextStyle(color: AppColors.textSecondaryLight)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          order.orderType,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // ملخص الدفع
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'المجموع الفرعي',
                    value: '${order.subtotal.toStringAsFixed(0)} ${order.currencySymbol}',
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'الشحن',
                    value: order.shipping == 0
                        ? 'مجاناً'
                        : '${order.shipping.toStringAsFixed(0)} ${order.currencySymbol}',
                  ),
                  const Divider(height: 24),
                  _SummaryRow(
                    label: 'الإجمالي',
                    value: '${order.total.toStringAsFixed(0)} ${order.currencySymbol}',
                    isTotal: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // زر إعادة الطلب
            CustomButton(
              text: 'إعادة الطلب',
              isOutlined: true,
              onPressed: () {
                // TODO: إعادة الطلب
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    final steps = [
      {'title': 'تم تأكيد الطلب', 'status': OrderStatus.pending},
      {'title': 'قيد المعالجة', 'status': OrderStatus.processing},
      {'title': 'قيد الشحن', 'status': OrderStatus.shipped},
      {'title': 'تم التوصيل', 'status': OrderStatus.delivered},
    ];

    int currentStep = 0;
    switch (order.status) {
      case OrderStatus.pending:
        currentStep = 0;
        break;
      case OrderStatus.processing:
        currentStep = 1;
        break;
      case OrderStatus.shipped:
        currentStep = 2;
        break;
      case OrderStatus.delivered:
        currentStep = 3;
        break;
      case OrderStatus.cancelled:
        currentStep = -1;
        break;
    }

    if (order.status == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel, color: AppColors.error),
            SizedBox(width: 12),
            Text(
              'تم إلغاء هذا الطلب',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(steps.length, (index) {
        final isCompleted = index <= currentStep;
        final isLast = index == steps.length - 1;

        return Row(
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? AppColors.success
                        : AppColors.borderLight,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: isCompleted
                        ? AppColors.success
                        : AppColors.borderLight,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 40),
                child: Text(
                  steps[index]['title'] as String,
                  style: TextStyle(
                    fontWeight:
                        isCompleted ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted
                        ? AppColors.textPrimaryLight
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}