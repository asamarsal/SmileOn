<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\Package;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * AdminPackageController — CRUD Pengaturan Harga & Paket Voucher Kuota oleh Admin.
 * Mendukung penetapan harga multi-currency (IDR, USD) dan Web3 Crypto (MON).
 */
class AdminPackageController extends Controller
{
    /**
     * GET /api/v1/admin/packages
     * Menampilkan semua paket (aktif & non-aktif) dengan opsi filter kategori.
     */
    public function index(Request $request): JsonResponse
    {
        $packages = Package::query()
            ->when($request->category, fn($q, $c) => $q->where('category', $c))
            ->when($request->has('is_active'), fn($q) => $q->where('is_active', filter_var($request->is_active, FILTER_VALIDATE_BOOLEAN)))
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Daftar seluruh paket berhasil dimuat.',
            'data'    => $packages,
        ]);
    }

    /**
     * POST /api/v1/admin/packages
     * Menambahkan paket voucher / kuota baru dengan harga IDR, USD, dan Crypto.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name'           => 'required|string|max:150',
            'description'    => 'nullable|string',
            'category'       => 'required|in:personal,event,bundle,member,special',
            'credits_amount' => 'required|integer|min:1',
            'price'          => 'required|numeric|min:0', // Harga IDR
            'price_usd'      => 'nullable|numeric|min:0', // Harga USD
            'crypto_price'   => 'nullable|string|max:50', // e.g. "1.00 MON"
            'currency'       => 'nullable|string|max:10', // Default 'IDR'
            'badge_label'    => 'nullable|string|max:30', // "POPULAR", "BEST VALUE"
            'is_active'      => 'nullable|boolean',
            'sort_order'     => 'nullable|integer',
        ]);

        if (empty($validated['currency'])) {
            $validated['currency'] = 'IDR';
        }

        $package = Package::create($validated);

        return response()->json([
            'success' => true,
            'message' => "Paket {$package->name} berhasil dibuat.",
            'data'    => $package,
        ], 201);
    }

    /**
     * GET /api/v1/admin/packages/{id}
     * Menampilkan detail satu paket.
     */
    public function show(int $id): JsonResponse
    {
        $package = Package::findOrFail($id);

        return response()->json([
            'success' => true,
            'data'    => $package,
        ]);
    }

    /**
     * PUT/PATCH /api/v1/admin/packages/{id}
     * Mengupdate informasi atau harga paket (IDR / USD / MON).
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $package = Package::findOrFail($id);

        $validated = $request->validate([
            'name'           => 'sometimes|required|string|max:150',
            'description'    => 'nullable|string',
            'category'       => 'sometimes|required|in:personal,event,bundle,member,special',
            'credits_amount' => 'sometimes|required|integer|min:1',
            'price'          => 'sometimes|required|numeric|min:0',
            'price_usd'      => 'nullable|numeric|min:0',
            'crypto_price'   => 'nullable|string|max:50',
            'currency'       => 'nullable|string|max:10',
            'badge_label'    => 'nullable|string|max:30',
            'is_active'      => 'nullable|boolean',
            'sort_order'     => 'nullable|integer',
        ]);

        $package->update($validated);

        return response()->json([
            'success' => true,
            'message' => "Paket {$package->name} berhasil diperbarui.",
            'data'    => $package,
        ]);
    }

    /**
     * PATCH /api/v1/admin/packages/{id}/toggle-active
     * Mengaktifkan atau menonaktifkan paket secara cepat.
     */
    public function toggleActive(int $id): JsonResponse
    {
        $package = Package::findOrFail($id);
        $package->update(['is_active' => !$package->is_active]);

        return response()->json([
            'success' => true,
            'message' => "Status paket {$package->name} berhasil diubah menjadi " . ($package->is_active ? 'Aktif' : 'Non-aktif') . ".",
            'data'    => ['is_active' => $package->is_active],
        ]);
    }

    /**
     * DELETE /api/v1/admin/packages/{id}
     * Menghapus paket dari sistem.
     */
    public function destroy(int $id): JsonResponse
    {
        $package = Package::findOrFail($id);
        $name = $package->name;
        $package->delete();

        return response()->json([
            'success' => true,
            'message' => "Paket {$name} berhasil dihapus dari sistem.",
        ]);
    }
}
