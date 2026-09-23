<?php

return [
    /*
    |--------------------------------------------------------------------------
    | إعدادات المحافظ الإلكترونية
    |--------------------------------------------------------------------------
    |
    | يتيح لك هذا الملف تكامل وتخصيص المحافظ الإلكترونية (أم فلوس والقطيبي)
    | بالإضافة إلى تحديد وقت انتهاء المهلة (300 ثانية = 5 دقائق)
    | وتفعيل وضع المحاكاة (mock_mode) للاختبار الشامل.
    |
    */

    'mock_mode' => env('PAYMENT_MOCK_MODE', true),

    'timeout_seconds' => env('PAYMENT_TIMEOUT_SECONDS', 300), // 5 دقائق

    'wallets' => [
        'am_flous' => [
            'name' => 'أم فلوس',
            'code' => 'am_flous',
            'icon' => 'wallet',
            'api_url' => env('AM_FLOUS_API_URL', 'https://api.amflous.com/v1'),
            'merchant_id' => env('AM_FLOUS_MERCHANT_ID', 'demo_merchant'),
            'secret_key' => env('AM_FLOUS_SECRET_KEY', 'demo_secret'),
        ],
        'qutaibi' => [
            'name' => 'القطيبي',
            'code' => 'qutaibi',
            'icon' => 'account_balance_wallet',
            'api_url' => env('QUTAIBI_API_URL', 'https://api.qutaibi.com/v1'),
            'merchant_id' => env('QUTAIBI_MERCHANT_ID', 'demo_merchant'),
            'secret_key' => env('QUTAIBI_SECRET_KEY', 'demo_secret'),
        ],
    ],
];
