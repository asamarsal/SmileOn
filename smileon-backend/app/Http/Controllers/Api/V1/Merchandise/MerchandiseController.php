<?php

namespace App\Http\Controllers\Api\V1\Merchandise;

use App\Http\Controllers\Controller;
use App\Models\MerchandiseOrder;
use App\Models\UserShippingAddress;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * MerchandiseController — Covers Section 4.15 of plan-backend-laravel.md
 *
 * Handles physical photo print orders including address book,
 * product catalog, shipping estimation, and order placement.
 */
class MerchandiseController extends Controller
{
    // ============================================================
    // PRODUCT CATALOG (static for now; move to DB model in Phase 8)
    // ============================================================

    private array $products = [
        ['slug' => 'polaroid-4x6', 'name' => 'Cetak Polaroid 4x6', 'price_idr' => 15000, 'print_ratio' => '4:6'],
        ['slug' => 'polaroid-2x6-strip', 'name' => 'Cetak Strip 2x6', 'price_idr' => 12000, 'print_ratio' => '2:6'],
        ['slug' => 'gantungan-kunci', 'name' => 'Gantungan Kunci Foto', 'price_idr' => 25000, 'print_ratio' => '1:1'],
        ['slug' => 'mug-foto', 'name' => 'Mug Foto Custom', 'price_idr' => 85000, 'print_ratio' => '16:9'],
        ['slug' => 'kalung-foto', 'name' => 'Kalung Foto Locket', 'price_idr' => 75000, 'print_ratio' => '1:1'],
        ['slug' => 'kanvas-30x45', 'name' => 'Kanvas 30x45 cm', 'price_idr' => 150000, 'print_ratio' => '2:3'],
    ];

    /**
     * GET /api/v1/merchandise/products
     */
    public function products(Request $request): JsonResponse
    {
        return response()->json(['success' => true, 'data' => $this->products]);
    }

    /**
     * GET /api/v1/merchandise/products/{slug}
     */
    public function productDetail(string $slug): JsonResponse
    {
        $product = collect($this->products)->firstWhere('slug', $slug);

        if (!$product) {
            return response()->json(['success' => false, 'message' => 'Produk tidak ditemukan.'], 404);
        }

        return response()->json(['success' => true, 'data' => $product]);
    }

    // ============================================================
    // SHIPPING ADDRESS BOOK
    // ============================================================

    /**
     * GET /api/v1/user/shipping-addresses
     */
    public function addresses(Request $request): JsonResponse
    {
        $addresses = UserShippingAddress::where('user_id', $request->user()->id)
            ->orderByDesc('is_default')
            ->orderByDesc('created_at')
            ->get();

        return response()->json(['success' => true, 'data' => $addresses]);
    }

