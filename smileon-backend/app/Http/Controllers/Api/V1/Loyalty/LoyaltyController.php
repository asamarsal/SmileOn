<?php

namespace App\Http\Controllers\Api\V1\Loyalty;

use App\Http\Controllers\Controller;
use App\Models\LoyaltyAccount;
use App\Models\LoyaltyTransaction;
use App\Models\LoyaltyReward;
use App\Models\PhotoCredit;
use App\Models\CreditTransaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * LoyaltyController — SmilePoints loyalty & gamification.
 * Covers Section 4.12 of plan-backend-laravel.md
 */
class LoyaltyController extends Controller
{
    /**
     * GET /api/v1/loyalty/points
     *
     * Current SmilePoints balance, lifetime stats, and tier.
     */
    public function points(Request $request): JsonResponse
    {
        $account = $request->user()->loyaltyAccount
            ?? LoyaltyAccount::create(['user_id' => $request->user()->id]);

        $tierThresholds = [
            'Bronze'   => 0,
            'Silver'   => 1000,
            'Gold'     => 5000,
            'Platinum' => 15000,
        ];

        $lifetime = $account->lifetime_earned;
        $tier     = 'Bronze';
        foreach ($tierThresholds as $t => $threshold) {
            if ($lifetime >= $threshold) {
                $tier = $t;
            }
        }

        // Sync tier if changed
        if ($account->tier !== $tier) {
            $account->update(['tier' => $tier]);
        }

        // Calculate next tier
        $tiers     = array_keys($tierThresholds);
        $tierIndex = array_search($tier, $tiers);
        $nextTier  = $tiers[$tierIndex + 1] ?? null;
        $nextThreshold = $nextTier ? $tierThresholds[$nextTier] : null;

        return response()->json([
            'success' => true,
            'data'    => [
                'points_balance'     => $account->points_balance,
                'lifetime_earned'    => $account->lifetime_earned,
                'lifetime_redeemed'  => $account->lifetime_redeemed,
                'tier'               => $tier,
                'next_tier'          => $nextTier,
                'points_to_next_tier'=> $nextThreshold ? max(0, $nextThreshold - $lifetime) : 0,
                'streak_days'        => $account->streak_days ?? 0,
                'last_check_in_date' => $account->last_check_in_date?->toDateString(),
            ],
        ]);
    }

    /**
     * GET /api/v1/loyalty/history
     *
     * Paginated point mutation history.
     */
    public function history(Request $request): JsonResponse
    {
        $transactions = LoyaltyTransaction::where('user_id', $request->user()->id)
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 20);

