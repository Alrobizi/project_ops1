<?php

namespace App\Observers;

use App\Models\AdminNotification;
use App\Models\Order;
use App\Notifications\OrderCancelledNotification;
use App\Notifications\OrderCreatedNotification;
use App\Notifications\OrderDeliveredNotification;
use App\Notifications\OrderPreparingNotification;
use App\Notifications\OrderShippedNotification;
use Illuminate\Support\Facades\Log;

class OrderObserver
{
    /**
     * Handle the Order "created" event.
     */
    public function created(Order $order): void
    {
        try {
            // 1. إرسال إشعار للمستخدم بتأكيد إنشاء الطلب
            if ($order->user) {
                $order->user->notify(new OrderCreatedNotification($order));
            }

            // 2. إنشاء إشعار للإدارة بوجود طلب جديد
            $customerName = $order->user ? $order->user->name : 'عميل';
            AdminNotification::create([
                'title' => "طلب جديد #{$order->order_number}",
                'body' => "تم استلام طلب جديد بقيمة {$order->total} ر.ي من {$customerName}",
                'type' => 'order_new',
            ]);
        } catch (\Throwable $e) {
            Log::error("Error in OrderObserver::created: " . $e->getMessage());
        }
    }

    /**
     * Handle the Order "updated" event.
     */
    public function updated(Order $order): void
    {
        if (!$order->wasChanged('status')) {
            return;
        }

        try {
            $user = $order->user;
            if (!$user) {
                return;
            }

            switch ($order->status) {
                case 'processing':
                    $user->notify(new OrderPreparingNotification($order));
                    break;
                case 'shipped':
                    $user->notify(new OrderShippedNotification($order));
                    break;
                case 'delivered':
                    $user->notify(new OrderDeliveredNotification($order));
                    break;
                case 'cancelled':
                    $user->notify(new OrderCancelledNotification($order));
                    break;
            }
        } catch (\Throwable $e) {
            Log::error("Error in OrderObserver::updated: " . $e->getMessage());
        }
    }
}
