<?php

namespace App\Notifications;

use App\Channels\FcmChannel;
use App\Models\NotificationLog;
use App\Models\Order;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class PaymentPendingNotification extends Notification
{
    use Queueable;

    public Order $order;
    public string $walletName;

    public function __construct(Order $order, string $walletName = 'المحفظة الإلكترونية')
    {
        $this->order = $order;
        $this->walletName = $walletName;
    }

    public function via($notifiable): array
    {
        return [FcmChannel::class];
    }

    public function toFcm($notifiable): array
    {
        $title = "بانتظار تأكيدك ⏳";
        $body = "افتح تطبيق محفظة ({$this->walletName}) ووافق على خصم مبلغ {$this->order->total} ر.ي للطلب رقم #{$this->order->order_number} خلال 5 دقائق";

        NotificationLog::create([
            'user_id' => $notifiable->id,
            'title' => $title,
            'body' => $body,
            'type' => 'payment_pending',
            'data' => [
                'order_id' => $this->order->id,
                'order_number' => $this->order->order_number,
                'amount' => $this->order->total,
                'wallet_name' => $this->walletName,
                'expires_at' => $this->order->payment_expires_at?->toIso8601String(),
            ],
        ]);

        return [
            'title' => $title,
            'body' => $body,
            'data' => [
                'type' => 'payment_pending',
                'order_id' => (string) $this->order->id,
                'order_number' => $this->order->order_number,
                'route' => "/order-details/{$this->order->id}",
            ],
        ];
    }
}
