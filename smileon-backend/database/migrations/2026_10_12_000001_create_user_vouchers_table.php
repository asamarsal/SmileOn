<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('user_vouchers', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('order_id')->nullable()->constrained('orders')->nullOnDelete();
            $table->string('voucher_code', 32)->unique(); // Format: SMLON-XXXXXXXX-XXXXXXXX-XXXXXXXX
            $table->string('title', 150);
            $table->string('category', 50)->default('event');
            $table->string('photo_count', 50);
            $table->unsignedInteger('credit_amount');
            $table->string('price_formatted', 50);
            $table->string('crypto_price', 50);
            $table->string('payment_method', 50)->default('QRIS');
            // status: Aktif | Digunakan | Kadaluarsa
            $table->string('status', 20)->default('Aktif');
            $table->string('image_path')->default('assets/images/voucher/wedding_package.jpg');
            $table->string('used_for_event', 150)->nullable();
            $table->timestamp('used_at')->nullable();
            $table->timestamp('expires_at');
            $table->timestamps();

            $table->index(['user_id', 'status']);
            $table->index('voucher_code');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('user_vouchers');
    }
};
