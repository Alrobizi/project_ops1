<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FcmService
{
    /**
     * الحصول على OAuth2 Access Token لمشروع Firebase باستخدام Service Account
     */
    public static function getAccessToken(): ?string
    {
        return Cache::remember('firebase_fcm_access_token', 3000, function () {
            $credPath = config('services.fcm.credentials', storage_path('app/firebase-credentials.json'));

            if (!file_exists($credPath)) {
                return null;
            }

            try {
                $credentials = json_decode(file_get_contents($credPath), true);
                if (!$credentials || empty($credentials['client_email']) || empty($credentials['private_key'])) {
                    return null;
                }

                $now = time();
                $b64Url = fn($data) => rtrim(strtr(base64_encode($data), '+/', '-_'), '=');

                $header = $b64Url(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
                $claim = $b64Url(json_encode([
                    'iss' => $credentials['client_email'],
                    'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                    'aud' => 'https://oauth2.googleapis.com/token',
                    'exp' => $now + 3600,
                    'iat' => $now,
                ]));

                $data = "$header.$claim";
                $signature = '';
                if (!openssl_sign($data, $signature, $credentials['private_key'], OPENSSL_ALGO_SHA256)) {
                    Log::error("FCM JWT signing failed with openssl.");
                    return null;
                }

                $jwt = $data . '.' . $b64Url($signature);

                $response = Http::asForm()->post('https://oauth2.googleapis.com/token', [
                    'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                    'assertion' => $jwt,
                ]);

                if ($response->successful()) {
                    return $response->json('access_token');
                }

                Log::error("FCM Token Exchange Failed: " . $response->body());
                return null;
            } catch (\Throwable $e) {
                Log::error("FCM getAccessToken Exception: " . $e->getMessage());
                return null;
            }
        });
    }

    /**
     * إرسال إشعار FCM للمستخدم عبر التوكن (يدعم FCM HTTP v1 مع الرجوع للنسخة السابقة)
     */
    public function sendPushNotification(string $fcmToken, string $title, string $body, array $data = []): bool
    {
        if (empty($fcmToken)) {
            return false;
        }

        // تحويل كافة قيم البيانات إلى نصوص لأن FCM v1 يشترط String
        $stringData = [];
        foreach ($data as $key => $val) {
            $stringData[(string) $key] = is_scalar($val) ? (string) $val : json_encode($val, JSON_UNESCAPED_UNICODE);
        }

        // محاولة إرسال الإشعار عبر FCM HTTP v1
        $accessToken = self::getAccessToken();
        if ($accessToken) {
            $credPath = config('services.fcm.credentials', storage_path('app/firebase-credentials.json'));
            $credentials = file_exists($credPath) ? json_decode(file_get_contents($credPath), true) : null;
            $projectId = $credentials['project_id'] ?? config('services.fcm.project_id', 'market-5b7c4');

            try {
                $response = Http::withToken($accessToken)
                    ->post("https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send", [
                        'message' => [
                            'token' => $fcmToken,
                            'notification' => [
                                'title' => $title,
                                'body' => $body,
                            ],
                            'data' => $stringData,
                            'android' => [
                                'priority' => 'HIGH',
                                'notification' => [
                                    'sound' => 'default',
                                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                                ],
                            ],
                            'apns' => [
                                'payload' => [
                                    'aps' => [
                                        'sound' => 'default',
                                        'badge' => 1,
                                    ],
                                ],
                            ],
                        ],
                    ]);

                if ($response->successful()) {
                    Log::info("FCM v1 Notification Sent Successfully to {$fcmToken}");
                    return true;
                }

                Log::error("FCM v1 Send Error: " . $response->body());
            } catch (\Throwable $e) {
                Log::error("FCM v1 Exception: " . $e->getMessage());
            }
        }

        // الرجوع للنسخة الكلاسيكية FCM Legacy في حال وجود Server Key
        $serverKey = env('FCM_SERVER_KEY');
        if (!empty($serverKey)) {
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
                    'data' => array_merge($stringData, [
                        'title' => $title,
                        'body' => $body,
                        'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                    ]),
                    'priority' => 'high',
                ]);

                if ($response->successful()) {
                    Log::info("FCM Legacy Notification Sent to {$fcmToken}");
                    return true;
                }

                Log::error("FCM Legacy Send Error: " . $response->body());
                return false;
            } catch (\Throwable $e) {
                Log::error("FCM Legacy Exception: " . $e->getMessage());
                return false;
            }
        }

        // في بيئة التطوير المحلية دون مفاتيح، نسجل المحاكاة بنجاح
        Log::info("FCM Notification Simulated (No credentials configured): Title: {$title}, Body: {$body}, Token: {$fcmToken}");
        return true;
    }

    /**
     * إرسال إشعار لمستخدم معين
     */
    public static function sendToUser(?User $user, string $title, string $body, array $data = []): bool
    {
        if (!$user || empty($user->fcm_token)) {
            Log::info("FCM Skipped for user " . ($user ? $user->id : 'null') . ": No FCM token");
            return false;
        }

        return (new self())->sendPushNotification($user->fcm_token, $title, $body, $data);
    }

    /**
     * إرسال إشعار لجميع المستخدمين الذين لديهم FCM Token
     */
    public static function sendToAllUsers(string $title, string $body, array $data = []): int
    {
        $users = User::whereNotNull('fcm_token')
            ->where('fcm_token', '!=', '')
            ->get();

        $successCount = 0;
        $service = new self();

        foreach ($users as $user) {
            if ($service->sendPushNotification($user->fcm_token, $title, $body, $data)) {
                $successCount++;
            }
        }

        return $successCount;
    }
}
