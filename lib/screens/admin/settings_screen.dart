// ============================================
// شاشة الإعدادات (Settings Screen)
// إعدادات المتجر والدفع والشحن والتكوين العام
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = ['المتجر', 'الدفع', 'الشحن', 'الإشعارات', 'الأمان'];

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
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
          _buildStoreTab(),
          _buildPaymentTab(),
          _buildShippingTab(),
          _buildNotificationsTab(),
          _buildSecurityTab(),
        ],
      ),
    );
  }

  // ============================================
  // تبويب إعدادات المتجر
  // ============================================
  Widget _buildStoreTab() {
    final settings = ref.watch(adminProvider).storeSettings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'معلومات المتجر',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'اسم المتجر',
            controller: TextEditingController(text: settings.name),
            prefixIcon: const Icon(Icons.store),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'البريد الإلكتروني',
            controller: TextEditingController(text: settings.email),
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'رقم الهاتف',
            controller: TextEditingController(text: settings.phone),
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(Icons.phone),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'العنوان',
            controller: TextEditingController(text: settings.address),
            prefixIcon: const Icon(Icons.location_on),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'الوصف',
            controller: TextEditingController(text: settings.description),
            maxLines: 3,
            prefixIcon: const Icon(Icons.description),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: settings.currency,
            decoration: InputDecoration(
              labelText: 'العملة',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              prefixIcon: const Icon(Icons.attach_money),
            ),
            items: const [
              DropdownMenuItem(value: 'YER', child: Text('ريال يمني (ر.ي)')),
              DropdownMenuItem(value: 'SAR', child: Text('ريال سعودي (ر.س)')),
              DropdownMenuItem(value: 'USD', child: Text('دولار أمريكي (\$)')),
            ],
            onChanged: (value) {
              if (value != null) {
                ref.read(adminProvider.notifier).updateStoreSetting(
                      'currency',
                      value,
                    );
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: settings.language,
            decoration: InputDecoration(
              labelText: 'اللغة الافتراضية',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              prefixIcon: const Icon(Icons.language),
            ),
            items: const [
              DropdownMenuItem(value: 'ar', child: Text('العربية')),
              DropdownMenuItem(value: 'en', child: Text('English')),
            ],
            onChanged: (value) {
              if (value != null) {
                ref.read(adminProvider.notifier).updateStoreSetting(
                      'language',
                      value,
                    );
              }
            },
          ),
          const SizedBox(height: 16),
          // رابط اختيار لون التطبيق
          GestureDetector(
            onTap: () => context.push('/theme-color'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.palette, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'لون التطبيق',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'اختر اللون المناسب لهوية متجرك',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textSecondaryLight,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'حفظ التغييرات',
            icon: Icons.save,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حفظ الإعدادات بنجاح'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================
  // تبويب إعدادات الدفع
  // ============================================
  Widget _buildPaymentTab() {
    final settings = ref.watch(adminProvider).paymentSettings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'طرق الدفع',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          _buildToggleItem(
            Icons.money,
            'الدفع عند الاستلام',
            'السماح بالدفع نقداً عند الاستلام',
            settings.cashOnDelivery,
            (value) => ref.read(adminProvider.notifier).updatePaymentSetting(
                  'cash_on_delivery',
                  value,
                ),
          ),
          const SizedBox(height: 12),
          _buildToggleItem(
            Icons.credit_card,
            'البطاقات الائتمانية',
            'فيزا، ماستركارد، مدى',
            settings.creditCard,
            (value) => ref.read(adminProvider.notifier).updatePaymentSetting(
                  'credit_card',
                  value,
                ),
          ),
          const SizedBox(height: 12),
          _buildToggleItem(
            Icons.account_balance_wallet,
            'المحافظ الإلكترونية',
            'محفظة، زين كاش، جاز كاش',
            settings.eWallet,
            (value) => ref.read(adminProvider.notifier).updatePaymentSetting(
                  'e_wallet',
                  value,
                ),
          ),
          const SizedBox(height: 12),
          _buildToggleItem(
            Icons.account_balance,
            'التحويل البنكي',
            'تحويل بنكي مباشر',
            settings.bankTransfer,
            (value) => ref.read(adminProvider.notifier).updatePaymentSetting(
                  'bank_transfer',
                  value,
                ),
          ),
          const SizedBox(height: 24),
          const Text(
            'إعدادات الدفع',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'الحد الأدنى للطلب (ر.ي)',
            controller:
                TextEditingController(text: settings.minOrderAmount.toString()),
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.shopping_cart),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'رسوم المعاملة (%)',
            controller:
                TextEditingController(text: settings.transactionFee.toString()),
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.percent),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'حفظ التغييرات',
            icon: Icons.save,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حفظ إعدادات الدفع'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================
  // تبويب إعدادات الشحن
  // ============================================
  Widget _buildShippingTab() {
    final settings = ref.watch(adminProvider).shippingSettings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إعدادات الشحن',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'تكلفة الشحن الافتراضية (ر.ي)',
            controller:
                TextEditingController(text: settings.defaultCost.toString()),
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.local_shipping),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'الحد الأدنى للشحن المجاني (ر.ي)',
            controller: TextEditingController(
                text: settings.freeShippingThreshold.toString()),
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.card_giftcard),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'مدة التوصيل المتوقعة (أيام)',
            controller:
                TextEditingController(text: settings.deliveryDays.toString()),
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.schedule),
          ),
          const SizedBox(height: 24),
          const Text(
            'شركات الشحن',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          ...settings.shippingCompanies.map((company) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildToggleItem(
                  Icons.local_shipping,
                  company.name,
                  'التكلفة: ${company.cost.toStringAsFixed(0)} ر.ي',
                  company.isActive,
                  (value) => ref
                      .read(adminProvider.notifier)
                      .toggleShippingCompany(company.id),
                ),
              )),
          const SizedBox(height: 24),
          CustomButton(
            text: 'حفظ التغييرات',
            icon: Icons.save,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حفظ إعدادات الشحن'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================
  // تبويب إعدادات الإشعارات
  // ============================================
  Widget _buildNotificationsTab() {
    final settings = ref.watch(adminProvider).notificationSettings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إعدادات الإشعارات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          _buildToggleItem(
            Icons.notifications_active,
            'إشعارات الطلبات',
            'تنبيهات الطلبات الجديدة',
            settings.orderNotifications,
            (value) => ref
                .read(adminProvider.notifier)
                .updateNotificationSetting('order', value),
          ),
          const SizedBox(height: 12),
          _buildToggleItem(
            Icons.person_add,
            'إشعارات العملاء الجدد',
            'تنبيه عند تسجيل عميل جديد',
            settings.customerNotifications,
            (value) => ref
                .read(adminProvider.notifier)
                .updateNotificationSetting('customer', value),
          ),
          const SizedBox(height: 12),
          _buildToggleItem(
            Icons.campaign,
            'إشعارات التسويق',
            'حملات وعروض ترويجية',
            settings.marketingNotifications,
            (value) => ref
                .read(adminProvider.notifier)
                .updateNotificationSetting('marketing', value),
          ),
          const SizedBox(height: 12),
          _buildToggleItem(
            Icons.warning,
            'تنبيهات المخزون',
            'تنبيه عند انخفاض المخزون',
            settings.stockNotifications,
            (value) => ref
                .read(adminProvider.notifier)
                .updateNotificationSetting('stock', value),
          ),
          const SizedBox(height: 24),
          const Text(
            'قنوات الإشعار',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          _buildToggleItem(
            Icons.phone_android,
            'الإشعارات الفورية (Push)',
            'إشعارات على الهاتف',
            settings.pushNotifications,
            (value) => ref
                .read(adminProvider.notifier)
                .updateNotificationSetting('push', value),
          ),
          const SizedBox(height: 12),
          _buildToggleItem(
            Icons.email,
            'البريد الإلكتروني',
            'إشعارات عبر البريد',
            settings.emailNotifications,
            (value) => ref
                .read(adminProvider.notifier)
                .updateNotificationSetting('email', value),
          ),
          const SizedBox(height: 12),
          _buildToggleItem(
            Icons.sms,
            'الرسائل النصية (SMS)',
            'رسائل نصية قصيرة',
            settings.smsNotifications,
            (value) => ref
                .read(adminProvider.notifier)
                .updateNotificationSetting('sms', value),
          ),
        ],
      ),
    );
  }

  // ============================================
  // تبويب إعدادات الأمان
  // ============================================
  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إعدادات الأمان',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          _buildSecurityItem(
            Icons.lock,
            'تغيير كلمة المرور',
            'تغيير كلمة مرور الحساب',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildSecurityItem(
            Icons.devices,
            'الأجهزة المرتبطة',
            'إدارة الأجهزة المسجلة',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildSecurityItem(
            Icons.verified_user,
            'المصادقة الثنائية',
            'تفعيل التحقق بخطوتين',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildSecurityItem(
            Icons.history,
            'سجل النشاط',
            'عرض سجل العمليات',
            onTap: () {},
          ),
          const SizedBox(height: 24),
          const Text(
            'النسخ الاحتياطي',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          _buildSecurityItem(
            Icons.backup,
            'نسخ احتياطي الآن',
            'إنشاء نسخة احتياطية من البيانات',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('جاري إنشاء نسخة احتياطية...'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSecurityItem(
            Icons.restore,
            'استعادة البيانات',
            'استعادة من نسخة احتياطية',
            onTap: () {},
          ),
          const SizedBox(height: 24),
          const Text(
            'منطقة الخطر',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                _buildSecurityItem(
                  Icons.delete_forever,
                  'حذف المتجر',
                  'حذف جميع بيانات المتجر نهائياً',
                  isDanger: true,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('تأكيد الحذف'),
                        content: const Text(
                          'هل أنت متأكد؟ سيتم حذف جميع البيانات نهائياً ولا يمكن التراجع.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('إلغاء'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'حذف نهائي',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // عناصر مساعدة
  // ============================================
  Widget _buildToggleItem(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(
    IconData icon,
    String title,
    String subtitle, {
    bool isDanger = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDanger
                    ? AppColors.error.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDanger ? AppColors.error : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDanger
                          ? AppColors.error
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDanger ? AppColors.error : AppColors.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }
}