        return response()->json(['success' => true, 'data' => $transactions]);
    }

    /**
     * GET /api/v1/loyalty/rewards
     *
     * Active reward catalog for redemption.
     */
    public function rewards(Request $request): JsonResponse
    {
        $rewards = LoyaltyReward::where('is_active', true)
            ->where(fn($q) => $q->whereNull('stock')->orWhere('stock', '>', 0))
            ->orderBy('points_required')
            ->get();

        return response()->json(['success' => true, 'data' => $rewards]);
    }

    /**
     * POST /api/v1/loyalty/rewards/{id}/redeem
     *
     * Redeem SmilePoints for a reward (credits, voucher, merch discount).
     * Idempotency-Key required (handled by middleware).
     */
    public function redeem(Request $request, int $id): JsonResponse
    {
        $user   = $request->user();
        $reward = LoyaltyReward::where('is_active', true)->findOrFail($id);

        $result = DB::transaction(function () use ($user, $reward) {
            $account = LoyaltyAccount::where('user_id', $user->id)->lockForUpdate()->first()
                ?? LoyaltyAccount::create(['user_id' => $user->id]);

            if ($account->points_balance < $reward->points_required) {
                return [
                    'error'     => 'INSUFFICIENT_POINTS',
                    'message'   => "Poin tidak cukup. Dibutuhkan {$reward->points_required}, Anda memiliki {$account->points_balance}.",
                ];
            }

            if ($reward->stock !== null && $reward->stock <= 0) {
                return ['error' => 'REWARD_OUT_OF_STOCK', 'message' => 'Reward sudah habis.'];
            }

            $before = $account->points_balance;
            $account->decrement('points_balance', $reward->points_required);
            $account->increment('lifetime_redeemed', $reward->points_required);

            if ($reward->stock !== null) {
                $reward->decrement('stock');
            }

            LoyaltyTransaction::create([
                'user_id'        => $user->id,
                'type'           => 'redeem',
                'points'         => -$reward->points_required,
                'balance_before' => $before,
                'balance_after'  => $before - $reward->points_required,
                'reference_type' => 'LoyaltyReward',
                'reference_id'   => $reward->id,
                'description'    => "Redeem: {$reward->name}",
                'created_at'     => now(),
            ]);

            // Grant reward
            $grantResult = [];
            if ($reward->type === 'credit') {
                $credit = $user->photoCredit ?? PhotoCredit::create(['user_id' => $user->id]);
                $creditBefore = $credit->balance;
                $creditAmount = (int) $reward->value;
                $credit->increment('balance', $creditAmount);
                $credit->increment('lifetime_earned', $creditAmount);

                CreditTransaction::create([
                    'user_id'        => $user->id,
                    'type'           => 'loyalty_redeem',
                    'amount'         => $creditAmount,
                    'balance_before' => $creditBefore,
                    'balance_after'  => $creditBefore + $creditAmount,
                    'reference_type' => 'LoyaltyReward',
                    'reference_id'   => $reward->id,
                    'created_at'     => now(),
                ]);
                $grantResult = ['credits_granted' => $creditAmount];
            }

            return array_merge(['points_used' => $reward->points_required, 'reward_name' => $reward->name], $grantResult);
        });

        if (isset($result['error'])) {
            return response()->json(['success' => false, 'message' => $result['message'], 'error_code' => $result['error']], 422);
        }

        return response()->json(['success' => true, 'message' => "Reward berhasil diklaim!", 'data' => $result]);
    }

    /**
     * POST /api/v1/loyalty/check-in
     *
     * Daily check-in streak gamification.
     */
    public function checkIn(Request $request): JsonResponse
    {
        $user    = $request->user();
        $today   = now()->toDateString();

        $account = $user->loyaltyAccount ?? LoyaltyAccount::create(['user_id' => $user->id]);

        // Already checked in today?
        if ($account->last_check_in_date && $account->last_check_in_date->toDateString() === $today) {
            return response()->json([
                'success'    => false,
                'message'    => 'Anda sudah melakukan check-in hari ini.',
                'error_code' => 'ALREADY_CHECKED_IN',
                'data'       => ['next_check_in' => now()->addDay()->startOfDay()->toIso8601String()],
            ], 409);
        }

        DB::transaction(function () use ($account, $today, $user) {
            $yesterday = now()->subDay()->toDateString();
            $isStreak  = $account->last_check_in_date && $account->last_check_in_date->toDateString() === $yesterday;

            $streakDays = $isStreak ? ($account->streak_days + 1) : 1;
            // Bonus: more points for longer streaks
            $pointsEarned = match (true) {
                $streakDays >= 30 => 50,
                $streakDays >= 14 => 30,
                $streakDays >= 7  => 20,
                default           => 10,
            };

            $before = $account->points_balance;
            $account->update([
                'points_balance'     => $before + $pointsEarned,
                'lifetime_earned'    => $account->lifetime_earned + $pointsEarned,
                'streak_days'        => $streakDays,
                'last_check_in_date' => $today,
            ]);

            LoyaltyTransaction::create([
                'user_id'        => $user->id,
                'type'           => 'check_in',
                'points'         => $pointsEarned,
                'balance_before' => $before,
                'balance_after'  => $before + $pointsEarned,
                'description'    => "Daily check-in (streak: {$streakDays} hari)",
                'created_at'     => now(),
            ]);
        });

        $account->refresh();

        return response()->json([
            'success' => true,
            'message' => 'Check-in berhasil! Poin SmilePoints ditambahkan.',
            'data'    => [
                'points_balance' => $account->points_balance,
                'streak_days'    => $account->streak_days,
            ],
        ]);
    }
}