    /**
     * POST /api/v1/user/shipping-addresses
     */
    public function storeAddress(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'label'          => 'required|string|max:50',
            'recipient_name' => 'required|string|max:100',
            'phone_number'   => 'required|string|max:20',
            'address_line1'  => 'required|string|max:255',
            'address_line2'  => 'nullable|string|max:255',
            'district'       => 'required|string|max:100',
            'city'           => 'required|string|max:100',
            'province'       => 'required|string|max:100',
            'postal_code'    => 'required|string|max:10',
            'is_default'     => 'boolean',
        ]);

        $user = $request->user();

        if ($request->boolean('is_default')) {
            UserShippingAddress::where('user_id', $user->id)->update(['is_default' => false]);
        }

        $address = UserShippingAddress::create(array_merge(
            $validated,
            ['user_id' => $user->id]
        ));

        return response()->json(['success' => true, 'data' => $address], 201);
    }

    /**
     * PATCH /api/v1/user/shipping-addresses/{id}
     */
    public function updateAddress(Request $request, int $id): JsonResponse
    {
        $address = UserShippingAddress::where('user_id', $request->user()->id)->findOrFail($id);

        if ($request->boolean('is_default')) {
            UserShippingAddress::where('user_id', $request->user()->id)->update(['is_default' => false]);
        }

        $address->update($request->only([
            'label', 'recipient_name', 'phone_number', 'address_line1',
            'address_line2', 'village', 'district', 'city', 'province',
            'postal_code', 'is_default',
        ]));

        return response()->json(['success' => true, 'data' => $address]);
    }

    /**
     * DELETE /api/v1/user/shipping-addresses/{id}
     */
    public function destroyAddress(Request $request, int $id): JsonResponse
    {
        UserShippingAddress::where('user_id', $request->user()->id)->findOrFail($id)->delete();
        return response()->json(['success' => true, 'message' => 'Alamat dihapus.']);
    }

    // ============================================================
    // SHIPPING COST ESTIMATION
    // ============================================================

    /**
     * POST /api/v1/merchandise/calculate-shipping
     *
     * Estimate shipping cost via courier API (RajaOngkir/Biteship).
     * Stub for now — returns placeholder.
     */
    public function calculateShipping(Request $request): JsonResponse
    {
        $request->validate([
            'address_id'    => 'required|integer',
            'product_slug'  => 'required|string',
            'quantity'      => 'required|integer|min:1',
            'courier'       => 'required|in:jne,jnt,sicepat,anteraja,gojek',
        ]);

        // TODO: Integrate with RajaOngkir or Biteship API
        $estimates = [
            'jne'      => ['service' => 'REG', 'etd' => '2-3 hari', 'cost_idr' => 18000],
            'jnt'      => ['service' => 'REG', 'etd' => '2-4 hari', 'cost_idr' => 15000],
            'sicepat'  => ['service' => 'BEST', 'etd' => '1-2 hari', 'cost_idr' => 20000],
            'anteraja' => ['service' => 'REG', 'etd' => '2-3 hari', 'cost_idr' => 16000],
            'gojek'    => ['service' => 'GoSend Sameday', 'etd' => 'Hari ini', 'cost_idr' => 25000],
        ];

        return response()->json([
            'success' => true,
            'data'    => $estimates[$request->courier] ?? [],
        ]);
    }

    // ============================================================
    // MERCHANDISE ORDERS
    // ============================================================

    /**
     * GET /api/v1/merchandise/orders
     */
    public function orders(Request $request): JsonResponse
    {
        $orders = MerchandiseOrder::where('user_id', $request->user()->id)
            ->with('order:id,uuid,status,total')
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 10);

        return response()->json(['success' => true, 'data' => $orders]);
    }

    /**
     * POST /api/v1/merchandise/orders
     *
     * Place a physical print/merch order.
     * Idempotency-Key required.
     */
    public function placeOrder(Request $request): JsonResponse
    {
        $request->validate([
            'strip_uuid'     => 'required|string',
            'product_slug'   => 'required|string',
            'address_id'     => 'required|integer',
            'courier'        => 'required|string',
            'quantity'       => 'integer|min:1|max:10',
            'crop_config'    => 'nullable|array',
        ]);

        $user    = $request->user();
        $address = UserShippingAddress::where('user_id', $user->id)->findOrFail($request->address_id);
        $strip   = \App\Models\PhotoStrip::where('uuid', $request->strip_uuid)->where('user_id', $user->id)->firstOrFail();

        $product  = collect($this->products)->firstWhere('slug', $request->product_slug);
        $quantity = $request->quantity ?? 1;
        $subtotal = $product['price_idr'] * $quantity;
        $shipping = 18000; // placeholder
        $total    = $subtotal + $shipping;

        $merch = DB::transaction(function () use ($user, $request, $address, $strip, $total, $subtotal, $shipping, $product, $quantity) {
            $order = \App\Models\Order::create([
                'user_id'   => $user->id,
                'subtotal'  => $subtotal,
                'admin_fee' => $shipping,
                'total'     => $total,
                'type'      => 'merchandise',
                'status'    => 'pending',
                'expired_at'=> now()->addHours(24),
            ]);

            $order->items()->create([
                'item_type'  => 'Merchandise',
                'item_id'    => 0,
                'item_name'  => $product['name'],
                'quantity'   => $quantity,
                'unit_price' => $product['price_idr'],
                'total'      => $subtotal,
            ]);

            return MerchandiseOrder::create([
                'user_id'          => $user->id,
                'order_id'         => $order->id,
                'address_id'       => $address->id,
                'address_snapshot' => $address->toArray(),
                'courier'          => $request->courier,
                'shipping_cost'    => $shipping,
                'high_res_print_url' => $strip->clean_url ?? $strip->watermarked_url,
                'crop_config'      => $request->crop_config,
                'status'           => 'pending',
            ]);
        });

        return response()->json(['success' => true, 'data' => $merch->load('order'), 'message' => 'Pesanan dibuat. Lanjutkan ke pembayaran.'], 201);
    }

    /**
     * PATCH /api/v1/admin/merchandise/orders/{uuid}/fulfill
     *
     * Admin/vendor: update fulfillment status and tracking number.
     */
    public function fulfill(Request $request, string $uuid): JsonResponse
    {
        $request->validate([
            'status'          => 'required|in:processing,shipped,delivered,cancelled',
            'tracking_number' => 'nullable|string|max:100',
        ]);

        $merch = MerchandiseOrder::where('uuid', $uuid)->firstOrFail();
        $merch->update([
            'status'          => $request->status,
            'tracking_number' => $request->tracking_number,
            'shipped_at'      => $request->status === 'shipped' ? now() : $merch->shipped_at,
            'delivered_at'    => $request->status === 'delivered' ? now() : $merch->delivered_at,
        ]);

        return response()->json(['success' => true, 'data' => $merch]);
    }
}
