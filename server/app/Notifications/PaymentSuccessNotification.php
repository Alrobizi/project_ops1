<?php

namespace App\Notifications;

use App\Channels\FcmChannel;
use App\Models\NotificationLog;
use App\Models\Order;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class PaymentSuccessNotification extends Notification
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
        $title = "تم الدفع بنجاح ✅";
        $body = "تم استلام مبلغ {$this->order->total} ر.ي عبر ({$this->walletName}) — طلبك رقم #{$this->order->order_number} قيد التجهيز الآن";

        NotificationLog::create([
            'user_id' => $notifiable->id,
            'title' => $title,
            'body' => $body,
            'type' => 'payment_success',
            'data' => [
                'order_id' => $this->order->id,
                'order_number' => $this->order->order_number,
                'amount' => $this->order->total,
                'wallet_name' => $this->walletName,
            ],
        ]);

        return [
            'title' => $title,
            'body' => $body,
            'data' => [
                'type' => 'payment_success',
                'order_id' => (string) $this->order->id,
                'order_number' => $this->order->order_number,
                'route' => "/order-details/{$this->order->id}",
            ],
        ];
    }
}
