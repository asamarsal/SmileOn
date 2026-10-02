<?php

namespace App\Http\Controllers\Api\V1\Webhooks;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\PhotoCredit;
use App\Models\CreditTransaction;
use App\Models\OutboxEvent;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * PaymentWebhookController — Idempotent webhook inbox.
 * Covers Section 4.10 webhooks & Outbox Pattern (plan-backend-laravel.md Item #5 & #11)
 *
 * Security:
 *   - Midtrans: SHA512(order_number + status_code + gross_amount + ServerKey)
 *   - Xendit: X-CALLBACK-TOKEN header validation
 *   - Monad: Envio HyperSync dispatcher (JWT or shared secret)
 */
class PaymentWebhookController extends Controller
{
    /**
     * POST /api/v1/webhooks/payment/{provider}
     *
     * Generic payment gateway callback (Midtrans, Xendit).
     * Stored in payment_webhooks for idempotent processing.
     */
    public function receive(Request $request, string $provider): JsonResponse
    {
        $allowedProviders = ['midtrans', 'xendit', 'monad'];

        if (!in_array(strtolower($provider), $allowedProviders)) {
            return response()->json(['status' => 'error', 'message' => 'Provider tidak dikenal.'], 400);
        }

        $payload  = $request->all();
        $eventId  = $this->extractEventId($provider, $payload);
        $valid    = $this->verifySignature($provider, $request);

        if (!$valid) {
            Log::warning("Webhook signature verification failed for {$provider}", ['ip' => $request->ip()]);
            return response()->json(['status' => 'error', 'message' => 'Signature tidak valid.'], 401);
        }

        // Idempotent insert — skip if already received
        $existing = DB::table('payment_webhooks')
            ->where('provider', $provider)
            ->where('event_id', $eventId)
            ->first();

        if ($existing) {
            return response()->json(['status' => 'ok', 'message' => 'Already received.']);
        }

        DB::table('payment_webhooks')->insert([
            'provider'   => $provider,
            'event_id'   => $eventId,
            'raw_payload'=> json_encode($payload),
            'status'     => 'pending',
            'received_at'=> now(),
        ]);

        // Write to outbox for atomic dispatch to queue worker
        OutboxEvent::create([
            'aggregate_type' => 'PaymentWebhook',
            'aggregate_id'   => 0,
            'event_type'     => "payment.webhook.{$provider}",
            'payload'        => $payload,
            'status'         => 'pending',
            'created_at'     => now(),
        ]);

        return response()->json(['status' => 'ok']);
    }

    /**
     * POST /api/v1/webhooks/payment/monad
     *
     * Envio HyperSync Indexer webhook dispatcher.
     * Receives PaymentReceived event from SmileOnPaymentHub.sol smart contract.
     */
    public function monad(Request $request): JsonResponse
    {
        $request->validate([
            'event_name'    => 'required|string',
            'tx_hash'       => 'required|string',
            'block_number'  => 'required|integer',
            'chain_id'      => 'required|integer',
            'from_address'  => 'required|string',
            'amount'        => 'required|string',
            'order_ref'     => 'nullable|string',
        ]);

        // Verify Envio shared secret (simple header token for now)
        $secret = config('services.envio.webhook_secret');
        if ($secret && $request->header('X-Envio-Secret') !== $secret) {
            return response()->json(['status' => 'error', 'message' => 'Unauthorized.'], 401);
        }

        $txHash = $request->tx_hash;

        // Idempotent
        $existing = DB::table('payment_webhooks')
            ->where('provider', 'monad')
            ->where('event_id', $txHash)
            ->first();

        if ($existing) {
            return response()->json(['status' => 'ok', 'message' => 'Already processed.']);
        }

        DB::transaction(function () use ($request, $txHash) {
            DB::table('payment_webhooks')->insert([
                'provider'   => 'monad',
                'event_id'   => $txHash,
                'raw_payload'=> json_encode($request->all()),
                'status'     => 'pending',
                'received_at'=> now(),
            ]);

            OutboxEvent::create([
                'aggregate_type' => 'MonadPaymentEvent',
                'aggregate_id'   => 0,
                'event_type'     => 'payment.received.monad',
                'payload'        => $request->all(),
                'status'         => 'pending',
                'created_at'     => now(),
            ]);

            // Auto-fulfill order if order_ref matches a pending order
            if ($request->order_ref) {
                $order = Order::where('order_number', $request->order_ref)
                    ->where('status', 'pending')
                    ->first();

                if ($order) {
                    $order->update([
                        'status'   => 'paid',
                        'paid_at'  => now(),
                        'payment_details' => array_merge($order->payment_details ?? [], [
                            'tx_hash'      => $txHash,
                            'block_number' => $request->block_number,
                            'chain_id'     => $request->chain_id,
                        ]),
                    ]);

                    // Grant credits if applicable
                    $creditsToGrant = $order->payment_details['credits_to_grant'] ?? 0;
                    if ($creditsToGrant > 0) {
                        $credit = $order->user->photoCredit
                            ?? PhotoCredit::create(['user_id' => $order->user_id]);
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
                }
            }
        });

        return response()->json(['status' => 'ok', 'message' => 'Event Monad diterima dan dijadwalkan.']);
    }

    // ============================================================
    // PRIVATE HELPERS
    // ============================================================

    private function extractEventId(string $provider, array $payload): string
    {
        return match ($provider) {
            'midtrans' => $payload['transaction_id'] ?? $payload['order_id'] ?? uniqid(),
            'xendit'   => $payload['id'] ?? $payload['external_id'] ?? uniqid(),
            'monad'    => $payload['tx_hash'] ?? uniqid(),
            default    => uniqid(),
        };
    }

    private function verifySignature(string $provider, Request $request): bool
    {
        // In production, implement per-provider HMAC verification
        // For development, accept all
        if (app()->environment('local', 'testing')) {
            return true;
        }

        return match ($provider) {
            'midtrans' => $this->verifyMidtrans($request),
            'xendit'   => $this->verifyXendit($request),
            default    => true,
        };
    }

    private function verifyMidtrans(Request $request): bool
    {
        $serverKey   = config('services.midtrans.server_key');
        $payload     = $request->all();
        $signature   = hash('sha512', ($payload['order_id'] ?? '') . ($payload['status_code'] ?? '') . ($payload['gross_amount'] ?? '') . $serverKey);
        return hash_equals($signature, $payload['signature_key'] ?? '');
    }

    private function verifyXendit(Request $request): bool
    {
        $token = config('services.xendit.callback_token');
        return $request->header('X-CALLBACK-TOKEN') === $token;
    }
}
