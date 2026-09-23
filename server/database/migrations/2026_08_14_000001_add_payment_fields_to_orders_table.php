<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->enum('payment_status', ['pending', 'paid', 'failed', 'expired'])->default('pending')->after('payment_method');
            $table->string('wallet_name')->nullable()->after('payment_status');
            $table->timestamp('payment_expires_at')->nullable()->after('wallet_name');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['payment_status', 'wallet_name', 'payment_expires_at']);
        });
    }
};
