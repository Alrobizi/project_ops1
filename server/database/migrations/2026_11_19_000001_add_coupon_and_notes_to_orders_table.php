<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            if (! Schema::hasColumn('orders', 'coupon_code')) {
                $table->string('coupon_code', 60)->nullable()->after('payment_method');
            }
            if (! Schema::hasColumn('orders', 'discount_amount')) {
                $table->decimal('discount_amount', 10, 2)->default(0)->after('subtotal');
            }
            if (! Schema::hasColumn('orders', 'notes')) {
                $table->text('notes')->nullable()->after('payment_expires_at');
            }
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $cols = array_filter(
                ['coupon_code', 'discount_amount', 'notes'],
                fn (string $col) => Schema::hasColumn('orders', $col)
            );
            if (! empty($cols)) {
                $table->dropColumn($cols);
            }
        });
    }
};
