// ============================================
// نموذج الإشعار (App Notification Model)
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // payment_pending, payment_success, payment_failed, order_preparing, order_shipped, order_delivered
  final Map<String, dynamic>? data;
  final DateTime? readAt;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'general',
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : null,
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
        'read_at': readAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  /// أيقونة ملونة حسب نوع الإشعار
  IconData get icon {
    switch (type) {
      case 'payment_success':
        return Icons.check_circle_rounded;
      case 'payment_failed':
        return Icons.warning_amber_rounded;
      case 'payment_pending':
        return Icons.hourglass_top_rounded;
      case 'order_preparing':
        return Icons.inventory_2_rounded;
      case 'order_shipped':
        return Icons.local_shipping_rounded;
      case 'order_delivered':
        return Icons.verified_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  /// لون الأيقونة والخلفية بحسب النوع
  Color get color {
    switch (type) {
      case 'payment_success':
      case 'order_delivered':
        return const Color(0xFF10B981); // green
      case 'payment_failed':
        return const Color(0xFFEF4444); // red/orange
      case 'payment_pending':
        return const Color(0xFFF59E0B); // amber/orange
      case 'order_shipped':
        return const Color(0xFF3B82F6); // blue
      case 'order_preparing':
        return const Color(0xFF8B5CF6); // purple
      default:
        return const Color(0xFF7C3AED); // primary
    }
  }

  /// تصنيف التاريخ (اليوم / أمس / أقدم)
  String get dateGroup {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

    if (notificationDate.isAtSameMomentAs(today)) {
      return 'اليوم';
    } else if (notificationDate.isAtSameMomentAs(yesterday)) {
      return 'أمس';
    } else {
      return 'أقدم';
    }
  }

  /// وقت الإشعار المنسق
  String get timeFormatted {
    return DateFormat('hh:mm a', 'ar').format(createdAt);
  }
}
