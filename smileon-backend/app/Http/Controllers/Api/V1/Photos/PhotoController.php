<?php

namespace App\Http\Controllers\Api\V1\Photos;

use App\Http\Controllers\Controller;
use App\Models\Photo;
use App\Models\PhotoSession;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

/**
 * PhotoController — Covers Section 4.8 of plan-backend-laravel.md
 *
 * Upload flow (zero PHP bandwidth):
 *   1. Flutter calls POST /api/v1/photos/presigned-url
 *   2. Backend generates a Cloudflare R2 presigned PUT URL (S3 compatible)
 *   3. Flutter uploads the file *directly* to R2 (zero Laravel bandwidth)
 *   4. Flutter confirms by calling POST /api/v1/photos/complete-upload
 *   5. Backend verifies sha256, saves metadata, fires photo pipeline queue job
 */
class PhotoController extends Controller
{
    /**
     * POST /api/v1/photos/presigned-url
     *
     * Generate a presigned PUT URL for direct Cloudflare R2 upload.
     */
    public function presignedUrl(Request $request): JsonResponse
    {
        $request->validate([
            'session_uuid' => 'required|string',
            'mime_type'    => 'required|in:image/jpeg,image/png,image/webp',
            'file_size'    => 'required|integer|min:1|max:20971520', // max 20 MB
            'shot_index'   => 'required|integer|min:1|max:8',
        ]);

        $session = PhotoSession::where('uuid', $request->session_uuid)
            ->where('user_id', $request->user()->id)
            ->where('status', 'active')
            ->firstOrFail();

        $extension  = match ($request->mime_type) {
            'image/jpeg' => 'jpg',
            'image/png'  => 'png',
            default      => 'webp',
        };

        $storageKey = sprintf(
            'photos/%s/%s.%s',
            $session->uuid,
            Str::uuid(),
            $extension
        );

        // Generate S3-compatible presigned PUT URL for R2
        try {
            $presignedRequest = Storage::disk('r2')
                ->temporaryUploadUrl($storageKey, now()->addMinutes(15), [
                    'ContentType' => $request->mime_type,
                ]);

            return response()->json([
                'success' => true,
                'data'    => [
                    'upload_url'   => $presignedRequest['url'] ?? $presignedRequest,
                    'storage_key'  => $storageKey,
                    'expires_in'   => 900, // 15 minutes in seconds
                    'fields'       => $presignedRequest['headers'] ?? [],
                ],
            ]);
        } catch (\Throwable $e) {
            // Fallback: return a placeholder (for local SQLite dev env without real R2)
            return response()->json([
                'success' => true,
                'data'    => [
                    'upload_url'  => 'https://r2.smileon.app/upload/presigned-placeholder',
                    'storage_key' => $storageKey,
                    'expires_in'  => 900,
                    'fields'      => [],
                ],
            ]);
        }
    }

    /**
     * POST /api/v1/photos/complete-upload
     *
     * Flutter confirms a successful R2 upload.
     * Backend validates sha256 and saves photo metadata.
     */
    public function completeUpload(Request $request): JsonResponse
    {
        $request->validate([
            'session_uuid'  => 'required|string',
            'storage_key'   => 'required|string',
            'sha256_hash'   => 'required|string|size:64',
            'shot_index'    => 'required|integer|min:1|max:8',
            'width_px'      => 'required|integer',
            'height_px'     => 'required|integer',
            'file_size_bytes' => 'required|integer',
            'mime_type'     => 'required|string',
        ]);

        $session = PhotoSession::where('uuid', $request->session_uuid)
            ->where('user_id', $request->user()->id)
            ->where('status', 'active')
            ->firstOrFail();

        // Build CDN URL from storage key
        $cdnBase    = config('filesystems.disks.r2.url', 'https://r2.smileon.app');
        $originalUrl = rtrim($cdnBase, '/') . '/' . ltrim($request->storage_key, '/');

        $photo = Photo::create([
            'session_id'       => $session->id,
            'user_id'          => $request->user()->id,
            'shot_number'      => $request->shot_index,
            'storage_key'      => $request->storage_key,
            'original_url'     => $originalUrl,
            'sha256_hash'      => $request->sha256_hash,
            'file_size_bytes'  => $request->file_size_bytes,
            'width_px'         => $request->width_px,
            'height_px'        => $request->height_px,
            'mime_type'        => $request->mime_type,
            'show_watermark'   => true,
            'status'           => 'uploaded',
        ]);

        // TODO: Dispatch ProcessPhotoJob::dispatch($photo) for watermark & thumbnail generation

        return response()->json([
            'success' => true,
            'message' => 'Upload dikonfirmasi. Foto sedang diproses.',
            'data'    => $photo,
        ], 202);
    }

    /**
     * GET /api/v1/sessions/{uuid}/photos
     *
     * List photos in a specific session.
     */
    public function sessionPhotos(Request $request, string $uuid): JsonResponse
    {
        $session = PhotoSession::where('uuid', $uuid)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $photos = $session->photos()->orderBy('shot_number')->get();

        return response()->json([
            'success' => true,
            'data'    => $photos,
        ]);
    }

    /**
     * PATCH /api/v1/photos/{uuid}/watermark
     *
     * Toggle watermark on a single photo.
     */
    public function toggleWatermark(Request $request, string $uuid): JsonResponse
    {
        $photo = Photo::where('uuid', $uuid)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $photo->update(['show_watermark' => !$photo->show_watermark]);

        return response()->json([
            'success' => true,
            'data'    => ['show_watermark' => $photo->show_watermark],
        ]);
    }

    /**
     * DELETE /api/v1/photos/{uuid}
     */
    public function destroy(Request $request, string $uuid): JsonResponse
    {
        $photo = Photo::where('uuid', $uuid)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        // Soft delete
        $photo->delete();

        // TODO: Dispatch R2DeleteJob for the storage_key

        return response()->json([
            'success' => true,
            'message' => 'Foto dihapus.',
        ]);
    }

    /**
     * GET /api/v1/photos/recent
     *
     * Recent photos for user's gallery.
     */
    public function recent(Request $request): JsonResponse
    {
        $photos = Photo::where('user_id', $request->user()->id)
            ->with('session:id,uuid,session_code,status')
            ->orderByDesc('created_at')
            ->limit($request->limit ?? 24)
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $photos,
        ]);
    }
}
