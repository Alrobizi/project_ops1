// ============================================
// شاشة الإشعارات (Notifications Screen)
// تحميل تدريجي + سحب للتحديث + تجميع حسب التاريخ
// ============================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/notification.dart';
import '../providers/app_providers.dart';
import '../core/theme/app_colors.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // جلب واحد فقط بعد بناء الشاشة.
    // ensureFresh يتجاهل الطلب إذا كانت البيانات حديثة، فلا يتكرّر الطلب
    // عند كل تنقّل بين الشاشات (بينما كان fetchNotifications يجلب دائماً).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(ref.read(notificationsProvider.notifier).ensureFresh());
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// تحميل الصفحة التالية عند الاقتراب من نهاية القائمة
  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      unawaited(ref.read(notificationsProvider.notifier).loadMore());
    }
  }

  NotificationsNotifier get _notifier =>
      ref.read(notificationsProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
            onPressed: state.isLoading
                ? null
                : () => _notifier.fetchNotifications(
                      quiet: true,
                      force: true,
                    ),
          ),
          if (state.unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all_rounded),
              tooltip: 'تعليم الكل كمقروء',
              onPressed: () => _notifier.markAllAsRead(),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _notifier.fetchNotifications(quiet: true, force: true),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(NotificationsState state) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.notifications.isEmpty) {
      if (state.error != null) {
        return _buildMessageView(
          icon: Icons.cloud_off_rounded,
          title: 'تعذّر تحميل الإشعارات',
          message: state.error!,
          actionLabel: 'إعادة المحاولة',
          onAction: () => _notifier.fetchNotifications(force: true),
        );
      }

      return _buildMessageView(
        icon: Icons.notifications_off_outlined,
        title: 'لا توجد إشعارات حالياً',
        message: 'ستظهر هنا إشعارات تأكيد طلباتك ومسار شحنها فور صدورها',
      );
    }

    final entries = _buildEntries(state);

    // مؤشر التحميل يظهر فقط عند وجود صفحات أخرى — لا نُطيل القائمة بلا داعٍ
    final showFooter = state.hasMore || state.isLoadingMore;

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: entries.length + (showFooter ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < entries.length) {
          return entries[index];
        }
        return _buildFooter(state);
      },
    );
  }

  /// ذيل القائمة: مؤشر أثناء الجلب، وزر صريح إن تعذّر التمرير (قائمة قصيرة)
  Widget _buildFooter(NotificationsState state) {
    if (!state.isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: TextButton(
            onPressed: () => _notifier.loadMore(),
            child: const Text('تحميل المزيد'),
          ),
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }

  /// عناصر القائمة مع فواصل مجموعات التاريخ (اليوم / أمس / أقدم)
  List<Widget> _buildEntries(NotificationsState state) {
    final entries = <Widget>[];

    if (state.error != null) {
      entries.add(_buildErrorBanner(state.error!));
    }

    String? currentGroup;

    for (final notification in state.notifications) {
      final group = notification.dateGroup;
      if (group != currentGroup) {
        currentGroup = group;
        entries.add(_buildGroupHeader(group));
      }
      entries.add(_buildCard(notification));
    }

    return entries;
  }

  Widget _buildGroupHeader(String label) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 8, bottom: 10, start: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(height: 1, color: AppColors.borderLight),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageView({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // ListView حتى يبقى السحب للتحديث متاحاً في الحالة الفارغة أيضاً
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
        Icon(icon, size: 80, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: AppColors.textSecondaryLight,
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 20),
          Center(
            child: FilledButton.tonal(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ),
        ],
      ],
    );
  }

  /// شريط خطأ يظهر أعلى القائمة دون إخفاء البيانات المحمّلة مسبقاً
  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: AppColors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () =>
                _notifier.fetchNotifications(quiet: true, force: true),
            child: const Text(
              'إعادة المحاولة',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(AppNotification notification) {
    final unread = notification.isUnread;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: unread
            ? notification.color.withValues(alpha: 0.06)
            : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _handleTap(notification),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: unread
                    ? notification.color.withValues(alpha: 0.35)
                    : AppColors.borderLight,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // أيقونة ملونة حسب نوع الإشعار
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: notification.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notification.icon,
                    color: notification.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    unread ? FontWeight.bold : FontWeight.w600,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: unread
                              ? AppColors.textPrimaryLight
                                  .withValues(alpha: 0.85)
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsetsDirectional.only(
                      start: 8,
                      top: 6,
                    ),
                    decoration: BoxDecoration(
                      color: notification.color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// النقر على إشعار: تعليمه كمقروء ثم الانتقال إلى وجهته
  Future<void> _handleTap(AppNotification notification) async {
    // تحديث متفائل: تختفي نقطة "غير مقروء" فوراً،
    // ويعود الحال تلقائياً إذا رفض السيرفر الطلب.
    if (notification.isUnread) {
      unawaited(_notifier.markAsRead(notification.id));
    }

    final route = notification.route;

    // الوجهة هي نفس الشاشة (إشعار إداري بلا رابط) — نعرض التفاصيل بدل التكرار
    if (!route.startsWith('/') || route == '/notifications') {
      _showDetailsSheet(notification);
      return;
    }

    // صفحة تفاصيل الطلب تحتاج كائن Order كاملاً (extra)،
    // فنجلبه أولاً ثم ننتقل — وعند الفشل نفتح قائمة الطلبات.
    if (route.startsWith('/order-details')) {
      final orderId = notification.orderId;
      if (orderId == null || orderId.isEmpty) {
        return;
      }

      try {
        final order = await ref.read(orderServiceProvider).getOrder(orderId);
        if (!mounted) {
          return;
        }
        context.push('/order-details/$orderId', extra: order);
      } catch (_) {
        if (!mounted) {
          return;
        }
        context.push('/orders');
      }
      return;
    }

    context.push(route);
  }

  void _showDetailsSheet(AppNotification notification) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: notification.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        notification.icon,
                        color: notification.color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  notification.body,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${notification.dateGroup} · ${notification.timeFormatted}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                if (notification.orderId != null) ...[
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        // تفاصيل الطلب تُبنى من قائمة الطلبات (تحتاج كائن Order)
                        context.push('/orders');
                      },
                      icon: const Icon(Icons.receipt_long_rounded, size: 18),
                      label: const Text('عرض الطلبات'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
