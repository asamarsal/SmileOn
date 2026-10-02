<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\PaymentMethod;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminPaymentMethodController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        return response()->json(['success' => true, 'data' => PaymentMethod::orderBy('sort_order')->get()]);
    }

    public function publicIndex(): JsonResponse
    {
        return response()->json(['success' => true, 'data' => PaymentMethod::where('is_active', true)->orderBy('sort_order')->get()]);
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate(['type'=>'required|unique:payment_methods','name'=>'required','admin_fee'=>'nullable|numeric','admin_fee_flat'=>'nullable|numeric']);
        $pm = PaymentMethod::create($request->all());
        return response()->json(['success' => true, 'data' => $pm], 201);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $pm = PaymentMethod::findOrFail($id);
        $pm->update($request->all());
        return response()->json(['success' => true, 'data' => $pm]);
    }

    public function toggleActive(Request $request, int $id): JsonResponse
    {
        $pm = PaymentMethod::findOrFail($id);
        $pm->update(['is_active' => !$pm->is_active]);
        return response()->json(['success' => true, 'data' => ['is_active' => $pm->is_active]]);
    }

    public function destroy(int $id): JsonResponse
    {
        PaymentMethod::findOrFail($id)->delete();
        return response()->json(['success' => true, 'message' => 'Payment method dihapus.']);
    }
}
