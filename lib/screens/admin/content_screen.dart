// ============================================
// شاشة المحتوى (Content Screen)
// إدارة البانرات والصفحات والمحتوى
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../models/admin_models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common_widgets.dart';

class ContentScreen extends ConsumerStatefulWidget {
  const ContentScreen({super.key});

  @override
  ConsumerState<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends ConsumerState<ContentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = ['البانرات', 'الصفحات', 'الإشعارات', 'الأسئلة الشائعة'];

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
        title: const Text('المحتوى'),
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
          _buildBannersTab(adminState),
          _buildPagesTab(adminState),
          _buildNotificationsTab(adminState),
          _buildFaqTab(adminState),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final index = _tabController.index;
          switch (index) {
            case 0:
              _showAddBannerDialog(context);
              break;
            case 1:
              _showAddPageDialog(context);
              break;
            case 2:
              _showAddNotificationDialog(context);
              break;
            case 3:
              _showAddFaqDialog(context);
              break;
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ============================================
  // تبويب البانرات
  // ============================================
  Widget _buildBannersTab(AdminState state) {
    final banners = state.banners;

    if (banners.isEmpty) {
      return const EmptyState(
        icon: Icons.image_outlined,
        title: 'لا توجد بانرات',
        subtitle: 'أضف بانراً جديداً',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: banners.length,
      itemBuilder: (context, index) {
        final banner = banners[index];
        return _BannerCard(
          banner: banner,
          onEdit: () {},
          onDelete: () {
            _showDeleteConfirm(context, banner.title, () async {
              try {
                await ref.read(adminProvider.notifier).deleteBanner(banner.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف البانر بنجاح'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل حذف البانر: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            });
          },
          onToggle: () {
            ref.read(adminProvider.notifier).toggleBannerStatus(banner.id);
          },
        );
      },
    );
  }

  // ============================================
  // تبويب الصفحات
  // ============================================
  Widget _buildPagesTab(AdminState state) {
    final pages = state.pages;

    if (pages.isEmpty) {
      return const EmptyState(
        icon: Icons.article_outlined,
        title: 'لا توجد صفحات',
        subtitle: 'أضف صفحة جديدة',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pages.length,
      itemBuilder: (context, index) {
        final page = pages[index];
        return _PageCard(
          page: page,
          onEdit: () {},
          onDelete: () {
            _showDeleteConfirm(context, page.title, () {
              ref.read(adminProvider.notifier).deletePage(page.id);
            });
          },
        );
      },
    );
  }

  // ============================================
  // تبويب الإشعارات
  // ============================================
  Widget _buildNotificationsTab(AdminState state) {
    final notifications = state.notifications;

    if (notifications.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_outlined,
        title: 'لا توجد إشعارات',
        subtitle: 'أرسل إشعاراً جديداً',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _NotificationCard(
          notification: notification,
          onDelete: () {
            _showDeleteConfirm(context, notification.title, () {
              ref.read(adminProvider.notifier).deleteNotification(notification.id);
            });
          },
        );
      },
    );
  }

  // ============================================
  // تبويب الأسئلة الشائعة
  // ============================================
  Widget _buildFaqTab(AdminState state) {
    final faqs = state.faqs;

    if (faqs.isEmpty) {
      return const EmptyState(
        icon: Icons.help_outline,
        title: 'لا توجد أسئلة',
        subtitle: 'أضف سؤالاً شائعاً',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        final faq = faqs[index];
        return _FaqCard(
          faq: faq,
          onEdit: () {},
          onDelete: () {
            _showDeleteConfirm(context, faq.question, () {
              ref.read(adminProvider.notifier).deleteFaq(faq.id);
            });
          },
        );
      },
    );
  }

  // ============================================
  // نوافذ الإضافة
  // ============================================
  void _showAddBannerDialog(BuildContext context) {
    final titleController = TextEditingController();
    final linkController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بانر جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              label: 'عنوان البانر',
              controller: titleController,
              prefixIcon: const Icon(Icons.title),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'رابط البانر',
              controller: linkController,
              prefixIcon: const Icon(Icons.link),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                try {
                  await ref.read(adminProvider.notifier).addBanner(
                        title: titleController.text,
                        link: linkController.text,
                      );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تمت إضافة البانر بنجاح'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشلت إضافة البانر: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
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
    );
  }

  void _showAddPageDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('صفحة جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              label: 'عنوان الصفحة',
              controller: titleController,
              prefixIcon: const Icon(Icons.title),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'محتوى الصفحة',
              controller: contentController,
              maxLines: 4,
              prefixIcon: const Icon(Icons.description),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                ref.read(adminProvider.notifier).addPage(
                      title: titleController.text,
                      content: contentController.text,
                    );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تمت إضافة الصفحة بنجاح'),
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
    );
  }

  void _showAddNotificationDialog(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    int? selectedUserId; // null = إرسال للجميع
    List<Map<String, dynamic>> customers = [];
    bool loadingCustomers = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // تحميل قائمة العملاء من السيرفر عند فتح النافذة
          if (loadingCustomers) {
            loadingCustomers = false;
            ref.read(adminServiceProvider).getCustomers().then((list) {
              if (mounted) {
                setState(() => customers = list);
              }
            }).catchError((_) {
              if (mounted) {
                setState(() => customers = []);
              }
            });
          }

          return AlertDialog(
            title: const Text('إشعار جديد'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    label: 'عنوان الإشعار',
                    controller: titleController,
                    prefixIcon: const Icon(Icons.title),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'نص الإشعار',
                    controller: bodyController,
                    maxLines: 3,
                    prefixIcon: const Icon(Icons.message),
                  ),
                  const SizedBox(height: 16),
                  // اختيار المستخدم المستهدف
                  DropdownButtonFormField<int?>(
                    initialValue: null,
                    decoration: const InputDecoration(
                      labelText: 'إرسال إلى',
                      prefixIcon: Icon(Icons.people_outline),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('جميع المستخدمين'),
                      ),
                      ...customers.map((c) => DropdownMenuItem<int?>(
                            value: (c['id'] as num).toInt(),
                            child: Text(
                              '${c['name']} (${c['email']})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                    ],
                    onChanged: (value) => setState(() => selectedUserId = value),
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
                onPressed: () async {
                  if (titleController.text.isNotEmpty) {
                    try {
                      await ref.read(adminProvider.notifier).addNotification(
                            title: titleController.text,
                            body: bodyController.text,
                            userId: selectedUserId,
                          );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              selectedUserId == null
                                  ? 'تم إرسال الإشعار لجميع المستخدمين'
                                  : 'تم إرسال الإشعار للمستخدم المحدد',
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('فشل إرسال الإشعار: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('إرسال'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddFaqDialog(BuildContext context) {
    final questionController = TextEditingController();
    final answerController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سؤال شائع جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              label: 'السؤال',
              controller: questionController,
              prefixIcon: const Icon(Icons.help_outline),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'الإجابة',
              controller: answerController,
              maxLines: 3,
              prefixIcon: const Icon(Icons.question_answer),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (questionController.text.isNotEmpty) {
                ref.read(adminProvider.notifier).addFaq(
                      question: questionController.text,
                      answer: answerController.text,
                    );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تمت إضافة السؤال بنجاح'),
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
    );
  }

  void _showDeleteConfirm(
      BuildContext context, String title, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف "$title"؟'),
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
// بطاقة بانر (Banner Card)
// ============================================
class _BannerCard extends StatelessWidget {
  final BannerItem banner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _BannerCard({
    required this.banner,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // صورة البانر
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.8),
                  AppColors.primaryAccent.withOpacity(0.6),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Stack(
              children: [
                // صورة البانر من السيرفر (إن وجدت)
                if (banner.image.isNotEmpty)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: banner.image,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image, color: Colors.white70, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        banner.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: banner.isActive
                          ? AppColors.success
                          : AppColors.textSecondaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      banner.isActive ? 'نشط' : 'متوقف',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // تفاصيل البانر
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الترتيب: ${banner.sortOrder}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      if (banner.link.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'الرابط: ${banner.link}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        banner.isActive ? Icons.pause : Icons.play_arrow,
                        color: AppColors.warning,
                      ),
                      onPressed: onToggle,
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: AppColors.primary),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// بطاقة صفحة (Page Card)
// ============================================
class _PageCard extends StatelessWidget {
  final PageItem page;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PageCard({
    required this.page,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            child: Icon(Icons.article, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  page.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  page.content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: AppColors.primary),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ============================================
// بطاقة إشعار (Notification Card)
// ============================================
class _NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              color: AppColors.primaryAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.notifications,
                color: AppColors.primaryAccent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  notification.date,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ============================================
// بطاقة سؤال شائع (FAQ Card)
// ============================================
class _FaqCard extends StatelessWidget {
  final FaqItem faq;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FaqCard({
    required this.faq,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.help_outline,
                color: AppColors.warning, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faq.question,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  faq.answer,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: AppColors.primary),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}