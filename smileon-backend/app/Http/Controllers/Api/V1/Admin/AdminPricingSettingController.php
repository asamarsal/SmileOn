<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\SystemPricingSetting;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * AdminPricingSettingController — Pengaturan Harga Foto Satuan, Cetak Fisik & Kurs Multi-Currency.
 */
class AdminPricingSettingController extends Controller
{
    /**
     * GET /api/v1/admin/pricing-settings
     * Menampilkan semua konfigurasi harga sistem.
     */
    public function index(): JsonResponse
    {
        $settings = SystemPricingSetting::orderBy('category')->orderBy('id')->get();

        return response()->json([
            'success' => true,
            'data'    => $settings,
        ]);
    }

    /**
     * GET /api/v1/pricing-settings (Public)
     * Endpoint publik untuk dibaca oleh aplikasi Flutter & Kiosk.
     */
    public function publicPricing(): JsonResponse
    {
        $settings = SystemPricingSetting::all()->keyBy('key');

        $singlePhoto = $settings->get('single_digital_photo');
        $singlePrint = $settings->get('single_physical_print');
        $exchangeRate = $settings->get('usd_idr_exchange_rate');

        return response()->json([
            'success' => true,
            'data'    => [
                'single_digital_photo' => [
                    'price_idr'        => (float) ($singlePhoto?->value_idr ?? 5000),
                    'price_usd'        => (float) ($singlePhoto?->value_usd ?? 0.35),
                    'crypto_price'     => $singlePhoto?->crypto_value ?? '0.05 MON',
                    'formatted_idr'    => 'Rp ' . number_format($singlePhoto?->value_idr ?? 5000, 0, ',', '.'),
                    'formatted_usd'    => '$' . number_format($singlePhoto?->value_usd ?? 0.35, 2),
                ],
                'single_physical_print' => [
                    'price_idr'        => (float) ($singlePrint?->value_idr ?? 20000),
                    'price_usd'        => (float) ($singlePrint?->value_usd ?? 1.35),
                    'crypto_price'     => $singlePrint?->crypto_value ?? '0.20 MON',
                    'formatted_idr'    => 'Rp ' . number_format($singlePrint?->value_idr ?? 20000, 0, ',', '.'),
                    'formatted_usd'    => '$' . number_format($singlePrint?->value_usd ?? 1.35, 2),
                ],
                'exchange_rate' => [
                    'usd_to_idr'       => (float) ($exchangeRate?->value_idr ?? 16000),
                ],
                'supported_currencies' => ['IDR', 'USD', 'MON'],
            ],
        ]);
    }

    /**
     * PUT/PATCH /api/v1/admin/pricing-settings/{id}
     * Mengupdate satu item pengaturan harga.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $setting = SystemPricingSetting::findOrFail($id);

        $validated = $request->validate([
            'label'        => 'sometimes|required|string|max:150',
            'value_idr'    => 'sometimes|required|numeric|min:0',
            'value_usd'    => 'sometimes|required|numeric|min:0',
            'crypto_value' => 'nullable|string|max:50',
            'description'  => 'nullable|string',
        ]);

        $setting->update($validated);

        return response()->json([
            'success' => true,
            'message' => "Pengaturan {$setting->label} berhasil diperbarui.",
            'data'    => $setting,
        ]);
    }

    /**
     * POST /api/v1/admin/pricing-settings/batch
     * Update beberapa parameter harga sekaligus (misal foto satuan + cetak fisik sekaligus).
     */
    public function batchUpdate(Request $request): JsonResponse
    {
        $request->validate([
            'settings'               => 'required|array',
            'settings.*.key'         => 'required|string|exists:system_pricing_settings,key',
            'settings.*.value_idr'   => 'required|numeric|min:0',
            'settings.*.value_usd'   => 'required|numeric|min:0',
            'settings.*.crypto_value'=> 'nullable|string|max:50',
        ]);

        foreach ($request->settings as $item) {
            SystemPricingSetting::where('key', $item['key'])->update([
                'value_idr'    => $item['value_idr'],
                'value_usd'    => $item['value_usd'],
                'crypto_value' => $item['crypto_value'] ?? null,
                'updated_at'   => now(),
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Pengaturan harga berhasil diperbarui secara massal.',
            'data'    => SystemPricingSetting::all(),
        ]);
    }
}
