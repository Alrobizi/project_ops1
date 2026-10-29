// ============================================
// لوحة التحكم (Admin Dashboard)
// الشاشة الرئيسية للوحة التحكم مع الإحصائيات والتنقل
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.white,
                              size: 28,
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