<?php

namespace App\Http\Controllers\Api\V1\Photos;

use App\Http\Controllers\Controller;
use App\Models\Photo;
use App\Models\PhotoSession;
use App\Models\PhotoStrip;
use App\Models\StorageSync;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * PhotoStripController — Covers Section 4.9 of plan-backend-laravel.md
 */
class PhotoStripController extends Controller
{
    /**
     * POST /api/v1/sessions/{uuid}/strip
     *
     * Trigger strip generation. Records metadata and dispatches background job.
     * In production this kicks off ProcessPhotostripJob (Intervention Image).
     */
    public function generate(Request $request, string $uuid): JsonResponse
    {
        $session = PhotoSession::where('uuid', $uuid)
            ->where('user_id', $request->user()->id)
            ->whereIn('status', ['completing', 'completed'])
            ->firstOrFail();

        // Check if a strip already exists
        $existing = PhotoStrip::where('session_id', $session->id)
            ->where('status', '!=', 'failed')
            ->first();

        if ($existing && $existing->status === 'ready') {
            return response()->json([
                'success' => true,
                'message' => 'Photostrip sudah tersedia.',
                'data'    => $existing,
            ]);
        }

        $strip = DB::transaction(function () use ($session, $request) {
            return PhotoStrip::create([
                'session_id'   => $session->id,
                'user_id'      => $session->user_id,
                'aspect_ratio' => $session->orientation === 'portrait' ? '2:6' : '4:3',
                'print_size_inch' => $session->orientation === 'portrait' ? '2x6' : '4x6',
                'show_watermark' => true,
                'status'       => 'processing',
            ]);
        });

        // TODO: Dispatch ProcessPhotostripJob::dispatch($strip)

        return response()->json([
            'success' => true,
            'message' => 'Photostrip sedang diproses di background.',
            'data'    => $strip,
        ], 202);
    }

    /**
     * GET /api/v1/strips/{uuid}
     */
    public function show(Request $request, string $uuid): JsonResponse
    {
        $strip = PhotoStrip::where('uuid', $uuid)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        return response()->json([
            'success' => true,
            'data'    => $strip,
        ]);
    }

    /**
     * PATCH /api/v1/strips/{uuid}/watermark
     */
    public function toggleWatermark(Request $request, string $uuid): JsonResponse
    {
        $strip = PhotoStrip::where('uuid', $uuid)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $strip->update(['show_watermark' => !$strip->show_watermark]);

        return response()->json([
            'success' => true,
            'data'    => ['show_watermark' => $strip->show_watermark],
        ]);
    }

    /**
     * POST /api/v1/strips/{uuid}/print
     *
     * Order instant print at booth.
     */
    public function print(Request $request, string $uuid): JsonResponse
    {
        $request->validate([
            'booth_uuid'   => 'required|string',
            'copies'       => 'integer|min:1|max:5',
            'voucher_code' => 'nullable|string',
        ]);

        $strip = PhotoStrip::where('uuid', $uuid)
            ->where('user_id', $request->user()->id)
            ->where('status', 'ready')
            ->firstOrFail();

        // TODO: Dispatch PrintJobJob::dispatch($strip, $request->booth_uuid, $request->copies)

        return response()->json([
            'success' => true,
            'message' => 'Permintaan cetak dikirim ke booth.',
            'data'    => [
                'strip_uuid'  => $strip->uuid,
                'copies'      => $request->copies ?? 1,
                'booth_uuid'  => $request->booth_uuid,
                'queued_at'   => now()->toIso8601String(),
            ],
        ]);
    }

    /**
     * GET /api/v1/strips/share/{token}
     *
     * Public share link access (no auth required).
     */
    public function shareLink(string $token): JsonResponse
    {
        $strip = PhotoStrip::where('share_token', $token)
            ->where('status', 'ready')
            ->first();

        if (!$strip || ($strip->share_expires_at && now()->gt($strip->share_expires_at))) {
            return response()->json([
                'success'    => false,
                'message'    => 'Link berbagi tidak valid atau sudah kedaluwarsa.',
                'error_code' => 'SHARE_LINK_EXPIRED',
            ], 410);
        }

        return response()->json([
            'success' => true,
            'data'    => [
                'uuid'              => $strip->uuid,
                'watermarked_url'   => $strip->watermarked_url,
                'clean_url'         => $strip->show_watermark ? null : $strip->clean_url,
                'gif_url'           => $strip->gif_url,
                'aspect_ratio'      => $strip->aspect_ratio,
                'width_px'          => $strip->width_px,
                'height_px'         => $strip->height_px,
                'share_expires_at'  => $strip->share_expires_at?->toIso8601String(),
            ],
        ]);
    }

    /**
     * POST /api/v1/strips/{uuid}/share
     *
     * Generate or refresh share link (TTL 7 days).
     */
    public function createShareLink(Request $request, string $uuid): JsonResponse
    {
        $strip = PhotoStrip::where('uuid', $uuid)
            ->where('user_id', $request->user()->id)
            ->where('status', 'ready')
            ->firstOrFail();

        $strip->update([
            'share_token'       => Str::random(64),
            'share_expires_at'  => now()->addDays(7),
        ]);

        return response()->json([
            'success' => true,
            'data'    => [
                'share_url'        => url('/api/v1/strips/share/' . $strip->share_token),
                'share_token'      => $strip->share_token,
                'share_expires_at' => $strip->share_expires_at->toIso8601String(),
            ],
        ]);
    }

    /**
     * POST /api/v1/strips/{uuid}/export/email
     *
     * Send download link to user's email.
     */
    public function exportEmail(Request $request, string $uuid): JsonResponse
    {
        $strip = PhotoStrip::where('uuid', $uuid)
            ->where('user_id', $request->user()->id)
            ->where('status', 'ready')
            ->firstOrFail();

        $user = $request->user();

        // Ensure share link exists
        if (!$strip->share_token) {
            $strip->update([
                'share_token'      => Str::random(64),
                'share_expires_at' => now()->addDays(7),
            ]);
        }

        // TODO: Dispatch SendPhotoStripEmailJob::dispatch($strip, $user)

        return response()->json([
            'success' => true,
            'message' => "Tautan download dikirim ke email {$user->email}.",
        ]);
    }

    /**
     * POST /api/v1/strips/{uuid}/export/drive
     *
     * Enqueue Google Drive sync job.
     */
    public function exportDrive(Request $request, string $uuid): JsonResponse
    {
        $strip = PhotoStrip::where('uuid', $uuid)
            ->where('user_id', $request->user()->id)
            ->where('status', 'ready')
            ->firstOrFail();

        // Create/reset storage sync record
        $sync = StorageSync::updateOrCreate(
            ['strip_id' => $strip->id, 'destination_type' => 'google_drive'],
            [
                'user_id'     => $request->user()->id,
                'source_url'  => $strip->clean_url ?? $strip->watermarked_url,
                'status'      => 'pending',
                'attempts'    => 0,
                'last_error'  => null,
            ]
        );

        // TODO: Dispatch UploadPhotostripToDriveJob::dispatch($sync)

        return response()->json([
            'success' => true,
            'message' => 'Sinkronisasi ke Google Drive dijadwalkan.',
            'data'    => ['sync_id' => $sync->id, 'status' => 'pending'],
        ]);
    }
}
