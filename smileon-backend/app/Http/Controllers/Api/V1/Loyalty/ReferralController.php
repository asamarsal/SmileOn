<?php

namespace App\Http\Controllers\Api\V1\Loyalty;

use App\Http\Controllers\Controller;
use App\Models\Referral;
use App\Models\User;
use App\Models\LoyaltyAccount;
use App\Models\LoyaltyTransaction;
use App\Models\PhotoCredit;
use App\Models\CreditTransaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * ReferralController — Covers Section 4.14 of plan-backend-laravel.md
 */
class ReferralController extends Controller
{
    /**
     * GET /api/v1/user/referral
     *
     * Return referral code, share link, referred friends count, pending rewards.
     */
    public function show(Request $request): JsonResponse
    {
        $user = $request->user();

        // Auto-generate referral code if not set
        if (!$user->referral_code) {
            $code = strtoupper(substr(md5($user->id . $user->email), 0, 8));
            $user->update(['referral_code' => $code]);
        }

        $referrals = Referral::where('referrer_id', $user->id)->get();
        $pending   = $referrals->where('status', 'pending')->count();
        $rewarded  = $referrals->where('status', 'rewarded')->count();

        return response()->json([
            'success' => true,
            'data'    => [
                'referral_code'     => $user->referral_code,
                'share_url'         => "smileon://ref?code={$user->referral_code}",
                'share_deeplink'    => "https://smileon.app/r/{$user->referral_code}",
                'total_referred'    => $referrals->count(),
                'pending_rewards'   => $pending,
                'rewarded_count'    => $rewarded,
            ],
        ]);
    }

    /**
     * POST /api/v1/user/referral/claim
     *
     * Claim pending referral rewards.
     * Idempotency-Key required (handled by middleware).
     */
    public function claim(Request $request): JsonResponse
    {
        $user = $request->user();

        $pendingReferrals = Referral::where('referrer_id', $user->id)
            ->where('status', 'pending')
            ->with('referred')
            ->lockForUpdate()
            ->get();

        if ($pendingReferrals->isEmpty()) {
            return response()->json([
                'success'    => false,
                'message'    => 'Tidak ada reward referral yang dapat diklaim.',
                'error_code' => 'NO_PENDING_REFERRALS',
            ], 422);
        }

        $creditsGranted = 0;
        $pointsGranted  = 0;

        DB::transaction(function () use ($user, $pendingReferrals, &$creditsGranted, &$pointsGranted) {
            foreach ($pendingReferrals as $referral) {
                // Grant 5 credits per successful referral
                $creditBonus = 5;
                $pointsBonus = 100;

                $credit = $user->photoCredit ?? PhotoCredit::create(['user_id' => $user->id]);
                $before = $credit->balance;
                $credit->increment('balance', $creditBonus);
                $credit->increment('lifetime_earned', $creditBonus);

                CreditTransaction::create([
                    'user_id'        => $user->id,
                    'type'           => 'referral_reward',
                    'amount'         => $creditBonus,
                    'balance_before' => $before,
                    'balance_after'  => $before + $creditBonus,
                    'reference_type' => 'Referral',
                    'reference_id'   => $referral->id,
                    'note'           => "Referral reward: {$referral->referred->name}",
                    'created_at'     => now(),
                ]);

                // Grant loyalty points
                $account = $user->loyaltyAccount ?? LoyaltyAccount::create(['user_id' => $user->id]);
                $pBefore = $account->points_balance;
                $account->increment('points_balance', $pointsBonus);
                $account->increment('lifetime_earned', $pointsBonus);

                LoyaltyTransaction::create([
                    'user_id'        => $user->id,
                    'type'           => 'referral_reward',
                    'points'         => $pointsBonus,
                    'balance_before' => $pBefore,
                    'balance_after'  => $pBefore + $pointsBonus,
                    'reference_type' => 'Referral',
                    'reference_id'   => $referral->id,
                    'description'    => "Referral reward: {$referral->referred->name}",
                    'created_at'     => now(),
                ]);

                $referral->update(['status' => 'rewarded', 'rewarded_at' => now()]);

                $creditsGranted += $creditBonus;
                $pointsGranted  += $pointsBonus;
            }
        });

        return response()->json([
            'success' => true,
            'message' => "Reward referral berhasil diklaim!",
            'data'    => [
                'claimed_referrals' => $pendingReferrals->count(),
                'credits_granted'   => $creditsGranted,
                'points_granted'    => $pointsGranted,
            ],
        ]);
    }
}
