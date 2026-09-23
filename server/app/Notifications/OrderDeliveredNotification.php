<?php

namespace App\Notifications;

use App\Channels\FcmChannel;
use App\Models\NotificationLog;
use App\Models\Order;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class OrderDeliveredNotification extends Notification
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
        $title = "تم تسليم طلبك بنجاح 🎉";
        $body = "شكراً لصلتك بنا! تم تسليم طلبك رقم #{$this->order->order_number} بنجاح";

        NotificationLog::create([
            'user_id' => $notifiable->id,
            'title' => $title,
            'body' => $body,
            'type' => 'order_delivered',
            'data' => [
                'order_id' => $this->order->id,
                'order_number' => $this->order->order_number,
            ],
        ]);

        return [
            'title' => $title,
            'body' => $body,
            'data' => [
                'type' => 'order_delivered',
                'order_id' => (string) $this->order->id,
                'order_number' => $this->order->order_number,
                'route' => "/order-details/{$this->order->id}",
            ],
        ];
    }
}
