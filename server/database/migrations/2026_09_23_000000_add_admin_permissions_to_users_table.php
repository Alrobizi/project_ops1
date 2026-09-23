<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * صلاحيات لوحة التحكم للمستخدمين من نوع admin.
     * القيمة مصفوفة JSON من مفاتيح الأقسام المسموحة:
     * products, orders, customers, discounts, reports, content, marketing, settings, users
     * المصفوفة الفارغة تعني وصول كامل (مدير متجر رئيسي).
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->json('admin_permissions')->nullable()->after('role');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('admin_permissions');
        });
    }
};

