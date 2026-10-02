<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // ============================================================
        // EVENTS
        // ============================================================
        Schema::create('events', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('organizer_id')->constrained('users')->cascadeOnDelete();
            $table->string('name');
            $table->text('description')->nullable();
            $table->string('banner_url')->nullable();
            $table->json('cover_visual')->nullable(); // JSONB for color/theme settings
            $table->timestamp('starts_at')->nullable();
            $table->timestamp('ends_at')->nullable();
            $table->timestamp('expired_at')->nullable();
            $table->boolean('is_event_started')->default(false);
            // status: draft | active | completed | cancelled
            $table->string('status', 20)->default('draft');
            $table->string('access_code', 20)->nullable()->unique(); // Invite QR code
            $table->unsignedInteger('total_credits')->default(0);    // Pool credits for guests
            $table->unsignedInteger('used_credits')->default(0);
            $table->unsignedInteger('reserved_credits')->default(0);
            $table->boolean('force_remove_watermark')->default(false);
            $table->json('settings')->nullable();
            $table->softDeletes();
            $table->timestamps();

            $table->index(['organizer_id', 'status']);
        });

        // ============================================================
        // EVENT FRAMES — Max 3 per event
        // ============================================================
        Schema::create('event_frames', function (Blueprint $table) {
            $table->id();
            $table->foreignId('event_id')->constrained('events')->cascadeOnDelete();
            $table->foreignId('frame_id')->nullable()->constrained('frames')->nullOnDelete();
            $table->unsignedTinyInteger('slot_index'); // 1, 2, or 3
            $table->boolean('is_custom')->default(false);
            $table->string('custom_frame_url')->nullable();
            $table->timestamp('attached_at')->useCurrent();

            $table->unique(['event_id', 'slot_index']); // enforce max 3 slots
        });

        // ============================================================
        // EVENT VOUCHERS
        // ============================================================
        Schema::create('event_vouchers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('event_id')->constrained('events')->cascadeOnDelete();
            $table->foreignId('voucher_id')->constrained('vouchers')->cascadeOnDelete();
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();

            $table->unique(['event_id', 'voucher_id']);
        });

        // ============================================================
        // EVENT PARTICIPANTS — Guests who checked in
        // ============================================================
        Schema::create('event_participants', function (Blueprint $table) {
            $table->id();
            $table->foreignId('event_id')->constrained('events')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('role', 20)->default('guest'); // guest | organizer
            $table->timestamp('checked_in_at')->nullable();
            $table->timestamps();

            $table->unique(['event_id', 'user_id']);
            $table->index('user_id');
        });

        // ============================================================
        // EVENT BOOTHS — Hardware authentication & telemetry
        // ============================================================
        Schema::create('event_booths', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('event_id')->constrained('events')->cascadeOnDelete();
            $table->foreignId('organizer_id')->constrained('users')->cascadeOnDelete();
            $table->string('booth_name')->nullable();
            $table->string('pairing_code', 50)->nullable()->unique(); // One-time pairing code
            $table->string('device_fingerprint', 64)->nullable();  // SHA256 of device hw info
            $table->string('access_token_hash', 64)->nullable();  // SHA256(access_token)
            $table->string('refresh_token_hash', 64)->nullable(); // SHA256(refresh_token)
            $table->timestamp('access_token_expires_at')->nullable();  // 60 minutes
            $table->timestamp('refresh_token_expires_at')->nullable(); // 30 days
            // status: paired | active | revoked
            $table->string('status', 20)->default('active');
            $table->json('hardware_info')->nullable(); // device model, OS, etc.
            // Latest telemetry snapshot
            $table->string('printer_status', 20)->nullable();
            $table->unsignedSmallInteger('paper_remaining')->nullable();
            $table->string('camera_status', 20)->nullable();
            $table->unsignedSmallInteger('disk_free_pct')->nullable();
            $table->unsignedSmallInteger('latency_ms')->nullable();
            $table->timestamp('last_heartbeat_at')->nullable();
            $table->timestamp('revoked_at')->nullable();
            $table->timestamps();

            $table->index(['event_id', 'status']);
        });

        // ============================================================
        // PERSONAL QR AUTH TOKENS — Temporary booth login
        // ============================================================
        Schema::create('personal_qr_tokens', function (Blueprint $table) {
            $table->id();
            $table->string('token', 64)->unique();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            // status: pending | confirmed | expired
            $table->string('status', 20)->default('pending');
            $table->string('ip_address', 45)->nullable();
            $table->timestamp('expires_at');
            $table->timestamps();

            $table->index('token');
            $table->index('expires_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('personal_qr_tokens');
        Schema::dropIfExists('event_booths');
        Schema::dropIfExists('event_participants');
        Schema::dropIfExists('event_vouchers');
        Schema::dropIfExists('event_frames');
        Schema::dropIfExists('events');
    }
};
