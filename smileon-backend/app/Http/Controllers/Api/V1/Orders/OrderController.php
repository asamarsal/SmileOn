<?php

namespace App\Http\Controllers\Api\V1\Orders;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Package;
use App\Models\PhotoCredit;
use App\Models\CreditTransaction;
use App\Models\NftCollection;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * OrderController — Handles credit package purchases and payment verification.
 * Covers section 4.10 of the plan.
 */
class OrderController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $orders = $request->user()->orders()
            ->with('items', 'paymentMethod:id,name,type,logo_url')
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 10);
        return response()->json(['success' => true, 'data' => $orders]);
    }

    public function latest(Request $request): JsonResponse
    {
        $order = $request->user()->orders()->with('items', 'paymentMethod')->latest()->first();
        return response()->json(['success' => true, 'data' => $order]);
    }

    public function show(string $uuid): JsonResponse
    {
        $order = Order::where('uuid', $uuid)->with('items', 'paymentMethod', 'voucher')->firstOrFail();
        return response()->json(['success' => true, 'data' => $order]);
    }

    /**
     * POST /api/v1/orders
     *
     * Create a new order. Supports credit_package type.
     * Requires Idempotency-Key header (enforced by middleware).
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'type'              => 'required|in:credit_package,voucher,print_job,merchandise',
            'package_id'        => 'required_if:type,credit_package|integer',
            'payment_method_id' => 'required|integer|exists:payment_methods,id',
            'voucher_code'      => 'nullable|string',
        ]);

        $user = $request->user();

        $order = DB::transaction(function () use ($request, $user) {
            $package     = null;
            $subtotal    = 0;
            $credits     = 0;
            $items       = [];

            if ($request->type === 'credit_package') {
                $package  = Package::findOrFail($request->package_id);
                $subtotal = $package->price;
                $credits  = $package->credits_amount;
                $items[]  = [
                    'item_type'  => 'Package',
                    'item_id'    => $package->id,
                    'item_name'  => $package->name,
                    'quantity'   => 1,
                    'unit_price' => $package->price,
                    'total'      => $package->price,
                ];
            }

            // Voucher validation
            $voucherId      = null;
            $discountAmount = 0;
            if ($request->voucher_code) {
                $voucher = \App\Models\Voucher::where('code', $request->voucher_code)->first();
                if ($voucher && $voucher->isValid()) {
                    $voucherId = $voucher->id;
                    if ($voucher->type === 'discount_pct') {
                        $discountAmount = $subtotal * ($voucher->value / 100);
                    } elseif ($voucher->type === 'discount_flat') {
                        $discountAmount = min($subtotal, $voucher->value);
                    }
                }
            }

            // Payment method fee
            $paymentMethod = \App\Models\PaymentMethod::findOrFail($request->payment_method_id);
            $adminFee = ($subtotal - $discountAmount) * ($paymentMethod->admin_fee / 100) + $paymentMethod->admin_fee_flat;
            $total    = max(0, $subtotal - $discountAmount + $adminFee);

            $order = Order::create([
                'user_id'           => $user->id,
                'payment_method_id' => $request->payment_method_id,
                'voucher_id'        => $voucherId,
                'subtotal'          => $subtotal,
                'discount_amount'   => $discountAmount,
                'admin_fee'         => $adminFee,
                'total'             => $total,
                'type'              => $request->type,
                'status'            => 'pending',
                'expired_at'        => now()->addHours(24),
            ]);

            foreach ($items as $item) {
                $order->items()->create($item);
            }

            // Store extra metadata like credits_amount
            if ($credits > 0) {
                $order->update(['payment_details' => array_merge(
                    $order->payment_details ?? [],
                    ['credits_to_grant' => $credits]
                )]);
            }

            return $order;
        });

        return response()->json(['success' => true, 'data' => $order->load('items', 'paymentMethod')], 201);
    }

    /**
     * POST /api/v1/orders/{uuid}/verify-payment
     *
     * Manually verify off-chain payment (QRIS manual, transfer).
     */
    public function verifyPayment(Request $request, string $uuid): JsonResponse
    {
        $order = Order::where('uuid', $uuid)->where('user_id', $request->user()->id)->firstOrFail();

        if ($order->status !== 'pending') {
            return response()->json(['success' => false, 'message' => 'Pesanan sudah diproses.'], 409);
        }

        // TODO: In production, call gateway API to verify
        // For now, auto-grant credits on successful verification

        DB::transaction(function () use ($order) {
            $order->update(['status' => 'paid', 'paid_at' => now()]);

            $creditsToGrant = $order->payment_details['credits_to_grant'] ?? 0;
            if ($creditsToGrant > 0) {
                $credit = $order->user->photoCredit ?? PhotoCredit::create(['user_id' => $order->user_id]);
                $before = $credit->balance;
                $credit->increment('balance', $creditsToGrant);
                $credit->increment('lifetime_earned', $creditsToGrant);

                CreditTransaction::create([
                    'user_id'        => $order->user_id,
                    'type'           => 'purchase',
                    'amount'         => $creditsToGrant,
                    'balance_before' => $before,
                    'balance_after'  => $before + $creditsToGrant,
                    'reference_type' => 'Order',
                    'reference_id'   => $order->id,
                    'created_at'     => now(),
                ]);
            }
        });

        return response()->json(['success' => true, 'message' => 'Pembayaran berhasil diverifikasi.', 'data' => $order->fresh()]);
    }

    public function onchainStatus(string $uuid): JsonResponse
    {
        $order = Order::where('uuid', $uuid)->firstOrFail();
        return response()->json(['success' => true, 'data' => ['tx_hash' => $order->payment_details['tx_hash'] ?? null, 'status' => $order->status]]);
    }

    public function web3Contracts(): JsonResponse
    {
        $contracts = NftCollection::where('is_active', true)->get(['name', 'contract_address', 'contract_type', 'chain_id']);
        return response()->json(['success' => true, 'data' => $contracts]);
    }

    public function web3SyncStatus(): JsonResponse
    {
        return response()->json(['success' => true, 'data' => ['synced' => true, 'last_block' => null]]);
    }
}
