<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // ============================================================
        // PHOTO CREDITS — Financial-grade user balance (dual ledger)
        // ============================================================
        Schema::create('photo_credits', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->unsignedBigInteger('balance')->default(0);          // available credits
            $table->unsignedBigInteger('reserved_balance')->default(0); // held by active sessions
            $table->unsignedBigInteger('lifetime_earned')->default(0);
            $table->unsignedBigInteger('lifetime_used')->default(0);
            $table->timestamps();

            $table->unique('user_id');
        });

        // ============================================================
        // CREDIT TRANSACTIONS — Immutable ledger
        // ============================================================
        Schema::create('credit_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            // type: purchase | session_reserve | session_release | session_use | admin_adjust | referral | voucher
            $table->string('type', 30);
            $table->bigInteger('amount'); // positive = credit, negative = debit
            $table->unsignedBigInteger('balance_before');
            $table->unsignedBigInteger('balance_after');
            $table->string('reference_type', 50)->nullable(); // Order, Session, etc
            $table->unsignedBigInteger('reference_id')->nullable();
            $table->text('note')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['user_id', 'type']);
        });

        // ============================================================
        // FRAME CATEGORIES — Dynamic categories managed by Admin
        // ============================================================
        Schema::create('frame_categories', function (Blueprint $table) {
            $table->id();
            $table->string('name', 100);
            $table->string('slug', 100)->unique();
            $table->string('icon', 255)->nullable();      // URL or emoji
            $table->string('badge_label', 30)->nullable(); // e.g. "HOT", "NEW"
            $table->boolean('is_active')->default(true);
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();
        });

        // ============================================================
        // FRAMES — Marketplace frames
        // ============================================================
        Schema::create('frames', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('creator_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('category_id')->nullable()->constrained('frame_categories')->nullOnDelete();
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('thumbnail_url');
            $table->string('frame_url');  // Full-res transparent PNG
            $table->string('orientation', 10)->default('portrait'); // portrait | landscape | square
            $table->unsignedSmallInteger('width_px')->nullable();
            $table->unsignedSmallInteger('height_px')->nullable();
            $table->decimal('price_credits', 10, 2)->default(0);
            $table->boolean('is_free')->default(true);
            // status: active | under_review | suspended | banned
            $table->string('status', 20)->default('active');
            $table->unsignedInteger('report_count')->default(0);
            $table->unsignedInteger('download_count')->default(0);
            $table->unsignedInteger('use_count')->default(0);
            // Promotion fields
            $table->unsignedInteger('priority_score')->default(0);
            $table->timestamp('promoted_until')->nullable();
            $table->softDeletes();
            $table->timestamps();

            $table->index(['status', 'is_free', 'orientation']);
            $table->index(['priority_score', 'promoted_until']);
        });

        // ============================================================
        // FRAME REPORTS — Auto-moderation
        // ============================================================
        Schema::create('frame_reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('frame_id')->constrained('frames')->cascadeOnDelete();
            $table->foreignId('reporter_id')->constrained('users')->cascadeOnDelete();
            $table->string('reason', 100);
            $table->text('notes')->nullable();
            // status: pending | reviewed | dismissed
            $table->string('status', 20)->default('pending');
            $table->timestamps();

            $table->unique(['frame_id', 'reporter_id']);
        });

        // ============================================================
        // USER SAVED FRAMES — Favorites / collection
        // ============================================================
        Schema::create('user_saved_frames', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('frame_id')->constrained('frames')->cascadeOnDelete();
            $table->timestamp('created_at')->useCurrent();

            $table->unique(['user_id', 'frame_id']);
        });

        // ============================================================
        // PAYMENT METHODS — Dynamic channels (Admin-controlled)
        // ============================================================
        Schema::create('payment_methods', function (Blueprint $table) {
            $table->id();
            // type: qris | va_bank | ewallet | monad_mon | monad_usdt | crypto
            $table->string('type', 30)->unique();
            $table->string('name', 100);
            $table->string('logo_url')->nullable();
            $table->decimal('admin_fee', 10, 2)->default(0); // percentage
            $table->decimal('admin_fee_flat', 15, 2)->default(0); // flat amount
            $table->text('instructions')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->json('metadata')->nullable(); // gateway-specific config
            $table->timestamps();
        });

        // ============================================================
        // VOUCHERS
        // ============================================================
        Schema::create('vouchers', function (Blueprint $table) {
            $table->id();
            $table->string('code', 50)->unique();
            $table->string('name');
            $table->text('description')->nullable();
            // type: credit_bonus | discount_pct | discount_flat | free_print | strip_pct
            $table->string('type', 30);
            $table->decimal('value', 10, 2)->default(0);
            $table->decimal('discount_strip_pct', 5, 2)->default(0);
            $table->unsignedSmallInteger('free_strip_copies')->default(0);
            $table->unsignedInteger('max_uses')->nullable();
            $table->unsignedInteger('used_count')->default(0);
            $table->timestamp('valid_from')->nullable();
            $table->timestamp('valid_until')->nullable();
            $table->boolean('is_active')->default(true);
            $table->softDeletes();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('vouchers');
        Schema::dropIfExists('payment_methods');
        Schema::dropIfExists('user_saved_frames');
        Schema::dropIfExists('frame_reports');
        Schema::dropIfExists('frames');
        Schema::dropIfExists('frame_categories');
        Schema::dropIfExists('credit_transactions');
        Schema::dropIfExists('photo_credits');
    }
};
