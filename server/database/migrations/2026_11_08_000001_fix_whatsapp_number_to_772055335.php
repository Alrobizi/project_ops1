<?php

use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    public function up(): void
    {
        // تحديث أرقام الواتساب والهاتف إلى الرقم الصحيح في قاعدة البيانات الحالية
        $correct = '772055335';

        $keys = ['whatsapp_number', 'whatsapp_transfer_number', 'store_phone'];

        foreach ($keys as $key) {
            \DB::table('settings')->updateOrInsert(
                ['key' => $key],
                [
                    'value'      => $correct,
                    'group'      => 'general',
                    'updated_at' => now(),
                    'created_at' => now(),
                ]
            );
        }
    }

    public function down(): void
    {
        // لا حاجة للتراجع
    }
};

