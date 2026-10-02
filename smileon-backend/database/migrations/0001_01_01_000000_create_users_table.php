<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // ============================================================
        // USERS — Core identity table
        // ============================================================
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->string('username')->nullable()->unique();
            $table->string('name');
            $table->string('email')->nullable()->unique();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password')->nullable(); // nullable for OAuth/Web3 users
            $table->string('avatar_url')->nullable();
            $table->string('phone_number', 20)->nullable();
            // auth_method: google | wallet | email
            $table->string('auth_method', 20)->default('email');
            // wallet info
            $table->string('wallet_address', 100)->nullable()->unique();
            $table->string('wallet_type', 30)->nullable(); // metamask | coinbase | etc
            $table->string('network', 30)->nullable(); // monad | ethereum | etc
            // Google OAuth
            $table->text('google_access_token')->nullable();
            $table->text('google_refresh_token')->nullable();
            $table->timestamp('google_token_expires_at')->nullable();
            // Role: admin | organizer | user | guest
            $table->string('role', 20)->default('user');
            $table->string('locale', 10)->default('id');
            $table->boolean('is_active')->default(true);
            $table->string('referral_code', 20)->nullable()->unique();
            $table->foreignId('referred_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('last_login_at')->nullable();
            $table->rememberToken();
            $table->softDeletes();
            $table->timestamps();

            $table->index(['role', 'is_active']);
            $table->index('wallet_address');
        });

        // ============================================================
        // USER SESSIONS (multi-device sessions) — replaces default sessions
        // ============================================================
        Schema::create('user_sessions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('device_name')->nullable();
            $table->string('device_type', 30)->nullable(); // mobile | tablet | desktop | kiosk
            $table->string('platform', 30)->nullable(); // ios | android | web | flutter
            $table->string('os_version', 50)->nullable();
            $table->string('app_version', 30)->nullable();
            $table->string('browser', 100)->nullable();
            $table->boolean('is_mobile')->default(false);
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->string('token_hash', 64)->nullable(); // SHA256 of Sanctum token
            $table->timestamp('last_seen_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'token_hash']);
        });

        // ============================================================
        // IDEMPOTENCY KEYS — prevents double payment/session/mint
        // ============================================================
        Schema::create('idempotency_keys', function (Blueprint $table) {
            $table->id();
            $table->string('key', 36); // UUID v4
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('endpoint', 255);
            $table->string('status', 20)->default('processing'); // processing | completed | failed
            $table->smallInteger('response_status')->nullable();
            $table->longText('response_body')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->timestamp('expires_at');

            $table->unique(['key', 'user_id']);
            $table->index('expires_at');
        });

        // ============================================================
        // ADMIN AUDIT LOGS — immutable trail of admin actions
        // ============================================================
        Schema::create('admin_audit_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('admin_id')->constrained('users')->cascadeOnDelete();
            $table->string('action', 100); // e.g. user.suspend, frame.promote
            $table->string('entity_type', 100)->nullable(); // User, Frame, Order
            $table->unsignedBigInteger('entity_id')->nullable();
            $table->json('before')->nullable(); // state before change
            $table->json('after')->nullable();  // state after change
            $table->text('reason')->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->string('user_agent')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['entity_type', 'entity_id']);
            $table->index('admin_id');
        });

        // ============================================================
        // USER ACTIVITY LOGS
        // ============================================================
        Schema::create('user_activity_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('action', 100);
            $table->string('entity_type', 100)->nullable();
            $table->unsignedBigInteger('entity_id')->nullable();
            $table->string('description')->nullable();
            $table->json('metadata')->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->string('user_agent')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['user_id', 'action']);
        });

        // ============================================================
        // PASSWORD RESET TOKENS
        // ============================================================
        Schema::create('password_reset_tokens', function (Blueprint $table) {
            $table->string('email')->primary();
            $table->string('token');
            $table->timestamp('created_at')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('user_activity_logs');
        Schema::dropIfExists('admin_audit_logs');
        Schema::dropIfExists('idempotency_keys');
        Schema::dropIfExists('user_sessions');
        Schema::dropIfExists('users');
        Schema::dropIfExists('password_reset_tokens');
    }
};

