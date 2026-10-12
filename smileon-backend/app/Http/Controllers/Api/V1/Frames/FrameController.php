<?php

namespace App\Http\Controllers\Api\V1\Frames;

use App\Http\Controllers\Controller;
use App\Models\Frame;
use App\Models\FrameCategory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FrameController extends Controller
{
    /**
     * GET /api/v1/frames
     * Daftar frame dengan filter kategori, orientasi, gratis/berbayar, dan pencarian nama frame.
     */
    public function index(Request $request): JsonResponse
    {
        $search = $request->search ?? $request->title ?? $request->name ?? $request->q;

        $query = Frame::with('category:id,name,slug')
            ->active()
            ->when($request->category, fn($q, $c) => $q->whereHas('category', fn($q2) => $q2->where('slug', $c)))
            ->when($request->orientation, fn($q, $o) => $q->where('orientation', $o))
            ->when($request->has('is_free'), fn($q) => $q->where('is_free', filter_var($request->is_free, FILTER_VALIDATE_BOOLEAN)))
            ->when($search, fn($q, $s) => $q->whereRaw('LOWER(title) LIKE ?', ['%' . strtolower($s) . '%']))
            ->orderByDesc('priority_score')
            ->orderByDesc('created_at');

        $frames = $query->paginate($request->per_page ?? 20);

        // Jika user terautentikasi (Bearer token opsional), tandai is_saved / is_liked
        $user = auth('sanctum')->user();
        if ($user) {
            $savedIds = $user->userSavedFrames()->pluck('frames.id')->toArray();
            $frames->getCollection()->transform(function ($frame) use ($savedIds) {
                $isSaved = in_array($frame->id, $savedIds, true);
                $frame->is_saved = $isSaved;
                $frame->is_liked = $isSaved;
                return $frame;
            });
        }

        return response()->json(['success' => true, 'data' => $frames]);
    }

    /**
     * GET /api/v1/frames/{uuid}
     * Detail satu frame berdasarkan UUID.
     */
    public function show(string $uuid): JsonResponse
    {
        $frame = Frame::with('category:id,name,slug', 'creator:id,name,avatar_url')
            ->active()
            ->where('uuid', $uuid)
            ->firstOrFail();

        $user = auth('sanctum')->user();
        if ($user) {
            $isSaved = $user->userSavedFrames()->where('frame_id', $frame->id)->exists();
            $frame->is_saved = $isSaved;
            $frame->is_liked = $isSaved;
        }

        return response()->json(['success' => true, 'data' => $frame]);
    }

    /**
     * POST /api/v1/frames/{uuid}/report
     */
    public function report(Request $request, string $uuid): JsonResponse
    {
        $request->validate(['reason' => 'required|string|max:100', 'notes' => 'nullable|string|max:500']);
        $frame = Frame::where('uuid', $uuid)->firstOrFail();

        $report = $frame->reports()->firstOrCreate(
            ['reporter_id' => $request->user()->id],
            ['reason' => $request->reason, 'notes' => $request->notes]
        );

        if (!$report->wasRecentlyCreated) {
            return response()->json(['success' => false, 'message' => 'Anda sudah melaporkan frame ini.'], 409);
        }

        $frame->increment('report_count');

        if ($frame->report_count >= 5) {
            $frame->update(['status' => 'under_review']);
        }

        return response()->json(['success' => true, 'message' => 'Laporan frame dikirim.'], 201);
    }

    /**
     * POST /api/v1/user/frames/save OR POST /api/v1/user/frames/{uuid}/save
     * Menyimpan frame ke koleksi pengguna (Frame Disimpan).
     */
    public function save(Request $request, ?string $uuid = null): JsonResponse
    {
        $targetUuid = $uuid ?? $request->frame_uuid ?? $request->uuid;
        if (!$targetUuid) {
            return response()->json(['success' => false, 'message' => 'frame_uuid wajib diisi.'], 422);
        }

        $frame = Frame::where('uuid', $targetUuid)->firstOrFail();
        $changes = $request->user()->userSavedFrames()->syncWithoutDetaching([$frame->id]);

        if (empty($changes['attached'])) {
            return response()->json([
                'success' => true,
                'is_saved' => true,
                'message' => 'Frame sudah tersimpan di koleksi Anda.'
            ]);
        }

        return response()->json([
            'success' => true,
            'is_saved' => true,
            'message' => 'Frame berhasil disimpan ke koleksi.'
        ], 201);
    }

    /**
     * DELETE /api/v1/user/frames/{uuid}/unsave
     * Menghapus frame dari simpanan pengguna.
     */
    public function unsave(Request $request, string $uuid): JsonResponse
    {
        $frame = Frame::where('uuid', $uuid)->firstOrFail();
        $request->user()->userSavedFrames()->where('frame_id', $frame->id)->delete();
        return response()->json([
            'success' => true,
            'is_saved' => false,
            'message' => 'Frame dihapus dari simpanan.'
        ]);
    }

    /**
     * GET /api/v1/user/frames/saved
     * Mengambil daftar Frame yang Disimpan oleh pengguna.
     */
    public function savedFrames(Request $request): JsonResponse
    {
        $frames = $request->user()->userSavedFrames()->with('category:id,name,slug')
            ->orderByDesc('user_saved_frames.created_at')
            ->paginate($request->per_page ?? 20);

        $frames->getCollection()->transform(function ($frame) {
            $frame->is_saved = true;
            $frame->is_liked = true;
            return $frame;
        });

        return response()->json(['success' => true, 'data' => $frames]);
    }

    /**
     * POST /api/v1/user/frames/{uuid}/favorite
     * Toggle status favorit frame.
     */
    public function toggleFavorite(Request $request, string $uuid): JsonResponse
    {
        return $this->toggleLike($request, $uuid);
    }

    /**
     * POST /api/v1/user/frames/{uuid}/like
     * Toggle status suka (Frame Disukai) / favorit.
     */
    public function toggleLike(Request $request, string $uuid): JsonResponse
    {
        $frame = Frame::where('uuid', $uuid)->firstOrFail();
        $user = $request->user();

        $exists = $user->userSavedFrames()->where('frame_id', $frame->id)->exists();

        if ($exists) {
            $user->userSavedFrames()->detach($frame->id);
            return response()->json([
                'success'      => true,
                'is_liked'     => false,
                'is_favorited' => false,
                'is_saved'     => false,
                'message'      => 'Frame dihapus dari disukai/favorit.'
            ]);
        } else {
            $user->userSavedFrames()->syncWithoutDetaching([$frame->id]);
            return response()->json([
                'success'      => true,
                'is_liked'     => true,
                'is_favorited' => true,
                'is_saved'     => true,
                'message'      => 'Frame berhasil disukai dan disimpan ke favorit.'
            ], 201);
        }
    }

    /**
     * GET /api/v1/user/frames/liked
     * Mengambil daftar Frame yang Disukai oleh pengguna (alias savedFrames).
     */
    public function likedFrames(Request $request): JsonResponse
    {
        return $this->savedFrames($request);
    }
}
