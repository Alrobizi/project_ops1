<?php

namespace App\Notifications;

use App\Channels\FcmChannel;
use App\Models\NotificationLog;
use App\Models\Order;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class OrderPreparingNotification extends Notification
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
        $title = "طلبك قيد التجهيز 📦";
        $body = "جارٍ تجهيز طلبك رقم #{$this->order->order_number} ليتم شحنه في أقرب وقت";

        NotificationLog::create([
            'user_id' => $notifiable->id,
            'title' => $title,
            'body' => $body,
            'type' => 'order_preparing',
            'data' => [
                'order_id' => $this->order->id,
                'order_number' => $this->order->order_number,
            ],
        ]);

        return [
            'title' => $title,
            'body' => $body,
            'data' => [
                'type' => 'order_preparing',
                'order_id' => (string) $this->order->id,
                'order_number' => $this->order->order_number,
                'route' => "/order-details/{$this->order->id}",
            ],
        ];
    }
}
