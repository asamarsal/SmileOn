<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\UserSession;
use App\Models\PhotoCredit;
use App\Models\LoyaltyAccount;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

/**
 * AuthController — Handles Google OAuth, Monad Wallet, logout, and profile.
 *
 * Covers Section 4.1 of plan-backend-laravel.md
 */
class AuthController extends Controller
{
    /**
     * POST /api/v1/auth/google
     *
     * Login via Google ID Token (Flutter passes the token from Google Sign-In SDK).
     * Server verifies with Google tokeninfo endpoint, upserts user, issues Sanctum token.
     */
    public function loginGoogle(Request $request): JsonResponse
    {
        $request->validate([
            'id_token'    => 'required|string',
            'device_name' => 'nullable|string|max:100',
            'device_type' => 'nullable|string|max:30',
            'platform'    => 'nullable|string|max:30',
            'app_version' => 'nullable|string|max:30',
        ]);

        // Verify Google ID Token
        $googleResponse = Http::get('https://oauth2.googleapis.com/tokeninfo', [
            'id_token' => $request->id_token,
        ]);

        if ($googleResponse->failed()) {
            return response()->json([
                'success'    => false,
                'message'    => 'Google token tidak valid atau sudah kedaluwarsa.',
                'error_code' => 'GOOGLE_TOKEN_INVALID',
            ], 401);
        }

        $googleData = $googleResponse->json();

        // Verify aud (audience) matches our Google Client ID
        $expectedClientId = config('services.google.client_id');
        if ($expectedClientId && $googleData['aud'] !== $expectedClientId) {
            return response()->json([
                'success'    => false,
                'message'    => 'Google token audience tidak cocok.',
                'error_code' => 'GOOGLE_TOKEN_AUDIENCE_MISMATCH',
            ], 401);
        }

        $googleId    = $googleData['sub'];
        $email       = $googleData['email'] ?? null;
        $name        = $googleData['name'] ?? $googleData['email'] ?? 'SmileOn User';
        $avatarUrl   = $googleData['picture'] ?? null;

        // Upsert user (find by email or create)
        $user = DB::transaction(function () use ($email, $name, $avatarUrl) {
            $user = User::where('email', $email)->first();

            if (!$user) {
                $user = User::create([
                    'name'        => $name,
                    'email'       => $email,
                    'avatar_url'  => $avatarUrl,
                    'auth_method' => 'google',
                    'role'        => 'user',
                    'email_verified_at' => now(),
                ]);

                // Initialize credit & loyalty accounts
                PhotoCredit::create(['user_id' => $user->id]);
                LoyaltyAccount::create(['user_id' => $user->id]);
            } else {
                $user->update([
                    'avatar_url'  => $avatarUrl ?? $user->avatar_url,
                    'last_login_at' => now(),
                ]);
            }

            return $user;
        });

        if (!$user->is_active) {
            return response()->json([
                'success'    => false,
                'message'    => 'Akun Anda telah dinonaktifkan. Hubungi support.',
                'error_code' => 'ACCOUNT_SUSPENDED',
            ], 403);
        }

        // Issue Sanctum token
        $tokenName = $request->device_name ?? 'flutter-app';
        $token     = $user->createToken($tokenName);

        // Track device session
        $this->trackDeviceSession($user, $request, $token->plainTextToken);

        $user->load('photoCredit', 'loyaltyAccount');

        return response()->json([
            'success' => true,
            'message' => 'Login Google berhasil.',
            'data'    => [
                'token'      => $token->plainTextToken,
                'token_type' => 'Bearer',
                'user'       => $this->userResource($user),
            ],
        ]);
    }

    /**
     * POST /api/v1/auth/wallet
     *
     * Login via Monad/EVM wallet signature.
     * Client signs a challenge message with their private key.
     */
    public function loginWallet(Request $request): JsonResponse
    {
        $request->validate([
            'wallet_address' => 'required|string|max:100',
            'signature'      => 'required|string',
            'message'        => 'required|string',
            'wallet_type'    => 'nullable|string|max:30',
            'network'        => 'nullable|string|max:30',
            'device_name'    => 'nullable|string|max:100',
            'device_type'    => 'nullable|string|max:30',
        ]);

        $walletAddress = strtolower($request->wallet_address);

        // In production, verify EIP-712 signature here.
        // For now, we trust the address (add ecrecover in prod).
        // TODO: Add proper ECDSA signature verification with ecrecover

        $user = DB::transaction(function () use ($request, $walletAddress) {
            $user = User::where('wallet_address', $walletAddress)->first();

            if (!$user) {
                // Create new wallet user
                $user = User::create([
                    'name'           => 'Wallet ' . substr($walletAddress, 0, 8) . '...',
                    'wallet_address' => $walletAddress,
                    'wallet_type'    => $request->wallet_type ?? 'metamask',
                    'network'        => $request->network ?? 'monad',
                    'auth_method'    => 'wallet',
                    'role'           => 'user',
                ]);

                PhotoCredit::create(['user_id' => $user->id]);
                LoyaltyAccount::create(['user_id' => $user->id]);
            } else {
                $user->update(['last_login_at' => now()]);
            }

            return $user;
        });

        if (!$user->is_active) {
            return response()->json([
                'success'    => false,
                'message'    => 'Akun Anda telah dinonaktifkan.',
                'error_code' => 'ACCOUNT_SUSPENDED',
            ], 403);
        }

        $token = $user->createToken($request->device_name ?? 'wallet-app');
        $this->trackDeviceSession($user, $request, $token->plainTextToken);

        $user->load('photoCredit', 'loyaltyAccount');

        return response()->json([
            'success' => true,
            'message' => 'Login wallet berhasil.',
            'data'    => [
                'token'      => $token->plainTextToken,
                'token_type' => 'Bearer',
                'user'       => $this->userResource($user),
            ],
        ]);
    }

