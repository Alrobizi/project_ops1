<?php

namespace App\Notifications;

use App\Channels\FcmChannel;
use App\Models\NotificationLog;
use App\Models\Order;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class OrderCancelledNotification extends Notification
{
    use Queueable;

    public Order $order;

    public function __construct(Order $order)
    {
        $this->order = $order;
    }

    public function via($notifiable): array
    {
        return [FcmChannel::class];
    }

    public function toFcm($notifiable): array
    {
        $title = "تم إلغاء طلبك ❌";
        $body = "تم إلغاء طلبك رقم #{$this->order->order_number}. إذا كان لديك أي استفسار يسعدنا تواصلك مع خدمة العملاء.";

        NotificationLog::create([
            'user_id' => $notifiable->id,
            'title' => $title,
            'body' => $body,
            'type' => 'order_cancelled',
            'data' => [
                'order_id' => $this->order->id,
                'order_number' => $this->order->order_number,
                'route' => "/order-details/{$this->order->id}",
            ],
        ]);

        return [
            'title' => $title,
            'body' => $body,
            'data' => [
                'type' => 'order_cancelled',
                'order_id' => (string) $this->order->id,
                'order_number' => (string) $this->order->order_number,
                'route' => "/order-details/{$this->order->id}",
            ],
        ];
    }
}
