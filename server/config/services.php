<?php

// معرّف عميل الويب (Web client ID) الافتراضي لمشروع Google/Firebase الخاص بالتطبيق.
// هذا المعرّف عام (ليس سراً) ويمكن تغييره عبر متغيرات البيئة.
$defaultGoogleClientId = '866528014908-ubkmbauq5ffitlqvc1ffc37f0k92uff0.apps.googleusercontent.com';

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    'fcm' => [
        'project_id' => env('FCM_PROJECT_ID'),
        'credentials' => env('FCM_CREDENTIALS', storage_path('app/firebase-credentials.json')),
    ],

    'google' => [
        // يُستخدم للتحقق من أن التوكن صادر لتطبيقنا فعلاً (حقل aud)
        'client_id' => env('GOOGLE_CLIENT_ID', $defaultGoogleClientId),
        'client_secret' => env('GOOGLE_CLIENT_SECRET'),

        // قائمة معرّفات العملاء المسموح بها (مفصولة بفواصل)،
        // الافتراضي هو معرّف عميل الويب فقط.
        'allowed_client_ids' => array_values(array_unique(array_filter(array_map(
            'trim',
            explode(',', (string) env('GOOGLE_ALLOWED_CLIENT_IDS', ''))
        )))) ?: [env('GOOGLE_CLIENT_ID', $defaultGoogleClientId)],
    ],

];
