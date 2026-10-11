<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Tambah kolom multi-currency pada tabel packages
        Schema::table('packages', function (Blueprint $table) {
            if (!Schema::hasColumn('packages', 'price_usd')) {
                $table->decimal('price_usd', 10, 2)->nullable()->after('price');
            }
            if (!Schema::hasColumn('packages', 'crypto_price')) {
                $table->string('crypto_price', 50)->nullable()->after('price_usd');
            }
        });

        // 2. Buat tabel system_pricing_settings untuk pengaturan harga foto satuan & cetak
        if (!Schema::hasTable('system_pricing_settings')) {
            Schema::create('system_pricing_settings', function (Blueprint $table) {
                $table->id();
                $table->string('key', 100)->unique();
                $table->string('label', 150);
                $table->string('category', 50)->default('pricing'); // pricing, fee, exchange_rate
                $table->decimal('value_idr', 15, 2)->default(0);
                $table->decimal('value_usd', 10, 2)->default(0);
                $table->string('crypto_value', 50)->nullable();
                $table->text('description')->nullable();
                $table->timestamps();
            });

            // Seed default pricing
            DB::table('system_pricing_settings')->insert([
                [
                    'key'          => 'single_digital_photo',
                    'label'        => 'Harga Foto Satuan Digital (HD)',
                    'category'     => 'photo_single',
                    'value_idr'    => 5000.00,
                    'value_usd'    => 0.35,
                    'crypto_value' => '0.05 MON',
                    'description'  => 'Harga per frame foto satuan digital resolusi tinggi tanpa watermark.',
                    'created_at'   => now(),
                    'updated_at'   => now(),
                ],
                [
                    'key'          => 'single_physical_print',
                    'label'        => 'Harga Cetak Fisik Per Lembar (Photostrip)',
                    'category'     => 'print',
                    'value_idr'    => 20000.00,
                    'value_usd'    => 1.35,
                    'crypto_value' => '0.20 MON',
                    'description'  => 'Biaya cetak fisik photostrip di mesin booth kiosk.',
                    'created_at'   => now(),
                    'updated_at'   => now(),
                ],
                [
                    'key'          => 'custom_watermark_removal',
                    'label'        => 'Biaya Hapus Watermark Custom',
                    'category'     => 'feature',
                    'value_idr'    => 15000.00,
                    'value_usd'    => 1.00,
                    'crypto_value' => '0.15 MON',
                    'description'  => 'Biaya tambahan untuk menghilangkan watermark SmileOn pada sesi personal.',
                    'created_at'   => now(),
                    'updated_at'   => now(),
                ],
                [
                    'key'          => 'usd_idr_exchange_rate',
                    'label'        => 'Kurs Konversi 1 USD ke IDR',
                    'category'     => 'exchange_rate',
                    'value_idr'    => 16000.00,
                    'value_usd'    => 1.00,
                    'crypto_value' => null,
                    'description'  => 'Acuan kurs konversi IDR ke USD untuk kalkulasi checkout multi-currency.',
                    'created_at'   => now(),
                    'updated_at'   => now(),
                ],
            ]);
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('system_pricing_settings');

        Schema::table('packages', function (Blueprint $table) {
            if (Schema::hasColumn('packages', 'price_usd')) {
                $table->dropColumn('price_usd');
            }
            if (Schema::hasColumn('packages', 'crypto_price')) {
                $table->dropColumn('crypto_price');
            }
        });
    }
};
