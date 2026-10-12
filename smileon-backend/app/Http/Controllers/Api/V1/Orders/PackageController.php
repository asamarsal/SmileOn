<?php

namespace App\Http\Controllers\Api\V1\Orders;

use App\Http\Controllers\Controller;
use App\Models\Package;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * PackageController — Credit package catalog.
 * Covers Section 4.10 packages of plan-backend-laravel.md
 */
class PackageController extends Controller
{
    /**
     * GET /api/v1/packages
     */
    public function index(Request $request): JsonResponse
    {
        if (Package::count() === 0) {
            $defaults = [
                ['name' => 'Wedding Package', 'category' => 'event', 'credits_amount' => 100, 'price' => 100000, 'crypto_price' => '1.00 MON', 'badge_label' => 'Hemat 25%', 'is_active' => true, 'sort_order' => 1],
                ['name' => 'Birthday Package', 'category' => 'event', 'credits_amount' => 50, 'price' => 60000, 'crypto_price' => '0.60 MON', 'badge_label' => 'Hemat 20%', 'is_active' => true, 'sort_order' => 2],
                ['name' => 'Graduation Package', 'category' => 'event', 'credits_amount' => 25, 'price' => 40000, 'crypto_price' => '0.40 MON', 'badge_label' => 'Hemat 15%', 'is_active' => true, 'sort_order' => 3],
                ['name' => 'Corporate Gathering', 'category' => 'event', 'credits_amount' => 300, 'price' => 250000, 'crypto_price' => '2.50 MON', 'badge_label' => 'Hemat 35%', 'is_active' => true, 'sort_order' => 4],
                ['name' => 'Festival & Concert', 'category' => 'event', 'credits_amount' => 500, 'price' => 400000, 'crypto_price' => '4.00 MON', 'badge_label' => 'Hemat 50%', 'is_active' => true, 'sort_order' => 5],
            ];
            foreach ($defaults as $d) {
                Package::create($d);
            }
        }

        $packages = Package::where('is_active', true)
            ->when($request->category, fn($q, $c) => $q->where('category', $c))
            ->orderBy('sort_order')
            ->get();

        return response()->json(['success' => true, 'data' => $packages]);
    }

    /**
     * GET /api/v1/packages/{id}
     */
    public function show(int $id): JsonResponse
    {
        $package = Package::where('is_active', true)->findOrFail($id);
        return response()->json(['success' => true, 'data' => $package]);
    }
}
