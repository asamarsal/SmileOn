<?php

namespace App\Http\Controllers\Api\V1\Booths;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\EventBooth;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

/**
 * BoothController — Hardware authentication and telemetry.
 * Covers section 4.5 of the plan.
 * Uses dual-token rotation: access_token (60min) + refresh_token (30 days).
 */
class BoothController extends Controller
{
    /**
     * POST /api/v1/booths/pair
     *
     * Pair a physical booth device to an event using a one-time pairing code.
     */
    public function pair(Request $request): JsonResponse
    {
        $request->validate([
            'pairing_code'       => 'required|string',
            'device_fingerprint' => 'required|string|max:64',
            'hardware_info'      => 'nullable|array',
            'booth_name'         => 'nullable|string|max:100',
        ]);

        $booth = EventBooth::where('pairing_code', $request->pairing_code)
            ->where('status', 'paired')
            ->first();

        if (!$booth) {
            return response()->json([
                'success'    => false,
                'message'    => 'Kode pairing tidak valid atau sudah digunakan.',
                'error_code' => 'PAIRING_CODE_INVALID',
            ], 401);
        }

        // Issue dual tokens
        $accessToken  = Str::random(64);
        $refreshToken = Str::random(64);

        $booth->update([
            'device_fingerprint'       => hash('sha256', $request->device_fingerprint),
            'access_token_hash'        => hash('sha256', $accessToken),
            'refresh_token_hash'       => hash('sha256', $refreshToken),
            'access_token_expires_at'  => now()->addHours(1),
            'refresh_token_expires_at' => now()->addDays(30),
            'hardware_info'            => $request->hardware_info,
            'booth_name'               => $request->booth_name ?? $booth->booth_name,
            'status'                   => 'active',
            'pairing_code'             => null, // Invalidate after use
        ]);

        return response()->json([
            'success'       => true,
            'message'       => 'Booth berhasil dipasang.',
            'data'          => [
                'booth_uuid'    => $booth->uuid,
                'access_token'  => $accessToken,
                'refresh_token' => $refreshToken,
                'expires_in'    => 3600, // seconds
            ],
        ]);
    }

    /**
     * POST /api/v1/booths/token/refresh
     *
     * Rotate access token using refresh token (no user auth required).
     */
    public function refreshToken(Request $request): JsonResponse
    {
        $request->validate([
            'booth_uuid'    => 'required|string',
            'refresh_token' => 'required|string',
        ]);

        $booth = EventBooth::where('uuid', $request->booth_uuid)
            ->where('refresh_token_hash', hash('sha256', $request->refresh_token))
            ->where('status', 'active')
            ->first();

        if (!$booth || $booth->refresh_token_expires_at < now()) {
            return response()->json([
                'success'    => false,
                'message'    => 'Refresh token tidak valid atau sudah kedaluwarsa.',
                'error_code' => 'REFRESH_TOKEN_INVALID',
            ], 401);
        }

        $newAccessToken  = Str::random(64);
        $newRefreshToken = Str::random(64);

        $booth->update([
            'access_token_hash'        => hash('sha256', $newAccessToken),
            'refresh_token_hash'       => hash('sha256', $newRefreshToken),
            'access_token_expires_at'  => now()->addHours(1),
            'refresh_token_expires_at' => now()->addDays(30),
        ]);

        return response()->json([
            'success' => true,
            'data'    => [
                'access_token'  => $newAccessToken,
                'refresh_token' => $newRefreshToken,
                'expires_in'    => 3600,
            ],
        ]);
    }

    /**
     * POST /api/v1/booths/heartbeat
     *
     * Booth sends telemetry snapshot periodically.
     */
    public function heartbeat(Request $request): JsonResponse
    {
        $request->validate([
            'booth_uuid'       => 'required|string',
            'printer_status'   => 'nullable|string|max:20',
            'paper_remaining'  => 'nullable|integer',
            'camera_status'    => 'nullable|string|max:20',
            'disk_free_pct'    => 'nullable|integer|max:100',
            'latency_ms'       => 'nullable|integer',
        ]);

        $booth = EventBooth::where('uuid', $request->booth_uuid)->firstOrFail();
        $booth->update(array_merge(
            $request->only('printer_status', 'paper_remaining', 'camera_status', 'disk_free_pct', 'latency_ms'),
            ['last_heartbeat_at' => now()]
        ));

        return response()->json(['success' => true, 'message' => 'Heartbeat diterima.', 'server_time' => now()->toIso8601String()]);
    }

    /**
     * GET /api/v1/booths/health
     *
     * Return booth telemetry snapshot.
     */
    public function health(Request $request): JsonResponse
    {
        $request->validate(['booth_uuid' => 'required|string']);
        $booth = EventBooth::where('uuid', $request->booth_uuid)->firstOrFail();

        return response()->json(['success' => true, 'data' => [
            'printer_status'   => $booth->printer_status,
            'paper_remaining'  => $booth->paper_remaining,
            'camera_status'    => $booth->camera_status,
            'disk_free_pct'    => $booth->disk_free_pct,
            'latency_ms'       => $booth->latency_ms,
            'last_heartbeat_at'=> $booth->last_heartbeat_at?->toIso8601String(),
        ]]);
    }

    /**
     * POST /api/v1/booths/revoke
     *
     * Organizer revokes booth access.
     */
    public function revoke(Request $request): JsonResponse
    {
        $request->validate(['booth_uuid' => 'required|string']);
        $booth = EventBooth::where('uuid', $request->booth_uuid)->firstOrFail();
        $booth->update(['status' => 'revoked', 'revoked_at' => now(), 'access_token_hash' => null, 'refresh_token_hash' => null]);
        return response()->json(['success' => true, 'message' => 'Booth akses dicabut.']);
    }

    /**
     * GET /api/v1/booths/config
     *
     * Return booth configuration (frames, event settings).
     */
    public function config(Request $request): JsonResponse
    {
        $request->validate(['booth_uuid' => 'required|string']);
        $booth = EventBooth::with('event.frames.frame')->where('uuid', $request->booth_uuid)->firstOrFail();
        return response()->json(['success' => true, 'data' => [
            'booth'  => $booth->only('uuid', 'booth_name', 'status'),
            'event'  => $booth->event->only('uuid', 'name', 'force_remove_watermark', 'settings', 'total_credits', 'used_credits'),
            'frames' => $booth->event->frames,
        ]]);
    }
}
