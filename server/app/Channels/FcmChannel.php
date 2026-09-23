<?php

namespace App\Channels;

use App\Services\FcmService;
use Illuminate\Notifications\Notification;

class FcmChannel
{
    protected FcmService $fcmService;

    public function __construct(FcmService $fcmService)
    {
        $this->fcmService = $fcmService;
    }

    /**
     * إرسال الإشعار عبر قناة FCM Push
     */
    public function send($notifiable, Notification $notification): void
    {
        if (empty($notifiable->fcm_token)) {
            return;
        }

        if (! method_exists($notification, 'toFcm')) {
            return;
        }

        $fcmData = $notification->toFcm($notifiable);

        if (empty($fcmData)) {
            return;
        }

        $this->fcmService->sendPushNotification(
            $notifiable->fcm_token,
            $fcmData['title'] ?? '',
            $fcmData['body'] ?? '',
            $fcmData['data'] ?? []
        );
    }
}
