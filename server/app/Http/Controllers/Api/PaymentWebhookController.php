<?php

namespace App\Http\Controllers\Api;

use App\Models\AdminNotification;
use App\Models\Order;
use App\Notifications\PaymentFailedNotification;
use App\Notifications\PaymentPendingNotification;
use App\Notifications\PaymentSuccessNotification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class PaymentWebhookController extends BaseApiController
{
    /**
     * بدء عملية الدفع عبر المحفظة (أم فلوس أو القطيبي) وتحديد مهلة 5 دقائق
     */
    public function initiatePayment(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'order_id' => ['required', 'exists:orders,id'],
            'wallet_code' => ['required', 'string', 'in:am_flous,qutaibi'],
        ]);

        $order = Order::where('id', $validated['order_id'])
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $wallets = config('payment_wallets.wallets');
        $walletInfo = $wallets[$validated['wallet_code']] ?? ['name' => 'المحفظة الإلكترونية'];
        $walletName = $walletInfo['name'];
        $timeoutSeconds = config('payment_wallets.timeout_seconds', 300);

        $expiresAt = now()->addSeconds($timeoutSeconds);

        $order->update([
            'payment_method' => $walletName,
            'wallet_name' => $walletName,
            'payment_status' => 'pending',
            'payment_expires_at' => $expiresAt,
        ]);

        // إرسال إشعار الدفع المعلق للعميل
        $order->user->notify(new PaymentPendingNotification($order, $walletName));

        return $this->success([
            'order_id' => $order->id,
            'order_number' => $order->order_number,
            'payment_status' => $order->payment_status,
            'wallet_name' => $walletName,
            'expires_at' => $expiresAt->toIso8601String(),
            'seconds_remaining' => $timeoutSeconds,
        ], 'تم إرسال طلب الدفع للمحفظة بنجاح');
    }

    /**
     * استقبال الـ Webhook من بوابة المحفظة الإلكترونية
     */
    public function handleWebhook(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'order_id' => ['required', 'exists:orders,id'],
            'status' => ['required', 'string', 'in:success,failed'],
            'wallet_name' => ['nullable', 'string'],
        ]);

        $order = Order::with('user')->findOrFail($validated['order_id']);
        $walletName = $validated['wallet_name'] ?? $order->wallet_name ?? 'المحفظة الإلكترونية';

        if ($validated['status'] === 'success') {
            $order->update([
                'payment_status' => 'paid',
                'status' => 'processing',
            ]);

            // 1. إشعار للعميل
            $order->user->notify(new PaymentSuccessNotification($order, $walletName));

            // 2. إشعار للوحة التحكم (المدير)
            AdminNotification::create([
                'title' => 'دفعة جديدة ناجحة ✅',
                'body' => "دفعة جديدة: {$order->total} ر.ي — طلب رقم #{$order->order_number} — {$walletName} ✅",
                'type' => 'order',
                'is_sent' => true,
            ]);

            return $this->success(null, 'تم معالجة دفع الطلب بنجاح');
        } else {
            $order->update([
                'payment_status' => 'failed',
            ]);

            // 1. إشعار للعميل
            $order->user->notify(new PaymentFailedNotification($order, 'رفض العملية من المحفظة'));

            // 2. إشعار تنبيه للمدير
            AdminNotification::create([
                'title' => 'تنبيه: تعثر دفع إلكتروني ⚠️',
                'body' => "تعثر دفع الطلب رقم #{$order->order_number} لمبلغ {$order->total} ر.ي عبر {$walletName}",
                'type' => 'order',
                'is_sent' => true,
            ]);

            return $this->success(null, 'تم تسجيل تعثر عملية الدفع');
        }
    }

    /**
     * Endpoint محاكاة (Mocking) لاختبار نتائج الـ Webhook بسهولة من التطبيق أو لوحة الاختبار
     */
    public function mockWebhook(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'order_id' => ['required', 'exists:orders,id'],
            'action' => ['required', 'string', 'in:success,fail,timeout'],
        ]);

        $order = Order::with('user')->findOrFail($validated['order_id']);

        if ($validated['action'] === 'success') {
            return $this->handleWebhook(new Request([
                'order_id' => $order->id,
                'status' => 'success',
                'wallet_name' => $order->wallet_name,
            ]));
        } elseif ($validated['action'] === 'fail') {
            return $this->handleWebhook(new Request([
                'order_id' => $order->id,
                'status' => 'failed',
                'wallet_name' => $order->wallet_name,
            ]));
        } else {
            // محاكاة انتهاء وقت المهلة
            $order->update([
                'payment_status' => 'expired',
            ]);

            $order->user->notify(new PaymentFailedNotification($order, 'انتهت مهلة الـ 5 دقائق بدون تأكيد'));

            AdminNotification::create([
                'title' => 'تنبيه: انتهاء مهلة الدفع ⏳',
                'body' => "انتهت مهلة الدفع للطلب #{$order->order_number} دون تأكيد العميل",
                'type' => 'order',
                'is_sent' => true,
            ]);

            return $this->success(null, 'تمت محاكاة انتهاء مهلة الدفع بنجاح');
        }
    }

    /**
     * فحص حالة الطلب والدفع مع احتساب الوقت المتبقي (Polling Endpoint)
     */
    public function getOrderStatus(Request $request, Order $order): JsonResponse
    {
        if ($order->user_id !== $request->user()->id) {
            return $this->error('غير مصرح لك بعرض هذا الطلب', 403);
        }

        // فحص انقضاء الوقت إن كان معلقاً
        if ($order->payment_status === 'pending' && $order->payment_expires_at) {
            if (Carbon::now()->greaterThan($order->payment_expires_at)) {
                $order->update(['payment_status' => 'expired']);

                $order->user->notify(new PaymentFailedNotification($order, 'انتهت مهلة الـ 5 دقائق بدون تأكيد'));

                AdminNotification::create([
                    'title' => 'تنبيه: انتهاء مهلة الدفع ⏳',
                    'body' => "انتهت مهلة الدفع للطلب #{$order->order_number} دون تأكيد العميل",
                    'type' => 'order',
                    'is_sent' => true,
                ]);
            }
        }

        $secondsRemaining = 0;
        if ($order->payment_status === 'pending' && $order->payment_expires_at) {
            $secondsRemaining = max(0, Carbon::now()->diffInSeconds($order->payment_expires_at, false));
        }

        return $this->success([
            'id' => $order->id,
            'order_number' => $order->order_number,
            'status' => $order->status,
            'payment_status' => $order->payment_status,
            'payment_method' => $order->payment_method,
            'wallet_name' => $order->wallet_name,
            'total' => (float) $order->total,
            'seconds_remaining' => (int) $secondsRemaining,
            'expires_at' => $order->payment_expires_at?->toIso8601String(),
        ]);
    }

    /**
     * تحويل طريقة الدفع إلى "الدفع عند الاستلام" (COD)
     */
    public function switchToCod(Request $request, Order $order): JsonResponse
    {
        if ($order->user_id !== $request->user()->id) {
            return $this->error('غير مصرح لك بتعديل هذا الطلب', 403);
        }

        $order->update([
            'payment_method' => 'cod',
            'payment_status' => 'pending',
            'status' => 'pending',
            'wallet_name' => null,
            'payment_expires_at' => null,
        ]);

        return $this->success([
            'id' => $order->id,
            'order_number' => $order->order_number,
            'payment_method' => 'cod',
            'status' => $order->status,
        ], 'تم تحويل طريقة الدفع إلى «الدفع عند الاستلام» بنجاح');
    }
}
