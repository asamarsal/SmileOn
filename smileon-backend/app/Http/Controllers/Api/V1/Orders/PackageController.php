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
