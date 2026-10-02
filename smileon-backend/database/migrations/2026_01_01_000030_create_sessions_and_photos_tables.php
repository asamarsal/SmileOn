<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // ============================================================
        // PHOTO SESSIONS — Deterministic state machine
        // ============================================================
        Schema::create('photo_sessions', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->string('session_code', 20)->unique(); // SO-2026-X89K
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('event_id')->nullable()->constrained('events')->nullOnDelete();
            $table->foreignId('booth_id')->nullable()->constrained('event_booths')->nullOnDelete();
            $table->foreignId('frame_id')->nullable()->constrained('frames')->nullOnDelete();
            // State machine: draft | waiting | active | completing | processing | completed | cancelled | expired
            $table->string('status', 20)->default('draft');
            $table->string('mode', 20)->default('personal'); // personal | event
            $table->string('orientation', 10)->default('portrait');
            $table->unsignedSmallInteger('credits_required')->default(1);
            $table->unsignedSmallInteger('photos_count')->default(4);
            $table->unsignedSmallInteger('photos_taken')->default(0);
            $table->json('participants')->nullable(); // names of people in the photo
            $table->string('location')->nullable();
            $table->timestamp('expires_at')->nullable(); // TTL 20 minutes for public booths
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->softDeletes();
            $table->timestamps();

            $table->index(['user_id', 'status']);
            $table->index(['event_id', 'status']);
        });

        // ============================================================
        // PHOTOS — Individual shots per session
        // ============================================================
        Schema::create('photos', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('session_id')->constrained('photo_sessions')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->unsignedTinyInteger('shot_number'); // 1, 2, 3, 4
            $table->string('storage_key');   // Cloudflare R2 object key
            $table->string('original_url');  // R2 direct URL
            $table->string('watermarked_url')->nullable();
            $table->string('sha256_hash', 64)->nullable();
            $table->unsignedInteger('file_size_bytes')->nullable();
            $table->unsignedSmallInteger('width_px')->nullable();
            $table->unsignedSmallInteger('height_px')->nullable();
            $table->string('mime_type', 50)->nullable();
            $table->boolean('show_watermark')->default(true);
            // status: uploading | ready | failed
            $table->string('status', 20)->default('uploading');
            $table->softDeletes();
            $table->timestamps();

            $table->index(['session_id', 'shot_number']);
        });

        // ============================================================
        // PHOTO STRIPS — Final composite strips
        // ============================================================
        Schema::create('photo_strips', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('session_id')->constrained('photo_sessions')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('storage_key');
            $table->string('clean_url');        // no watermark
            $table->string('watermarked_url')->nullable(); // with SmileOn watermark
            $table->string('gif_url')->nullable();         // animated GIF version
            $table->string('high_res_print_url')->nullable(); // 300 DPI for merchandise
            $table->string('share_token', 64)->nullable()->unique();
            $table->timestamp('share_expires_at')->nullable();
            $table->unsignedSmallInteger('width_px')->nullable();
            $table->unsignedSmallInteger('height_px')->nullable();
            $table->string('aspect_ratio', 10)->nullable(); // e.g. 2:6, 4:6
            $table->string('print_size_inch', 20)->nullable(); // e.g. 2x6
            $table->unsignedInteger('file_size_bytes')->nullable();
            $table->boolean('show_watermark')->default(true);
            // status: pending | processing | ready | failed
            $table->string('status', 20)->default('pending');
            $table->softDeletes();
            $table->timestamps();
        });

        // ============================================================
        // STORAGE SYNCS — Google Drive reconciliation
        // ============================================================
        Schema::create('storage_syncs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('strip_id')->nullable()->constrained('photo_strips')->nullOnDelete();
            $table->string('source_url');      // R2 URL
            $table->string('destination_type', 30)->default('google_drive');
            $table->string('destination_id')->nullable(); // Google Drive file ID
            $table->string('destination_url')->nullable();
            // status: pending | syncing | synced | failed
            $table->string('status', 20)->default('pending');
            $table->unsignedSmallInteger('attempts')->default(0);
            $table->text('last_error')->nullable();
            $table->timestamp('synced_at')->nullable();
            $table->timestamps();

            $table->index(['status', 'user_id']);
        });

        // ============================================================
        // OUTBOX EVENTS — Transactional Outbox Pattern
        // ============================================================
        Schema::create('outbox_events', function (Blueprint $table) {
            $table->id();
            $table->string('aggregate_type', 100); // Order, Session, Nft
            $table->unsignedBigInteger('aggregate_id');
            $table->string('event_type', 100);     // OrderCreated, SessionCompleted
            $table->json('payload');
            // status: pending | dispatched | failed
            $table->string('status', 20)->default('pending');
            $table->unsignedSmallInteger('attempts')->default(0);
            $table->text('last_error')->nullable();
            $table->timestamp('dispatched_at')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['status', 'created_at']);
            $table->index(['aggregate_type', 'aggregate_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('outbox_events');
        Schema::dropIfExists('storage_syncs');
        Schema::dropIfExists('photo_strips');
        Schema::dropIfExists('photos');
        Schema::dropIfExists('photo_sessions');
    }
};
