<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('product_reviews')) {
            Schema::create('product_reviews', function (Blueprint $table) {
                $table->id();
                $table->foreignId('product_id')->constrained()->cascadeOnDelete();
                $table->foreignId('user_id')->constrained()->cascadeOnDelete();
                $table->unsignedTinyInteger('rating'); // 1..5
                $table->text('comment')->nullable();
                // ملاءمة المقاس بنمط SHEIN: small | true_to_size | large
                $table->string('size_fit', 20)->default('true_to_size');
                $table->boolean('is_verified_purchase')->default(false);
                $table->timestamps();

                $table->unique(['product_id', 'user_id']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('product_reviews');
    }
};
