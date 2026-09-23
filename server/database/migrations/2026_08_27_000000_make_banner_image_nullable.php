<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * جعل عمود image في جدول banners قابلًا للقيمة الفارغة
     * (لدعم إضافة بانر نصي/بروابط فقط من تطبيق الأدمن).
     */
    public function up(): void
    {
        Schema::table('banners', function (Blueprint $table) {
            $table->string('image')->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('banners', function (Blueprint $table) {
            $table->string('image')->nullable(false)->change();
        });
    }
};
