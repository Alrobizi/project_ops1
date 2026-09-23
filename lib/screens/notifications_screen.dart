// ============================================
// شاشة الإشعارات (Notifications Screen)
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/notification.dart';
import '../providers/app_providers.dart';
import '../core/theme/app_colors.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        centerTitle: true,
        actions: [
          if (notificationsState.unreadCount > 0)
            TextButton(
              onPressed: () => notifier.markAllAsRead(),
              child: const Text(
                'تعليم الكل كمقروء',
                style: TextStyle(fontSize: 12, color: AppColors.primary),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.fetchNotifications(),
        child: notificationsState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : notificationsState.notifications.isEmpty
                ? _buildEmptyState()
                : _buildNotificationsList(context, ref, notificationsState.notifications),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد إشعارات حالياً',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ستظهر إشعارات الدفع والطلبات هنا فور صدورها',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(
      BuildContext context, WidgetRef ref, List<AppNotification> notifications) {
    // تجميع الإشعارات حسب التواريخ (اليوم / أمس / أقدم)
    final Map<String, List<AppNotification>> grouped = {};
    for (var notification in notifications) {
      final group = notification.dateGroup;
      grouped.putIfAbsent(group, () => []).add(notification);
    }

    final groupsOrder = ['اليوم', 'أمس', 'أقدم'];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: groupsOrder.where((g) => grouped.containsKey(g)).length,
      itemBuilder: (context, index) {
        final groupKey = groupsOrder.where((g) => grouped.containsKey(g)).elementAt(index);
        final groupItems = grouped[groupKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8, right: 4),
              child: Text(
                groupKey,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
            ...groupItems.map((item) => _NotificationTile(notification: item)),
          ],
        );
      },
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(notificationsProvider.notifier);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: notification.isRead ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: notification.isRead ? Colors.grey.shade200 : notification.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      color: notification.isRead ? AppColors.cardLight : notification.color.withOpacity(0.04),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          if (!notification.isRead) {
            notifier.markAsRead(notification.id);
          }

          final data = notification.data;
          if (data != null && data['order_id'] != null) {
            final orderId = data['order_id'].toString();
            try {
              final order = await ref.read(orderServiceProvider).getOrder(orderId);
              if (context.mounted) {
                context.push('/order-details/$orderId', extra: order);
              }
            } catch (_) {
              if (context.mounted) {
                context.push('/orders');
              }
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // أيقونة ملونة حسَب النوع
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: notification.color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification.icon,
                  color: notification.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // المحتوى النصي
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                        Text(
                          notification.timeFormatted,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: notification.isRead
                            ? AppColors.textSecondaryLight
                            : AppColors.textPrimaryLight.withOpacity(0.85),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: notification.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