    /**
     * POST /api/v1/auth/logout
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logout berhasil.',
        ]);
    }

    /**
     * GET /api/v1/auth/me
     */
    public function me(Request $request): JsonResponse
    {
        $user = $request->user()->load('photoCredit', 'loyaltyAccount');

        return response()->json([
            'success' => true,
            'data'    => $this->userResource($user),
        ]);
    }

    /**
     * PATCH /api/v1/auth/me
     */
    public function updateProfile(Request $request): JsonResponse
    {
        $request->validate([
            'name'         => 'sometimes|string|max:100',
            'username'     => 'sometimes|nullable|string|max:50|unique:users,username,' . $request->user()->id,
            'phone_number' => 'sometimes|nullable|string|max:20',
            'avatar_url'   => 'sometimes|nullable|url',
            'locale'       => 'sometimes|in:id,en',
        ]);

        $request->user()->update($request->only(['name', 'username', 'phone_number', 'avatar_url', 'locale']));

        return response()->json([
            'success' => true,
            'message' => 'Profil berhasil diperbarui.',
            'data'    => $this->userResource($request->user()->fresh('photoCredit', 'loyaltyAccount')),
        ]);
    }

    /**
     * GET /api/v1/auth/sessions — List active device sessions
     */
    public function sessions(Request $request): JsonResponse
    {
        $sessions = $request->user()
            ->userSessions()
            ->orderByDesc('last_seen_at')
            ->get()
            ->map(fn ($s) => [
                'id'          => $s->id,
                'device_name' => $s->device_name,
                'device_type' => $s->device_type,
                'platform'    => $s->platform,
                'ip_address'  => $s->ip_address,
                'last_seen_at'=> $s->last_seen_at?->toIso8601String(),
                'created_at'  => $s->created_at?->toIso8601String(),
            ]);

        return response()->json([
            'success' => true,
            'data'    => $sessions,
        ]);
    }

    /**
     * DELETE /api/v1/auth/sessions/{id} — Revoke specific device session
     */
    public function revokeSession(Request $request, int $id): JsonResponse
    {
        $session = $request->user()->userSessions()->findOrFail($id);
        $session->delete();

        // Also revoke corresponding Sanctum token if we tracked it
        // (simplified: in production match token_hash)

        return response()->json([
            'success' => true,
            'message' => 'Sesi perangkat berhasil dicabut.',
        ]);
    }

    /**
     * DELETE /api/v1/auth/sessions/other — Revoke all other device sessions
     */
    public function revokeOtherSessions(Request $request): JsonResponse
    {
        // Revoke all tokens except current
        $currentToken = $request->user()->currentAccessToken();
        $request->user()->tokens()->where('id', '!=', $currentToken->id)->delete();

        // Delete all other device sessions
        $request->user()->userSessions()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Semua sesi perangkat lain berhasil dicabut.',
        ]);
    }

    // ============================================================
    // PRIVATE HELPERS
    // ============================================================

    /**
     * Track device session after login.
     */
    private function trackDeviceSession(User $user, Request $request, string $plainToken): void
    {
        try {
            UserSession::updateOrCreate(
                [
                    'user_id'     => $user->id,
                    'token_hash'  => hash('sha256', $plainToken),
                ],
                [
                    'device_name' => $request->device_name ?? $request->userAgent(),
                    'device_type' => $request->device_type ?? 'unknown',
                    'platform'    => $request->platform ?? 'unknown',
                    'app_version' => $request->app_version,
                    'ip_address'  => $request->ip(),
                    'user_agent'  => $request->userAgent(),
                    'is_mobile'   => (bool) $request->boolean('is_mobile', false),
                    'last_seen_at'=> now(),
                ]
            );
        } catch (\Throwable) {
            // Non-blocking
        }
    }

    /**
     * Build user resource array for API responses.
     */
    private function userResource(User $user): array
    {
        return [
            'uuid'           => $user->uuid,
            'name'           => $user->name,
            'username'       => $user->username,
            'email'          => $user->email,
            'avatar_url'     => $user->avatar_url,
            'phone_number'   => $user->phone_number,
            'role'           => $user->role,
            'auth_method'    => $user->auth_method,
            'wallet_address' => $user->wallet_address,
            'wallet_type'    => $user->wallet_type,
            'network'        => $user->network,
            'locale'         => $user->locale,
            'is_active'      => $user->is_active,
            'referral_code'  => $user->referral_code,
            'credits'        => [
                'balance'          => $user->availableCredits(),
                'reserved_balance' => $user->reservedCredits(),
            ],
            'loyalty'        => $user->loyaltyAccount ? [
                'tier'           => $user->loyaltyAccount->tier,
                'points_balance' => $user->loyaltyAccount->points_balance,
            ] : null,
            'last_login_at'  => $user->last_login_at?->toIso8601String(),
            'created_at'     => $user->created_at?->toIso8601String(),
        ];
    }
}
