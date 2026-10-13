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
        Schema::table('events', function (Blueprint $table) {
            if (!Schema::hasColumn('events', 'venue')) {
                $table->string('venue', 150)->nullable()->after('description');
            }
            if (!Schema::hasColumn('events', 'host_voucher_code')) {
                $table->string('host_voucher_code', 50)->nullable()->after('access_code');
            }
        });

        if (Schema::hasTable('user_sessions')) {
            Schema::table('user_sessions', function (Blueprint $table) {
                if (!Schema::hasColumn('user_sessions', 'fcm_token')) {
                    $table->string('fcm_token', 255)->nullable();
                }
            });
        }

        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'fcm_token')) {
                $table->string('fcm_token', 255)->nullable()->after('remember_token');
            }
        });

        Schema::table('photo_sessions', function (Blueprint $table) {
            if (!Schema::hasColumn('photo_sessions', 'guest_voucher_id')) {
                $table->foreignId('guest_voucher_id')->nullable()->after('event_id')->constrained('event_guest_vouchers')->nullOnDelete();
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('events', function (Blueprint $table) {
            $table->dropColumn(['venue', 'host_voucher_code']);
        });

        if (Schema::hasTable('user_sessions') && Schema::hasColumn('user_sessions', 'fcm_token')) {
            Schema::table('user_sessions', function (Blueprint $table) {
                $table->dropColumn('fcm_token');
            });
        }

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('fcm_token');
        });

        Schema::table('photo_sessions', function (Blueprint $table) {
            $table->dropForeign(['guest_voucher_id']);
            $table->dropColumn('guest_voucher_id');
        });
    }
};
