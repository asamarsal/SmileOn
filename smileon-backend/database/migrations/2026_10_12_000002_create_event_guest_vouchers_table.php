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
        Schema::create('event_guest_vouchers', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('event_id')->constrained('events')->cascadeOnDelete();
            $table->string('guest_name', 150);
            $table->string('guest_slug', 100);
            $table->string('voucher_code', 100)->unique(); // Format: haikalronald-stevenbirthday
            $table->string('category', 50)->default('Teman'); // VIP | Keluarga | Teman | Vendor
            $table->unsignedInteger('quota_limit')->default(1);
            $table->unsignedInteger('quota_used')->default(0);
            $table->boolean('has_photo')->default(false);
            $table->timestamp('last_photo_at')->nullable();
            $table->string('qr_code_url')->nullable();
            // status: active | exhausted | revoked
            $table->string('status', 20)->default('active');
            $table->timestamps();

            $table->index(['event_id', 'voucher_code']);
            $table->index(['event_id', 'status']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('event_guest_vouchers');
    }
};
