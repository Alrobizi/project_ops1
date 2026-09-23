<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('settings', function (Blueprint $table) {
            $table->id();
            $table->string('key')->unique();
            $table->text('value')->nullable();
            $table->string('group')->default('general'); // general, payment, shipping, notification
            $table->timestamps();
        });

        // إدراج إعدادات افتراضية
        $settings = [
            ['key' => 'store_name', 'value' => 'متجر الإلكترونيات', 'group' => 'general'],
            ['key' => 'store_email', 'value' => 'info@store.com', 'group' => 'general'],
            ['key' => 'store_phone', 'value' => '777123456', 'group' => 'general'],
            ['key' => 'store_address', 'value' => 'صنعاء، اليمن', 'group' => 'general'],
            ['key' => 'store_currency', 'value' => 'YER', 'group' => 'general'],
            ['key' => 'store_language', 'value' => 'ar', 'group' => 'general'],
            ['key' => 'cash_on_delivery', 'value' => '1', 'group' => 'payment'],
            ['key' => 'credit_card', 'value' => '1', 'group' => 'payment'],
            ['key' => 'e_wallet', 'value' => '0', 'group' => 'payment'],
            ['key' => 'bank_transfer', 'value' => '1', 'group' => 'payment'],
            ['key' => 'min_order_amount', 'value' => '50', 'group' => 'payment'],
            ['key' => 'transaction_fee', 'value' => '2.5', 'group' => 'payment'],
            ['key' => 'shipping_default_cost', 'value' => '25', 'group' => 'shipping'],
            ['key' => 'free_shipping_threshold', 'value' => '200', 'group' => 'shipping'],
            ['key' => 'delivery_days', 'value' => '3', 'group' => 'shipping'],
            ['key' => 'order_notifications', 'value' => '1', 'group' => 'notification'],
            ['key' => 'customer_notifications', 'value' => '1', 'group' => 'notification'],
            ['key' => 'marketing_notifications', 'value' => '0', 'group' => 'notification'],
            ['key' => 'stock_notifications', 'value' => '1', 'group' => 'notification'],
            ['key' => 'push_notifications', 'value' => '1', 'group' => 'notification'],
            ['key' => 'email_notifications', 'value' => '0', 'group' => 'notification'],
            ['key' => 'sms_notifications', 'value' => '1', 'group' => 'notification'],
        ];

        foreach ($settings as $setting) {
            \DB::table('settings')->insert(array_merge($setting, [
                'created_at' => now(),
                'updated_at' => now(),
            ]));
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('settings');
    }
};