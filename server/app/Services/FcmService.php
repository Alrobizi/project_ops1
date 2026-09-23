<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FcmService
{
    /**
     * إرسال إشعار FCM للمستخدم عبر التوكن
     */
    public function sendPushNotification(string $fcmToken, string $title, string $body, array $data = []): bool
    {
        $serverKey = env('FCM_SERVER_KEY');

        if (empty($serverKey)) {
            Log::info("FCM Notification Simulated (FCM_SERVER_KEY is not set in .env): Title: {$title}, Body: {$body}, Token: {$fcmToken}");
            return true;
        }

        try {
            $response = Http::withHeaders([
                'Authorization' => 'key=' . $serverKey,
                'Content-Type' => 'application/json',
            ])->post('https://fcm.googleapis.com/fcm/send', [
                'to' => $fcmToken,
                'notification' => [
                    'title' => $title,
                    'body' => $body,
                    'sound' => 'default',
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                ],
                'data' => array_merge($data, [
                    'title' => $title,
                    'body' => $body,
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                ]),
                'priority' => 'high',
            ]);

            if ($response->successful()) {
                Log::info("FCM Notification Sent Successfully to {$fcmToken}");
                return true;
            }

            Log::error("FCM Send Error: " . $response->body());
            return false;
        } catch (\Throwable $e) {
            Log::error("FCM Exception: " . $e->getMessage());
            return false;
        }
    }
}