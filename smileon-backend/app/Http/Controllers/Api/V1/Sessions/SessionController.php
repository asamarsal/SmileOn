<?php

namespace App\Http\Controllers\Api\V1\Sessions;

use App\Http\Controllers\Controller;
use App\Models\PhotoSession;
use App\Models\PhotoCredit;
use App\Models\CreditTransaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * SessionController — Photo session state machine management.
 * Covers section 4.7 of the plan.
 */
class SessionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $sessions = $request->user()->sessions()
            ->with('frame:id,uuid,title,thumbnail_url', 'strip:id,uuid,clean_url,status')
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 10);
        return response()->json(['success' => true, 'data' => $sessions]);
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'frame_uuid'   => 'nullable|string',
            'orientation'  => 'nullable|in:portrait,landscape,square',
            'mode'         => 'nullable|in:personal,event',
            'event_uuid'   => 'nullable|string',
            'credits_required' => 'nullable|integer|min:1',
            'photos_count' => 'nullable|integer|min:1|max:8',
        ]);

        $user = $request->user();
        $creditsRequired = $request->credits_required ?? 1;

        // Check available credits
        $credit = $user->photoCredit;
        if (!$credit || $credit->balance < $creditsRequired) {
            return response()->json([
                'success'    => false,
                'message'    => 'Kredit foto tidak mencukupi.',
                'error_code' => 'INSUFFICIENT_CREDITS',
                'data'       => ['available' => $credit?->balance ?? 0, 'required' => $creditsRequired],
            ], 402);
        }

        $session = DB::transaction(function () use ($user, $request, $creditsRequired, $credit) {
            // Reserve credits
            $before = $credit->balance;
            $credit->decrement('balance', $creditsRequired);
            $credit->increment('reserved_balance', $creditsRequired);

            CreditTransaction::create([
                'user_id'        => $user->id,
                'type'           => 'session_reserve',
                'amount'         => -$creditsRequired,
                'balance_before' => $before,
                'balance_after'  => $before - $creditsRequired,
                'created_at'     => now(),
            ]);

            // Resolve frame
            $frameId = null;
            if ($request->frame_uuid) {
                $frame = \App\Models\Frame::where('uuid', $request->frame_uuid)->first();
                $frameId = $frame?->id;
            }

            return PhotoSession::create([
                'user_id'          => $user->id,
                'frame_id'         => $frameId,
                'mode'             => $request->mode ?? 'personal',
                'orientation'      => $request->orientation ?? 'portrait',
                'credits_required' => $creditsRequired,
                'photos_count'     => $request->photos_count ?? 4,
                'status'           => 'waiting',
                'expires_at'       => now()->addMinutes(20),
            ]);
        });

        return response()->json(['success' => true, 'data' => $session->load('frame')], 201);
    }

    public function show(string $uuid): JsonResponse
    {
        $session = PhotoSession::with('frame', 'photos', 'strip')->where('uuid', $uuid)->firstOrFail();
        return response()->json(['success' => true, 'data' => $session]);
    }

    public function lookup(string $sessionCode): JsonResponse
    {
        $session = PhotoSession::where('session_code', $sessionCode)->firstOrFail();
        return response()->json(['success' => true, 'data' => $session]);
    }

    public function update(Request $request, string $uuid): JsonResponse
    {
        $session = $request->user()->sessions()->where('uuid', $uuid)->firstOrFail();
        $request->validate(['participants' => 'nullable|array', 'location' => 'nullable|string|max:100']);
        $session->update($request->only('participants', 'location'));
        return response()->json(['success' => true, 'data' => $session]);
    }

    public function startPersonal(Request $request, string $uuid): JsonResponse
    {
        return $this->transition($request, $uuid, 'active');
    }

    public function startEvent(Request $request, string $uuid): JsonResponse
    {
        return $this->transition($request, $uuid, 'active');
    }

    public function complete(Request $request, string $uuid): JsonResponse
    {
        return $this->transition($request, $uuid, 'completing', function (PhotoSession $session) {
            $session->update(['completed_at' => now()]);

            // Release reserved credits, mark as used
            DB::transaction(function () use ($session) {
                $credit = $session->user->photoCredit;
                if ($credit) {
                    $credit->decrement('reserved_balance', $session->credits_required);
                    $credit->increment('lifetime_used', $session->credits_required);
                    CreditTransaction::create([
                        'user_id'        => $session->user_id,
                        'type'           => 'session_use',
                        'amount'         => -$session->credits_required,
                        'balance_before' => $credit->balance + $session->credits_required,
                        'balance_after'  => $credit->balance,
                        'reference_type' => 'PhotoSession',
                        'reference_id'   => $session->id,
                        'created_at'     => now(),
                    ]);
                }
            });
        });
    }

    public function cancel(Request $request, string $uuid): JsonResponse
    {
        return $this->transition($request, $uuid, 'cancelled', function (PhotoSession $session) {
            $session->update(['cancelled_at' => now()]);

            // Refund reserved credits
            DB::transaction(function () use ($session) {
                $credit = $session->user->photoCredit;
                if ($credit) {
                    $before = $credit->balance;
                    $credit->increment('balance', $session->credits_required);
                    $credit->decrement('reserved_balance', $session->credits_required);
                    CreditTransaction::create([
                        'user_id'        => $session->user_id,
                        'type'           => 'session_release',
                        'amount'         => $session->credits_required,
                        'balance_before' => $before,
                        'balance_after'  => $before + $session->credits_required,
                        'reference_type' => 'PhotoSession',
                        'reference_id'   => $session->id,
                        'created_at'     => now(),
                    ]);
                }
            });
        });
    }

    // ============================================================
    // PRIVATE
    // ============================================================

    private function transition(Request $request, string $uuid, string $newStatus, ?\Closure $afterTransition = null): JsonResponse
    {
        $session = $request->user()->sessions()->where('uuid', $uuid)->firstOrFail();

        if (!$session->canTransitionTo($newStatus)) {
            return response()->json([
                'success'    => false,
                'message'    => "Tidak dapat mengubah status sesi dari '{$session->status}' ke '{$newStatus}'.",
                'error_code' => 'INVALID_STATUS_TRANSITION',
                'data'       => ['current_status' => $session->status, 'requested_status' => $newStatus],
            ], 409);
        }

        $session->update(['status' => $newStatus]);

        if ($afterTransition) {
            $afterTransition($session->fresh());
        }

        return response()->json(['success' => true, 'data' => $session->fresh('photos', 'strip')]);
    }
}
