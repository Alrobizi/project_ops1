<?php

namespace App\Notifications;

use App\Channels\FcmChannel;
use App\Models\NotificationLog;
use App\Models\Order;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class PaymentFailedNotification extends Notification
{
    use Queueable;

    public Order $order;
    public string $reason;

    public function __construct(Order $order, string $reason = 'انتهاء المهلة أو رفض الخصم')
    {
        $this->order = $order;
        $this->reason = $reason;
    }

    public function via($notifiable): array
    {
        return [FcmChannel::class];
    }

    public function toFcm($notifiable): array
    {
        $title = "لم يكتمل الدفع ⚠️";
        $body = "لم يكتمل الدفع لطلبك رقم #{$this->order->order_number} — لم يُخصم أي مبلغ. يمكنك إعادة المحاولة أو التحويل للدفع عند الاستلام";

        NotificationLog::create([
            'user_id' => $notifiable->id,
            'title' => $title,
            'body' => $body,
            'type' => 'payment_failed',
            'data' => [
                'order_id' => $this->order->id,
                'order_number' => $this->order->order_number,
                'reason' => $this->reason,
            ],
        ]);

        return [
            'title' => $title,
            'body' => $body,
            'data' => [
                'type' => 'payment_failed',
                'order_id' => (string) $this->order->id,
                'order_number' => $this->order->order_number,
                'route' => "/order-details/{$this->order->id}",
            ],
        ];
    }
}
