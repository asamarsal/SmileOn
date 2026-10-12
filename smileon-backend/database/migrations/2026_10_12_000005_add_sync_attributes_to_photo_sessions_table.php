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
        Schema::table('photo_sessions', function (Blueprint $table) {
            if (!Schema::hasColumn('photo_sessions', 'title')) {
                $table->string('title', 150)->nullable()->after('session_code');
            }
            if (!Schema::hasColumn('photo_sessions', 'frame_asset_path')) {
                $table->string('frame_asset_path')->nullable()->after('frame_id');
            }
            if (!Schema::hasColumn('photo_sessions', 'bg_asset_path')) {
                $table->string('bg_asset_path')->nullable()->after('frame_asset_path');
            }
            if (!Schema::hasColumn('photo_sessions', 'mirrored_states')) {
                $table->json('mirrored_states')->nullable()->after('location');
            }
            if (!Schema::hasColumn('photo_sessions', 'filter_matrix')) {
                $table->json('filter_matrix')->nullable()->after('mirrored_states');
            }
            if (!Schema::hasColumn('photo_sessions', 'people_in_photo')) {
                $table->json('people_in_photo')->nullable()->after('filter_matrix');
            }
            if (!Schema::hasColumn('photo_sessions', 'is_paid')) {
                $table->boolean('is_paid')->default(false)->after('people_in_photo');
            }
            if (!Schema::hasColumn('photo_sessions', 'is_watermarked')) {
                $table->boolean('is_watermarked')->default(false)->after('is_paid');
            }
            if (!Schema::hasColumn('photo_sessions', 'sync_status')) {
                $table->string('sync_status', 20)->default('synced')->after('status'); // local_only | syncing | synced | failed
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('photo_sessions', function (Blueprint $table) {
            $table->dropColumn([
                'title',
                'frame_asset_path',
                'bg_asset_path',
                'mirrored_states',
                'filter_matrix',
                'people_in_photo',
                'is_paid',
                'is_watermarked',
                'sync_status',
            ]);
        });
    }
};
