// ============================================
// شاشة الحساب (Profile Screen)
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../providers/app_providers.dart';
import '../widgets/common_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // بطاقة المستخدم
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  // صورة المستخدم
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Text(
                      user?.name.substring(0, 1) ?? 'أ',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // معلومات المستخدم
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'أحمد محمد',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'test@test.com',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // زر التعديل
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () => context.push('/edit-profile'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // قائمة الخيارات
            _MenuSection(
              title: 'التسوق',
              items: [
                _MenuItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'طلباتي',
                  onTap: () => context.push('/orders'),
                ),
                _MenuItem(
                  icon: Icons.location_on_outlined,
                  title: 'عناويني',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.favorite_outline,
                  title: 'المفضلة',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            _MenuSection(
              title: 'الإعدادات',
              items: [
                _MenuItem(
                  icon: Icons.palette_outlined,
                  title: 'لون التطبيق (المفضل)',
                  onTap: () => context.push('/theme-color'),
                ),
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  title: 'الإشعارات',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.language_outlined,
                  title: 'اللغة',
                  trailing: const Text(
                    'العربية',
                    style: TextStyle(color: AppColors.textSecondaryLight),
                  ),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            _MenuSection(
              title: 'الدعم',
              items: [
                _MenuItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'سياسة الخصوصية',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.headset_mic_outlined,
                  title: 'تواصل معنا',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            // قسم لوحة التحكم — يظهر فقط لمن يملك صلاحية الوصول للوحة
            if (user != null && user.canAccessAdminPanel) ...[
              _MenuSection(
                title: 'الإدارة',
                items: [
                  _MenuItem(
                    icon: Icons.admin_panel_settings,
                    title: 'لوحة التحكم',
                    onTap: () => context.push('/admin/dashboard'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 24),
            // زر تسجيل الخروج
            CustomButton(
              text: 'تسجيل الخروج',
              isOutlined: true,
              icon: Icons.logout,
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('تسجيل الخروج'),
                    content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('إلغاء'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'تسجيل الخروج',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                }
              },
            ),
            const SizedBox(height: 24),
            // نسخة التطبيق
            const Text(
              'الإصدار 1.0.0',
              style: TextStyle(
                color: AppColors.textSecondaryLight,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.icon,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: item.trailing ??
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.textSecondaryLight,
                        ),
                    onTap: item.onTap,
                  ),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      indent: 60,
                      endIndent: 16,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
  });
}

// ============================================
// شاشة تعديل الملف الشخصي (Edit Profile Screen)
// ============================================
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // صورة المستخدم
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: AppColors.primary,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // الاسم
              CustomTextField(
                label: 'الاسم الكامل',
                controller: _nameController,
                prefixIcon: const Icon(Icons.person_outline),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال الاسم';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // رقم الجوال
              CustomTextField(
                label: 'رقم الجوال',
                hint: '7xxxxxxxx',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال رقم الجوال';
                  }
                  if (!value.startsWith('7')) {
                    return 'رقم الجوال يجب أن يبدأ بـ 7';
                  }
                  if (value.length < 9) {
                    return 'رقم الجوال يجب أن يكون 9 أرقام على الأقل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              // زر الحفظ
              CustomButton(
                text: 'حفظ التغييرات',
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم حفظ التغييرات بنجاح'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    context.pop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
