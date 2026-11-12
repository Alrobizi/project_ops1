// ============================================
// نموذج الإشعار (App Notification Model)
// ============================================

import 'dart:convert';

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;

  /// payment_pending, payment_success, payment_failed, order_placed,
  /// order_preparing, order_shipped, order_delivered, order_cancelled
  final String type;
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

  bool get isUnread => readAt == null;

  /// رقم الطلب المرتبط بالإشعار إن وُجد
  String? get orderId {
    final value = data?['order_id'];
    if (value == null) {
      return null;
    }
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  /// الوجهة التي يجب فتحها عند النقر على الإشعار
  String get route {
    final value = data?['route'];
    if (value is String && value.trim().startsWith('/')) {
      return value.trim();
    }
    return orderId != null ? '/orders' : '/notifications';
  }

  /// تحويل آمن لخريطة البيانات (السيرفر قد يُرسل نصاً JSON أو null)
  static Map<String, dynamic>? _asDataMap(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) {
        return null;
      }
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        // نص غير صالح — نتجاهله بدلاً من تعطيل قائمة الإشعارات
      }
    }

    return null;
  }

  /// تحويل التاريخ إلى توقيت الجهاز المحلي.
  /// السيرفر يُرسل UTC (…Z)، وبدون toLocal() يظهر الوقت خاطئاً بفارق التوقيت.
  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    final raw = value.toString().trim();
    if (raw.isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return null;
    }

    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  /// يُرجع null إذا كانت البيانات غير صالحة (بدلاً من إسقاط القائمة كاملة)
  static AppNotification? fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    if (id.isEmpty) {
      return null;
    }

    return AppNotification(
      id: id,
      title: (json['title'] ?? 'إشعار جديد').toString(),
      body: (json['body'] ?? json['message'] ?? '').toString(),
      type: (json['type'] ?? 'general').toString(),
      data: _asDataMap(json['data']),
      readAt: _parseDate(json['read_at']),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
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

  AppNotification copyWith({
    String? title,
    String? body,
    String? type,
    Map<String, dynamic>? data,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// أيقونة ملونة حسب نوع الإشعار
  IconData get icon {
    switch (type) {
      case 'payment_success':
        return Icons.check_circle_rounded;
      case 'payment_failed':
        return Icons.warning_amber_rounded;
      case 'payment_pending':
        return Icons.hourglass_top_rounded;
      case 'order_placed':
        return Icons.receipt_long_rounded;
      case 'order_preparing':
        return Icons.inventory_2_rounded;
      case 'order_shipped':
        return Icons.local_shipping_rounded;
      case 'order_delivered':
        return Icons.verified_rounded;
      case 'order_cancelled':
        return Icons.cancel_outlined;
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
      case 'order_cancelled':
        return const Color(0xFFEF4444); // red/orange
      case 'payment_pending':
        return const Color(0xFFF59E0B); // amber/orange
      case 'order_shipped':
        return const Color(0xFF3B82F6); // blue
      case 'order_preparing':
        return const Color(0xFF8B5CF6); // purple
      case 'order_placed':
        return const Color(0xFF0284C7); // cyan-blue
      default:
        return AppColors.primary;
    }
  }

  /// تصنيف التاريخ (اليوم / أمس / أقدم) — يُحسب بالتوقيت المحلي
  String get dateGroup {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final local = createdAt.isUtc ? createdAt.toLocal() : createdAt;
    final notificationDate = DateTime(local.year, local.month, local.day);

    if (notificationDate.isAtSameMomentAs(today)) {
      return 'اليوم';
    }

    if (notificationDate.isAtSameMomentAs(
      today.subtract(const Duration(days: 1)),
    )) {
      return 'أمس';
    }

    return 'أقدم';
  }

  /// وقت الإشعار المنسق (12 ساعة) — لا يعتمد على تحميل بيانات اللغة
  ///
  /// DateFormat('hh:mm a', 'ar') يرمي LocaleDataException إذا لم تُهيَّأ
  /// بيانات 'ar' عبر initializeDateFormatting، وهو ما كان يُسقط قائمة الإشعارات.
  String get timeFormatted {
    final hour24 = createdAt.hour;
    final period = hour24 < 12 ? 'ص' : 'م';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour12:$minute $period';
  }
}
