<?php

namespace App\Http\Controllers\Api\V1\Booths;

use App\Http\Controllers\Controller;
use App\Models\PersonalQrToken;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

/**
 * PersonalQrController — Instant booth login without password.
 * Covers Section 4.6 of plan-backend-laravel.md
 *
 * Flow:
 *   1. Booth screen calls POST /personal/qr-auth/init → gets QR token (TTL 2 min)
 *   2. User scans QR with Flutter app → calls POST /personal/qr-auth/confirm
 *   3. Booth polls GET /personal/qr-auth/status/{token} until status = 'confirmed'
 *   4. On confirmed, booth uses the user's Sanctum token to start the session
 */
class PersonalQrController extends Controller
{
    /**
     * POST /api/v1/personal/qr-auth/init
     *
     * Booth (unauthenticated) generates a short-lived QR token for the kiosk screen.
     * No user auth needed.
     */
    public function init(Request $request): JsonResponse
    {
        $request->validate([
            'booth_uuid' => 'nullable|string',
        ]);

        // Cleanup expired tokens
        PersonalQrToken::where('expires_at', '<', now())->delete();

        $token = Str::random(48);

        PersonalQrToken::create([
            'token'      => $token,
            'status'     => 'pending',
            'ip_address' => $request->ip(),
            'expires_at' => now()->addMinutes(2),
        ]);

        return response()->json([
            'success' => true,
            'data'    => [
                'token'          => $token,
                'qr_payload'     => "smileon://qr-login?token={$token}",
                'expires_at'     => now()->addMinutes(2)->toIso8601String(),
                'ttl_seconds'    => 120,
            ],
        ]);
    }

    /**
     * POST /api/v1/personal/qr-auth/confirm
     *
     * Authenticated user (via Flutter app) confirms the QR scan.
     * This "pairs" the user to the token so the booth can continue.
     */
    public function confirm(Request $request): JsonResponse
    {
        $request->validate(['token' => 'required|string']);

        $qrToken = PersonalQrToken::where('token', $request->token)
            ->where('status', 'pending')
            ->first();

        if (!$qrToken || $qrToken->isExpired()) {
            return response()->json([
                'success'    => false,
                'message'    => 'QR Token tidak valid atau sudah kedaluwarsa.',
                'error_code' => 'QR_TOKEN_INVALID',
            ], 401);
        }

        $user = $request->user();

        // Issue a short-lived Sanctum token for the booth
        $boothToken = $user->createToken('booth-qr-login', ['*'], now()->addHours(2));

        $qrToken->update([
            'user_id'  => $user->id,
            'status'   => 'confirmed',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Login booth berhasil dikonfirmasi.',
            'data'    => [
                'user_name'    => $user->name,
                'user_avatar'  => $user->avatar_url,
                'booth_token'  => $boothToken->plainTextToken,
                'expires_in'   => 7200,
            ],
        ]);
    }

    /**
     * GET /api/v1/personal/qr-auth/status/{token}
     *
     * Booth polls this endpoint until status changes to 'confirmed'.
     * Returns user basic info + Sanctum token on success.
     * No auth required (booth is not authenticated as a user).
     */
    public function status(string $token): JsonResponse
    {
        $qrToken = PersonalQrToken::where('token', $token)->first();

        if (!$qrToken) {
            return response()->json([
                'success'    => false,
                'message'    => 'Token tidak ditemukan.',
                'error_code' => 'QR_TOKEN_NOT_FOUND',
            ], 404);
        }

        if ($qrToken->isExpired()) {
            return response()->json([
                'success' => true,
                'data'    => ['status' => 'expired'],
            ]);
        }

        if ($qrToken->status === 'confirmed') {
            $user = User::find($qrToken->user_id);

            return response()->json([
                'success' => true,
                'data'    => [
                    'status'      => 'confirmed',
                    'user_name'   => $user?->name,
                    'user_avatar' => $user?->avatar_url,
                    'user_uuid'   => $user?->uuid,
                ],
            ]);
        }

        return response()->json([
            'success' => true,
            'data'    => [
                'status'     => 'pending',
                'expires_at' => $qrToken->expires_at->toIso8601String(),
            ],
        ]);
    }
}
