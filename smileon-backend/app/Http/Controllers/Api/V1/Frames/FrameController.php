<?php

namespace App\Http\Controllers\Api\V1\Frames;

use App\Http\Controllers\Controller;
use App\Models\Frame;
use App\Models\FrameCategory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FrameController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $frames = Frame::with('category:id,name,slug')
            ->active()
            ->when($request->category, fn($q, $c) => $q->whereHas('category', fn($q2) => $q2->where('slug', $c)))
            ->when($request->orientation, fn($q, $o) => $q->where('orientation', $o))
            ->when($request->is_free, fn($q, $f) => $q->where('is_free', (bool)$f))
            ->when($request->search, fn($q, $s) => $q->where('title', 'LIKE', "%$s%"))
            ->orderByDesc('priority_score')->orderByDesc('created_at')
            ->paginate($request->per_page ?? 20);

        return response()->json(['success' => true, 'data' => $frames]);
    }

    public function show(string $uuid): JsonResponse
    {
        $frame = Frame::with('category:id,name,slug', 'creator:id,name,avatar_url')
            ->active()->where('uuid', $uuid)->firstOrFail();
        return response()->json(['success' => true, 'data' => $frame]);
    }

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

        // Auto-suspend if report threshold exceeded
        if ($frame->report_count >= 5) {
            $frame->update(['status' => 'under_review']);
        }

        return response()->json(['success' => true, 'message' => 'Laporan frame dikirim.'], 201);
    }

    public function save(Request $request): JsonResponse
    {
        $request->validate(['frame_uuid' => 'required|string']);
        $frame = Frame::where('uuid', $request->frame_uuid)->firstOrFail();

        $saved = $request->user()->userSavedFrames()->firstOrCreate(['frame_id' => $frame->id]);

        if (!$saved->wasRecentlyCreated) {
            return response()->json(['success' => false, 'message' => 'Frame sudah disimpan.'], 409);
        }

        return response()->json(['success' => true, 'message' => 'Frame berhasil disimpan.'], 201);
    }

    public function unsave(Request $request, string $uuid): JsonResponse
    {
        $frame = Frame::where('uuid', $uuid)->firstOrFail();
        $request->user()->userSavedFrames()->where('frame_id', $frame->id)->delete();
        return response()->json(['success' => true, 'message' => 'Frame dihapus dari simpanan.']);
    }

    public function savedFrames(Request $request): JsonResponse
    {
        $frames = $request->user()->savedFrames()->with('category:id,name,slug')
            ->orderByDesc('user_saved_frames.created_at')
            ->paginate($request->per_page ?? 20);
        return response()->json(['success' => true, 'data' => $frames]);
    }
}
