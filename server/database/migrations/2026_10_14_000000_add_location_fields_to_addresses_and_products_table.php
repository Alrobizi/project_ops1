<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [الموقع الجغرافي] إضافة حقول الموقع الجغرافي لجدولي العناوين والمنتجات:
 * - addresses: المحافظة + إحداثيات المشتري (GPS أو خريطة)
 * - products: موقع البائع (المحافظة/المدينة/الإحداثيات) لحساب المسافة
 *   وفرز المنتجات حسب الأقرب (Nearest First) وتقدير تكلفة وزمن التوصيل.
 * الافتراضي: اليمن - عدن (جنوب اليمن) - كريتر.
 */
return new class extends Migration
{
    public function up(): void
    {
        // إضافة المحافظة والإحداثيات لعناوين المشترين
        Schema::table('addresses', function (Blueprint $table) {
            $table->string('governorate')->default('عدن')->after('user_id');
            $table->double('latitude')->nullable()->after('is_default');
            $table->double('longitude')->nullable()->after('latitude');
            $table->boolean('is_gps_location')->default(false)->after('longitude');
        });

        // إضافة موقع البائع للمنتجات (الافتراضي: متجر بركة عدن - كريتر)
        Schema::table('products', function (Blueprint $table) {
            $table->string('seller_name')->default('متجر بركة عدن')->after('is_active');
            $table->string('seller_governorate')->default('عدن')->after('seller_name');
            $table->string('seller_city')->default('كريتر')->after('seller_governorate');
            $table->double('seller_latitude')->default(12.7917)->after('seller_city');
            $table->double('seller_longitude')->default(45.0067)->after('seller_latitude');
        });
    }

    public function down(): void
    {
        Schema::table('addresses', function (Blueprint $table) {
            $table->dropColumn(['governorate', 'latitude', 'longitude', 'is_gps_location']);
        });

        Schema::table('products', function (Blueprint $table) {
            $table->dropColumn([
                'seller_name',
                'seller_governorate',
                'seller_city',
                'seller_latitude',
                'seller_longitude',
            ]);
        });
    }
};
