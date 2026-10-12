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
use Illuminate\Support\Facades\Http;

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
            'currency'          => 'nullable|string|in:IDR,USD',
            'voucher_code'      => 'nullable|string',
        ]);

        $user = $request->user();
        $currency = strtoupper($request->currency ?? 'IDR');

        $order = DB::transaction(function () use ($request, $user, $currency) {
            $package     = null;
            $subtotal    = 0;
            $credits     = 0;
            $items       = [];

            if ($request->type === 'credit_package') {
                $package  = Package::findOrFail($request->package_id);
                $unitPrice = $package->getPriceForCurrency($currency);
                $subtotal = $unitPrice;
                $credits  = $package->credits_amount;
                $items[]  = [
                    'item_type'  => 'Package',
                    'item_id'    => $package->id,
                    'item_name'  => $package->name,
                    'quantity'   => 1,
                    'unit_price' => $unitPrice,
                    'total'      => $unitPrice,
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
                'currency'          => $currency,
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

            if ($order->type === 'voucher') {
                \App\Models\UserVoucher::create([
                    'user_id'         => $order->user_id,
                    'order_id'        => $order->id,
                    'title'           => $order->items->first()?->item_name ?? 'Tiket Voucher SmileOn',
                    'category'        => 'Event',
                    'photo_count'     => ($creditsToGrant > 0 ? $creditsToGrant : 10) . ' Foto',
                    'credit_amount'   => $creditsToGrant > 0 ? $creditsToGrant : 10,
                    'price_formatted' => 'Rp ' . number_format($order->total_amount, 0, ',', '.'),
                    'crypto_price'    => $order->payment_details['crypto_amount'] ?? '0.05 MON',
                    'payment_method'  => $order->paymentMethod?->name ?? 'QRIS',
                    'status'          => 'Aktif',
                    'expires_at'      => now()->addDays(60),
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

    /**
     * POST /api/v1/payments/verify-monad
     *
     * Dual-Rail Instant Verifier: Queries Monad Testnet RPC directly
     * via eth_getTransactionReceipt to verify on-chain payment.
     */
    public function verifyMonad(Request $request): JsonResponse
    {
        $request->validate([
            'order_ref' => 'required|string',
            'tx_hash'   => ['required', 'string', 'regex:/^0x[a-fA-F0-9]{64}$/'],
            'amount'    => 'nullable|string',
        ]);

        $orderRef = $request->input('order_ref');
        $txHash   = strtolower($request->input('tx_hash'));

        $rpcUrl = config('services.monad.rpc_url', 'https://testnet-rpc.monad.xyz');
        $expectedPaymentHub = strtolower(config('services.monad.payment_hub_address', '0xFAB484e78053e3FE88351A6a8A9dD545bb6a41ff'));

        try {
            $rpcResponse = Http::timeout(10)->post($rpcUrl, [
                'jsonrpc' => '2.0',
                'method'  => 'eth_getTransactionReceipt',
                'params'  => [$txHash],
                'id'      => 1,
            ]);

            if (!$rpcResponse->successful()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Gagal menghubungi Monad Testnet RPC node.',
                ], 502);
            }

            $receipt = $rpcResponse->json('result');

            if (!$receipt) {
                return response()->json([
                    'success'  => false,
                    'verified' => false,
                    'status'   => 'pending',
                    'message'  => 'Transaksi belum ditambang atau sedang diproses di Monad Testnet mempool.',
                ], 202);
            }

            // Check transaction status: 0x1 is success
            $statusHex = $receipt['status'] ?? '0x0';
            if ($statusHex !== '0x1') {
                return response()->json([
                    'success'  => false,
                    'verified' => false,
                    'status'   => 'reverted',
                    'message'  => 'Transaksi on-chain gagal atau dibatalkan (reverted).',
                ], 422);
            }

            // Verify contract destination
            $toAddress = strtolower($receipt['to'] ?? '');
            if ($toAddress !== $expectedPaymentHub) {
                return response()->json([
                    'success'  => false,
                    'verified' => false,
                    'message'  => "Alamat kontrak tujuan ({$toAddress}) tidak sesuai dengan SmileOnPaymentHub ({$expectedPaymentHub}).",
                ], 422);
            }

            $blockNumber = isset($receipt['blockNumber']) ? hexdec($receipt['blockNumber']) : null;
            $fromAddress = strtolower($receipt['from'] ?? '');

            // Idempotent audit record in payment_webhooks
            $existingWebhook = DB::table('payment_webhooks')
                ->where('provider', 'monad')
                ->where('event_id', $txHash)
                ->first();

            if (!$existingWebhook) {
                DB::table('payment_webhooks')->insert([
                    'provider'    => 'monad',
                    'event_id'    => $txHash,
                    'raw_payload' => json_encode([
                        'order_ref'    => $orderRef,
                        'tx_hash'      => $txHash,
                        'from_address' => $fromAddress,
                        'block_number' => $blockNumber,
                        'verified_by'  => 'instant_rpc_rail',
                    ]),
                    'status'      => 'processed',
                    'received_at' => now(),
                ]);
            }

            // Try to match with internal Order record
            $order = Order::where('order_number', $orderRef)
                ->orWhere('uuid', $orderRef)
                ->first();

            if ($order && $order->status === 'pending') {
                DB::transaction(function () use ($order, $txHash, $blockNumber, $fromAddress) {
                    $order->update([
                        'status'   => 'paid',
                        'paid_at'  => now(),
                        'payment_details' => array_merge($order->payment_details ?? [], [
                            'tx_hash'      => $txHash,
                            'block_number' => $blockNumber,
                            'from_address' => $fromAddress,
                            'chain_id'     => 10143,
                            'verified_via' => 'instant_rpc',
                        ]),
                    ]);

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

                    if ($order->type === 'voucher') {
                        \App\Models\UserVoucher::create([
                            'user_id'         => $order->user_id,
                            'order_id'        => $order->id,
                            'title'           => $order->items->first()?->item_name ?? 'Tiket Voucher SmileOn',
                            'category'        => 'Event',
                            'photo_count'     => ($creditsToGrant > 0 ? $creditsToGrant : 10) . ' Foto',
                            'credit_amount'   => $creditsToGrant > 0 ? $creditsToGrant : 10,
                            'price_formatted' => 'Rp ' . number_format($order->total_amount, 0, ',', '.'),
                            'crypto_price'    => $order->payment_details['crypto_amount'] ?? '0.05 MON',
                            'payment_method'  => 'Monad Testnet',
                            'status'          => 'Aktif',
                            'expires_at'      => now()->addDays(60),
                        ]);
                    }
                });
            }

            return response()->json([
                'success'      => true,
                'verified'     => true,
                'status'       => 'paid',
                'order_ref'    => $orderRef,
                'tx_hash'      => $txHash,
                'block_number' => $blockNumber,
                'chain_id'     => 10143,
                'network'      => 'Monad Testnet',
                'explorer_url' => "https://testnet.monadexplorer.com/tx/{$txHash}",
                'message'      => 'Pembayaran on-chain Monad berhasil diverifikasi secara instan.',
                'order'        => $order ? $order->fresh(['items']) : null,
            ]);

        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan internal saat verifikasi transaksi: ' . $e->getMessage(),
            ], 500);
        }
    }
}
