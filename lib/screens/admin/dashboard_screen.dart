// ============================================
// لوحة التحكم (Admin Dashboard)
// الشاشة الرئيسية للوحة التحكم مع الإحصائيات والتنقل
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static const String _licenseStorageKey = 'admin_license_key_v1';
  bool _licenseVerified = false;
  bool _isCheckingLicense = true;
  bool _isVerifyingInput = false;
  String? _licenseError;
  final TextEditingController _licenseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // تحديث بيانات المستخدم وصلاحياته + التحقق الإلزامي من الترخيص
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).refreshUser();
      _checkSavedLicense();
    });
  }

  @override
  void dispose() {
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _checkSavedLicense() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_licenseStorageKey) ?? '';
      if (saved.isNotEmpty) {
        _licenseController.text = saved;
        await ref.read(apiClientProvider).verifyAdminLicense(saved);
        if (mounted) {
          setState(() {
            _licenseVerified = true;
            _isCheckingLicense = false;
            _licenseError = null;
          });
          ref.read(adminProvider.notifier).loadDashboard();
          return;
        }
      }
    } catch (e) {
      _licenseError = 'انتهت صلاحية الترخيص أو تم إيقافه، أدخل ترخيصاً صالحاً';
    }
    if (mounted) {
      setState(() {
        _licenseVerified = false;
        _isCheckingLicense = false;
      });
    }
  }

  Future<void> _submitLicense() async {
    final key = _licenseController.text.trim().toUpperCase();
    if (key.isEmpty) {
      setState(() => _licenseError = 'الرجاء إدخال مفتاح الترخيص');
      return;
    }
    setState(() {
      _isVerifyingInput = true;
      _licenseError = null;
    });
    try {
      await ref.read(apiClientProvider).verifyAdminLicense(key);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_licenseStorageKey, key);
      if (mounted) {
        setState(() {
          _licenseVerified = true;
          _isVerifyingInput = false;
        });
        ref.read(adminProvider.notifier).loadDashboard();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifyingInput = false;
          _licenseError = 'مفتاح الترخيص غير صالح أو موقوف';
        });
      }
    }
  }

  void _openLicensesManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AdminLicensesManagerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingLicense) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('جاري التحقق من ترخيص لوحة التحكم...'),
            ],
          ),
        ),
      );
    }

    if (!_licenseVerified) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('تأمين لوحة التحكم'),
          centerTitle: true,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified_user_rounded,
                    size: 56,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'مطلوب ترخيص للدخول',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'لا يمكن دخول لوحة التحكم إلا بمفتاح ترخيص صالح صادر من الإدارة',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 20),
                if (_licenseError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _licenseError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                TextField(
                  controller: _licenseController,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    hintText: 'BRK-XXXX-XXXX-XXXX',
                    labelText: 'مفتاح الترخيص (License Key)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isVerifyingInput ? null : _submitLicense,
                    child: _isVerifyingInput
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'تحقق وافتح لوحة التحكم 🔓',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final adminState = ref.watch(adminProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    // بطاقة المنتجات تظهر فقط لمن يملك صلاحية إدارة المنتجات
    final canManageProducts = user?.canManageProducts ?? false;
    // التحقق من صلاحية قسم معين (أدمن بصلاحيات فارغة = وصول كامل)
    bool hasPerm(String permission) => user?.hasAdminPermission(permission) ?? false;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(adminProvider.notifier).loadDashboard(),
          child: CustomScrollView(
            slivers: [
              // رأس لوحة التحكم
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back,
                                    color: Colors.white),
                                onPressed: () => context.pop(),
                              ),
                              const SizedBox(width: 8),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'لوحة التحكم',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'إدارة المتجر والإعدادات',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: _openLicensesManager,
                            child: Tooltip(
                              message: 'إدارة تراخيص لوحة التحكم',
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.verified_user_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // بطاقات الإحصائيات
                      if (adminState.isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.shopping_bag,
                                title: 'الطلبات',
                                value: '${adminState.totalOrders}',
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.people,
                                title: 'العملاء',
                                value: '${adminState.totalCustomers}',
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.inventory_2,
                                title: 'المنتجات',
                                value: '${adminState.totalProducts}',
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.attach_money,
                                title: 'المبيعات',
                                value: '${adminState.totalSales.toStringAsFixed(0)} ر.ي',
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              // أقسام لوحة التحكم
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'أقسام الإدارة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                        children: [
                          // بطاقة المنتجات — تظهر فقط لمن يملك صلاحية "products"
                          if (canManageProducts)
                            _DashboardCard(
                              icon: Icons.inventory_2,
                              title: 'المنتجات',
                              subtitle: 'إضافة وتعديل المنتجات',
                              color: const Color(0xFFEC4899),
                              onTap: () => context.push('/admin/products'),
                            ),
                          if (hasPerm('marketing'))
                            _DashboardCard(
                              icon: Icons.campaign,
                              title: 'التسويق',
                              subtitle: 'الحملات والإعلانات',
                              color: AppColors.primaryAccent,
                              onTap: () => context.push('/admin/marketing'),
                            ),
                          if (hasPerm('customers'))
                            _DashboardCard(
                              icon: Icons.people_outline,
                              title: 'العملاء',
                              subtitle: 'إدارة العملاء',
                              color: const Color(0xFF10B981),
                              onTap: () => context.push('/admin/customers'),
                            ),
                          if (hasPerm('reports'))
                            _DashboardCard(
                              icon: Icons.bar_chart,
                              title: 'التقارير',
                              subtitle: 'الإحصائيات والتقارير',
                              color: const Color(0xFFF59E0B),
                              onTap: () => context.push('/admin/reports'),
                            ),
                          if (hasPerm('discounts'))
                            _DashboardCard(
                              icon: Icons.local_offer,
                              title: 'الخصومات',
                              subtitle: 'أكواد الخصم والعروض',
                              color: const Color(0xFFEF4444),
                              onTap: () => context.push('/admin/discounts'),
                            ),
                          if (hasPerm('content'))
                            _DashboardCard(
                              icon: Icons.article,
                              title: 'المحتوى',
                              subtitle: 'البانرات والصفحات',
                              color: AppColors.secondaryAccent,
                              onTap: () => context.push('/admin/content'),
                            ),
                          if (hasPerm('settings'))
                            _DashboardCard(
                              icon: Icons.settings,
                              title: 'الإعدادات',
                              subtitle: 'إعدادات المتجر',
                              color: const Color(0xFF6B7280),
                              onTap: () => context.push('/admin/settings'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // إجراءات سريعة
                      const Text(
                        'إجراءات سريعة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _QuickAction(
                        icon: Icons.add_circle,
                        title: 'إضافة منتج جديد',
                        onTap: canManageProducts
                            ? () => context.push('/admin/products')
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _QuickAction(
                        icon: Icons.receipt_long,
                        title: 'عرض الطلبات الجديدة',
                        onTap: hasPerm('orders')
                            ? () {}
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _QuickAction(
                        icon: Icons.notifications,
                        title: 'الإشعارات',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// بطاقة إحصائية (Stat Card)
// ============================================
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ============================================
// بطاقة قسم (Dashboard Card)
// ============================================
class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// إجراء سريع (Quick Action)
// ============================================
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
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
    );
  }
}

/// نافذة إدارة تراخيص لوحة التحكم من داخل لوحة التحكم في التطبيق
class _AdminLicensesManagerSheet extends ConsumerStatefulWidget {
  const _AdminLicensesManagerSheet();

  @override
  ConsumerState<_AdminLicensesManagerSheet> createState() =>
      _AdminLicensesManagerSheetState();
}

class _AdminLicensesManagerSheetState
    extends ConsumerState<_AdminLicensesManagerSheet> {
  List<Map<String, dynamic>> _licenses = [];
  bool _loading = true;
  final TextEditingController _labelCtrl = TextEditingController();
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ref.read(apiClientProvider).getAdminLicenses();
      if (mounted) {
        setState(() {
          _licenses = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final label = _labelCtrl.text.trim();
    if (label.isEmpty) return;
    setState(() => _creating = true);
    try {
      final created =
          await ref.read(apiClientProvider).createAdminLicense(label: label);
      _labelCtrl.clear();
      await _load();
      final key = created['license_key']?.toString() ?? '';
      if (key.isNotEmpty) {
        Clipboard.setData(ClipboardData(text: key));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إصدار الترخيص ونسخه: $key'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر إصدار الترخيص'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollCtrl) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified_user_rounded, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'إدارة تراخيص لوحة التحكم',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _labelCtrl,
                    decoration: InputDecoration(
                      hintText: 'اسم صاحب الترخيص الجديد...',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _creating ? null : _create,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _creating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('إصدار'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      controller: scrollCtrl,
                      itemCount: _licenses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final lic = _licenses[i];
                        final isActive = lic['is_active'] == true;
                        final isMaster = lic['is_master'] == true;
                        final key = lic['license_key']?.toString() ?? '';
                        final id = int.tryParse(lic['id'].toString()) ?? 0;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.cardLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.success.withValues(alpha: 0.4)
                                  : AppColors.error.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${lic['label']}${isMaster ? ' (رئيسي)' : ''}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    isActive ? 'نشط ✓' : 'موقوف',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isActive
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: SelectableText(
                                      key,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 18),
                                    onPressed: () {
                                      Clipboard.setData(
                                          ClipboardData(text: key));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('تم نسخ المفتاح'),
                                        ),
                                      );
                                    },
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await ref
                                          .read(apiClientProvider)
                                          .toggleAdminLicense(id);
                                      await _load();
                                    },
                                    child: Text(isActive ? 'إيقاف' : 'تفعيل'),
                                  ),
                                  if (!isMaster)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: AppColors.error,
                                        size: 20,
                                      ),
                                      onPressed: () async {
                                        await ref
                                            .read(apiClientProvider)
                                            .deleteAdminLicense(id);
                                        await _load();
                                      },
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}