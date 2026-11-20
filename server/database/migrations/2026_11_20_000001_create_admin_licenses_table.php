<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('admin_licenses')) {
            Schema::create('admin_licenses', function (Blueprint $table) {
                $table->id();
                $table->string('license_key', 80)->unique();
                $table->string('label', 150)->default('ترخيص لوحة التحكم');
                $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
                $table->boolean('is_active')->default(true);
                $table->boolean('is_master')->default(false);
                $table->timestamp('expires_at')->nullable();
                $table->timestamp('last_used_at')->nullable();
                $table->string('last_used_ip', 64)->nullable();
                $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
                $table->timestamps();
            });
        }

        // إنشاء الترخيص الرئيسي الافتراضي لضمان عدم إغلاق اللوحة على المالك
        $masterKey = env('ADMIN_MASTER_LICENSE_KEY', 'BRK-ADEN-2026-MASTER');
        $exists = DB::table('admin_licenses')->where('is_master', true)->exists();
        if (! $exists && ! empty($masterKey)) {
            DB::table('admin_licenses')->insert([
                'license_key' => strtoupper(trim($masterKey)),
                'label' => 'الترخيص الرئيسي (المالك)',
                'is_active' => true,
                'is_master' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('admin_licenses');
    }
};
