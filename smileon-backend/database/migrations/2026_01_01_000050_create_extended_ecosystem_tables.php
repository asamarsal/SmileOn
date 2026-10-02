<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // ============================================================
        // USER NOTIFICATIONS
        // ============================================================
        if (!Schema::hasTable('user_notifications')) {
            Schema::create('user_notifications', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
                $table->string('type', 50);
                $table->string('title');
                $table->text('body')->nullable();
                $table->string('icon', 50)->nullable();
                $table->string('action_url')->nullable();
                $table->json('metadata')->nullable();
                $table->timestamp('read_at')->nullable();
                $table->timestamps();

                $table->index(['user_id', 'read_at']);
            });
        }

        // ============================================================
        // PAYMENT WEBHOOKS INBOX — already in 000040, skip if exists
        // ============================================================

        // ============================================================
        // LOYALTY ACCOUNTS (if not created via previous migration)
        // ============================================================
        if (!Schema::hasTable('loyalty_accounts')) {
            Schema::create('loyalty_accounts', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
                $table->unsignedInteger('points_balance')->default(0);
                $table->unsignedInteger('lifetime_earned')->default(0);
                $table->unsignedInteger('lifetime_redeemed')->default(0);
                $table->string('tier', 20)->default('Bronze');
                $table->unsignedSmallInteger('streak_days')->default(0);
                $table->date('last_check_in_date')->nullable();
                $table->timestamps();
            });
        }

        // ============================================================
        // LOYALTY TRANSACTIONS
        // ============================================================
        if (!Schema::hasTable('loyalty_transactions')) {
            Schema::create('loyalty_transactions', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained()->cascadeOnDelete();
                $table->string('type', 50); // earn | redeem | check_in | referral_reward
                $table->integer('points'); // positive or negative
                $table->integer('balance_before')->default(0);
                $table->integer('balance_after')->default(0);
                $table->string('reference_type', 50)->nullable();
                $table->unsignedBigInteger('reference_id')->nullable();
                $table->string('description')->nullable();
                $table->timestamp('created_at')->useCurrent();

                $table->index(['user_id', 'created_at']);
            });
        }

        // ============================================================
        // LOYALTY REWARDS CATALOG
        // ============================================================
        if (!Schema::hasTable('loyalty_rewards')) {
            Schema::create('loyalty_rewards', function (Blueprint $table) {
                $table->id();
                $table->string('name');
                $table->text('description')->nullable();
                $table->string('type', 30); // credit | voucher | merch_discount
                $table->unsignedInteger('points_required');
                $table->decimal('value', 15, 2)->default(0);
                $table->boolean('is_active')->default(true);
                $table->integer('stock')->nullable();
                $table->timestamps();
            });
        }

        // ============================================================
        // REFERRALS
        // ============================================================
        if (!Schema::hasTable('referrals')) {
            Schema::create('referrals', function (Blueprint $table) {
                $table->id();
                $table->foreignId('referrer_id')->constrained('users')->cascadeOnDelete();
                $table->foreignId('referred_id')->unique()->constrained('users')->cascadeOnDelete();
                $table->string('status', 20)->default('pending'); // pending | rewarded
                $table->timestamp('rewarded_at')->nullable();
                $table->timestamps();

                $table->index(['referrer_id', 'status']);
            });
        }

        // ============================================================
        // USER SHIPPING ADDRESSES
        // ============================================================
        if (!Schema::hasTable('user_shipping_addresses')) {
            Schema::create('user_shipping_addresses', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained()->cascadeOnDelete();
                $table->string('label', 50)->default('Rumah');
                $table->string('recipient_name', 100);
                $table->string('phone_number', 20);
                $table->string('address_line1');
                $table->string('address_line2')->nullable();
                $table->string('village', 100)->nullable();
                $table->string('district', 100);
                $table->string('city', 100);
                $table->string('province', 100);
                $table->string('postal_code', 10);
                $table->boolean('is_default')->default(false);
                $table->timestamps();

                $table->index(['user_id', 'is_default']);
            });
        }

        // ============================================================
        // MERCHANDISE ORDERS
        // ============================================================
        if (!Schema::hasTable('merchandise_orders')) {
            Schema::create('merchandise_orders', function (Blueprint $table) {
                $table->id();
                $table->uuid('uuid')->unique();
                $table->foreignId('user_id')->constrained()->cascadeOnDelete();
                $table->foreignId('order_id')->nullable()->constrained('orders')->nullOnDelete();
                $table->foreignId('address_id')->nullable()->constrained('user_shipping_addresses')->nullOnDelete();
                $table->json('address_snapshot')->nullable();
                $table->string('courier', 30)->nullable();
                $table->string('courier_service', 30)->nullable();
                $table->unsignedInteger('shipping_cost')->default(0);
                $table->string('tracking_number', 100)->nullable();
                $table->string('high_res_print_url')->nullable();
                $table->json('crop_config')->nullable();
                $table->string('status', 20)->default('pending');
                $table->timestamp('shipped_at')->nullable();
                $table->timestamp('delivered_at')->nullable();
                $table->timestamps();

                $table->index(['user_id', 'status']);
            });
        }

        // ============================================================
        // PERSONAL QR TOKENS — Instant booth login
        // ============================================================
        // Already created in 2026_01_01_000020, skip if exists

        // ============================================================
        // USER SAVED FRAMES
        // ============================================================
        if (!Schema::hasTable('user_saved_frames')) {
            Schema::create('user_saved_frames', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained()->cascadeOnDelete();
                $table->foreignId('frame_id')->constrained('frames')->cascadeOnDelete();
                $table->timestamp('created_at')->useCurrent();

                $table->unique(['user_id', 'frame_id']);
            });
        }

        // ============================================================
        // USER SESSIONS (device tracking) — if not already created
        // ============================================================
        if (!Schema::hasTable('user_sessions')) {
            Schema::create('user_sessions', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained()->cascadeOnDelete();
                $table->string('device_name')->nullable();
                $table->string('device_type', 30)->nullable();
                $table->string('platform', 30)->nullable();
                $table->string('os_version', 30)->nullable();
                $table->string('app_version', 30)->nullable();
                $table->string('browser', 50)->nullable();
                $table->boolean('is_mobile')->default(false);
                $table->string('ip_address', 45)->nullable();
                $table->text('user_agent')->nullable();
                $table->string('token_hash', 64)->nullable();
                $table->timestamp('last_seen_at')->nullable();
                $table->timestamps();

                $table->unique(['user_id', 'token_hash']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('user_saved_frames');
        Schema::dropIfExists('merchandise_orders');
        Schema::dropIfExists('user_shipping_addresses');
        Schema::dropIfExists('referrals');
        Schema::dropIfExists('loyalty_rewards');
        Schema::dropIfExists('loyalty_transactions');
        Schema::dropIfExists('loyalty_accounts');
        Schema::dropIfExists('payment_webhooks');
        Schema::dropIfExists('user_notifications');
    }
};
