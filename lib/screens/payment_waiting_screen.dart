// ============================================
// شاشة انتظار تأكيد الدفع بالمحفظة (Payment Waiting Screen)
// مع Polling كل 5 ثوانٍ وعدّاد 5 دقائق
// ============================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../core/theme/app_colors.dart';

class PaymentWaitingScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String walletName;

  const PaymentWaitingScreen({
    super.key,
    required this.orderId,
    required this.walletName,
  });

  @override
  ConsumerState<PaymentWaitingScreen> createState() => _PaymentWaitingScreenState();
}

class _PaymentWaitingScreenState extends ConsumerState<PaymentWaitingScreen> {
  Timer? _pollingTimer;
  Timer? _countdownTimer;
  int _secondsRemaining = 300; // 5 دقائق

  String _paymentStatus = 'pending'; // pending, paid, failed, expired
  bool _isSwitchingToCod = false;
  bool _isMocking = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() => _secondsRemaining--);
        }
      } else {
        timer.cancel();
        _checkStatus();
      }
    });
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    // إجراء فحص فوري
    _checkStatus();
    // ثم Polling كل 5 ثوانٍ
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.getOrderStatus(widget.orderId);

      if (!mounted) return;

      final status = res['payment_status'] ?? 'pending';
      final remSec = res['seconds_remaining'] as int? ?? _secondsRemaining;

      setState(() {
        _paymentStatus = status;
        if (status == 'pending') {
          _secondsRemaining = remSec;
        }
      });

      if (status == 'paid') {
        _pollingTimer?.cancel();
        _countdownTimer?.cancel();

        // جلب بيانات الطلب والانتقال لصفحة النجاح
        final order = await ref.read(orderServiceProvider).getOrder(widget.orderId);
        ref.read(cartProvider.notifier).clearCart();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم الدفع بنجاح! ✅ جاري نقلكم للتأكيد...'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          context.pushReplacement('/order-success', extra: order);
        }
      } else if (status == 'failed' || status == 'expired') {
        _pollingTimer?.cancel();
        _countdownTimer?.cancel();
      }
    } catch (e) {
      debugPrint('Polling error: $e');
    }
  }

  Future<void> _switchToCod() async {
    setState(() => _isSwitchingToCod = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.switchToCod(widget.orderId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحويل طريقة الدفع إلى «الدفع عند الاستلام» بنجاح'),
          backgroundColor: AppColors.primary,
        ),
      );

      final order = await ref.read(orderServiceProvider).getOrder(widget.orderId);
      ref.read(cartProvider.notifier).clearCart();
      if (mounted) {
        context.pushReplacement('/order-success', extra: order);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل التحويل: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSwitchingToCod = false);
    }
  }

  Future<void> _triggerMockAction(String action) async {
    setState(() => _isMocking = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.mockWebhook(orderId: widget.orderId, action: action);
      await _checkStatus();
    } catch (e) {
      debugPrint('Mock error: $e');
    } finally {
      if (mounted) setState(() => _isMocking = false);
    }
  }

  String _formatTimer(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تأكيد الدفع الإلكتروني'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      if (_paymentStatus == 'pending') _buildPendingState(),
                      if (_paymentStatus == 'paid') _buildPaidState(),
                      if (_paymentStatus == 'failed' || _paymentStatus == 'expired')
                        _buildFailedState(),
                    ],
                  ),
                ),
              ),

              // أدوات المحاكاة السريعة للاختبار (Mock Panel)
              _buildMockControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingState() {
    return Column(
      children: [
        // دائرة العداد التنازلي
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: CircularProgressIndicator(
                value: _secondsRemaining / 300,
                strokeWidth: 8,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                color: _secondsRemaining < 60 ? AppColors.error : AppColors.primary,
              ),
            ),
            Column(
              children: [
                Icon(Icons.hourglass_top_rounded, color: AppColors.primary, size: 28),
                const SizedBox(height: 4),
                Text(
                  _formatTimer(_secondsRemaining),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: _secondsRemaining < 60 ? AppColors.error : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'محفظة ${widget.walletName}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'بانتظار تأكيدك ⏳',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'يرجى فتح تطبيق محفظة (${widget.walletName}) الآن والموافقة على طلب خصم المبلغ خلال 5 دقائق.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryLight,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text(
              'جارٍ التحقق التلقائي من حالة الطلب...',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaidState() {
    return Column(
      children: const [
        Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 100),
        SizedBox(height: 16),
        Text(
          'تم الدفع بنجاح ✅',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text('طلبك قيد التجهيز الآن، جارٍ التحويل...'),
      ],
    );
  }

  Widget _buildFailedState() {
    return Column(
      children: [
        const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 90),
        const SizedBox(height: 16),
        Text(
          _paymentStatus == 'expired' ? 'انتهت المهلة الزمنيّة ⚠️' : 'لم يكتمل الدفع ⚠️',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFFEF4444),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: const Text(
            'لم يُخصم أي مبلغ من حسابك. يمكنك التحويل إلى «الدفع عند الاستلام» لإتمام الطلب فوراً.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textPrimaryLight, height: 1.4),
          ),
        ),
        const SizedBox(height: 28),

        // زر التحويل لـ COD
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isSwitchingToCod ? null : _switchToCod,
            icon: _isSwitchingToCod
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.local_shipping, color: Colors.white),
            label: const Text(
              'الدفع عند الاستلام',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMockControls() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Text(
            '🧪 لوحة محاكاة نتيجة الدفع (للتجربة والتحقق)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _isMocking ? null : () => _triggerMockAction('success'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                child: const Text('محاكاة النجاح ✅', style: TextStyle(fontSize: 11, color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: _isMocking ? null : () => _triggerMockAction('fail'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                child: const Text('محاكاة الفشل ⚠️', style: TextStyle(fontSize: 11, color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: _isMocking ? null : () => _triggerMockAction('timeout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                child: const Text('محاكاة انتهاء الوقت ⏳', style: TextStyle(fontSize: 11, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
