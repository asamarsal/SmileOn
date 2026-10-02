<?php

namespace App\Http\Controllers\Api\V1\Orders;

use App\Http\Controllers\Controller;
use App\Models\Voucher;
use App\Models\PhotoCredit;
use App\Models\CreditTransaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * VoucherController — Covers Section 4.11 of plan-backend-laravel.md
 */
class VoucherController extends Controller
{
    /**
     * POST /api/v1/vouchers/validate
     *
     * Validate a voucher code and return its details.
     */
    public function validate(Request $request): JsonResponse
    {
        $request->validate(['code' => 'required|string']);

        $voucher = Voucher::where('code', strtoupper($request->code))->first();

        if (!$voucher) {
            return response()->json([
                'success'    => false,
                'message'    => 'Kode voucher tidak ditemukan.',
                'error_code' => 'VOUCHER_NOT_FOUND',
            ], 404);
        }

        if (!$voucher->isValid()) {
            return response()->json([
                'success'    => false,
                'message'    => 'Voucher sudah tidak berlaku atau habis kuotanya.',
                'error_code' => 'VOUCHER_INVALID',
            ], 422);
        }

        return response()->json([
            'success' => true,
            'data'    => [
                'code'               => $voucher->code,
                'name'               => $voucher->name,
                'description'        => $voucher->description,
                'type'               => $voucher->type,
                'value'              => $voucher->value,
                'discount_strip_pct' => $voucher->discount_strip_pct,
                'free_strip_copies'  => $voucher->free_strip_copies,
                'valid_until'        => $voucher->valid_until?->toIso8601String(),
                'remaining_quota'    => $voucher->max_uses ? ($voucher->max_uses - $voucher->used_count) : null,
            ],
        ]);
    }

    /**
     * POST /api/v1/vouchers/redeem
     *
     * Redeem a credit_bonus voucher — immediately grants credits.
     * Idempotency-Key required (handled by middleware).
     */
    public function redeem(Request $request): JsonResponse
    {
        $request->validate(['code' => 'required|string']);

        $result = DB::transaction(function () use ($request) {
            $voucher = Voucher::where('code', strtoupper($request->code))
                ->lockForUpdate()
                ->first();

            if (!$voucher || !$voucher->isValid()) {
                return ['error' => 'VOUCHER_INVALID', 'message' => 'Kode voucher tidak valid atau sudah tidak berlaku.'];
            }

            if ($voucher->type !== 'credit_bonus') {
                return ['error' => 'VOUCHER_WRONG_TYPE', 'message' => 'Voucher ini bukan tipe bonus kredit foto.'];
            }

            $user   = $request->user();
            $credit = $user->photoCredit ?? PhotoCredit::create(['user_id' => $user->id]);
            $before = $credit->balance;
            $added  = (int) $voucher->value;

            $credit->increment('balance', $added);
            $credit->increment('lifetime_earned', $added);

            CreditTransaction::create([
                'user_id'        => $user->id,
                'type'           => 'voucher_redeem',
                'amount'         => $added,
                'balance_before' => $before,
                'balance_after'  => $before + $added,
                'reference_type' => 'Voucher',
                'reference_id'   => $voucher->id,
                'note'           => "Redeem voucher: {$voucher->code}",
                'created_at'     => now(),
            ]);

            $voucher->increment('used_count');

            return ['credits_added' => $added, 'new_balance' => $before + $added, 'voucher' => $voucher->code];
        });

        if (isset($result['error'])) {
            return response()->json(['success' => false, 'message' => $result['message'], 'error_code' => $result['error']], 422);
        }

        return response()->json([
            'success' => true,
            'message' => "{$result['credits_added']} kredit foto berhasil ditambahkan.",
            'data'    => $result,
        ]);
    }

    /**
     * GET /api/v1/user/credits
     *
     * Current user credit balance.
     */
    public function credits(Request $request): JsonResponse
    {
        $credit = $request->user()->photoCredit ?? PhotoCredit::create(['user_id' => $request->user()->id]);

        return response()->json([
            'success' => true,
            'data'    => [
                'balance'          => $credit->balance,
                'reserved_balance' => $credit->reserved_balance,
                'lifetime_used'    => $credit->lifetime_used,
                'lifetime_earned'  => $credit->lifetime_earned ?? 0,
            ],
        ]);
    }

    /**
     * GET /api/v1/user/credits/ledger
     *
     * Full credit mutation history with before/after balance snapshots.
     */
    public function creditLedger(Request $request): JsonResponse
    {
        $transactions = CreditTransaction::where('user_id', $request->user()->id)
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 20);

        return response()->json(['success' => true, 'data' => $transactions]);
    }
}
