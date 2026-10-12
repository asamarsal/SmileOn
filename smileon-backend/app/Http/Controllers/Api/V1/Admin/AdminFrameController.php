<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\Frame;
use App\Models\FrameCategory;
use App\Models\AdminAuditLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminFrameController extends Controller
{
    public function reports(Request $request): JsonResponse
    {
        $reports = \App\Models\FrameReport::with(['frame:id,uuid,title,thumbnail_url', 'reporter:id,name,email'])
            ->when($request->status, fn($q, $s) => $q->where('status', $s))
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 20);

        return response()->json(['success' => true, 'data' => $reports]);
    }

    public function resolveReport(Request $request, string $uuid): JsonResponse
    {
        $request->validate(['action' => 'required|in:dismiss,suspend,ban']);

        $frame = Frame::where('uuid', $uuid)->firstOrFail();
        $statusMap = ['dismiss' => 'active', 'suspend' => 'suspended', 'ban' => 'banned'];
        $frame->update(['status' => $statusMap[$request->action]]);
        $frame->reports()->where('status', 'pending')->update(['status' => 'reviewed']);

        AdminAuditLog::create([
            'admin_id' => $request->user()->id, 'action' => 'frame.report.resolve',
            'entity_type' => 'Frame', 'entity_id' => $frame->id,
            'after' => ['status' => $frame->status], 'ip_address' => $request->ip(),
        ]);

        return response()->json(['success' => true, 'message' => 'Laporan frame diselesaikan.']);
    }

    public function promote(Request $request, string $uuid): JsonResponse
    {
        $request->validate(['priority_score' => 'required|integer|min:0', 'promoted_until' => 'nullable|date']);
        $frame = Frame::where('uuid', $uuid)->firstOrFail();
        $frame->update($request->only('priority_score', 'promoted_until'));

        AdminAuditLog::create([
            'admin_id' => $request->user()->id, 'action' => 'frame.promote',
            'entity_type' => 'Frame', 'entity_id' => $frame->id,
            'after' => $frame->only('priority_score', 'promoted_until'), 'ip_address' => $request->ip(),
        ]);

        return response()->json(['success' => true, 'message' => 'Frame dipromosikan.']);
    }

    public function demote(Request $request, string $uuid): JsonResponse
    {
        $frame = Frame::where('uuid', $uuid)->firstOrFail();
        $frame->update(['priority_score' => 0, 'promoted_until' => null]);

        return response()->json(['success' => true, 'message' => 'Promosi frame dihapus.']);
    }

    /**
     * GET /api/v1/admin/frames
     * List all frames with status filtering (active, under_review, suspended, banned)
     */
    public function index(Request $request): JsonResponse
    {
        $frames = Frame::with('category:id,name,slug', 'creator:id,name,email')
            ->when($request->status, fn($q, $s) => $q->where('status', $s))
            ->when($request->category_id, fn($q, $c) => $q->where('category_id', $c))
            ->when($request->orientation, fn($q, $o) => $q->where('orientation', $o))
            ->when($request->search, fn($q, $s) => $q->where('title', 'LIKE', "%$s%"))
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 20);

        return response()->json(['success' => true, 'data' => $frames]);
    }

    /**
     * GET /api/v1/admin/frames/{uuid}
     */
    public function show(string $uuid): JsonResponse
    {
        $frame = Frame::with(['category', 'creator', 'reports.reporter'])->where('uuid', $uuid)->firstOrFail();
        return response()->json(['success' => true, 'data' => $frame]);
    }

    /**
     * POST /api/v1/admin/frames
     * Create new frame asset
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'title'          => 'required|string|max:150',
            'category_id'    => 'nullable|exists:frame_categories,id',
            'description'    => 'nullable|string',
            'thumbnail_url'  => 'required|string',
            'frame_url'      => 'required|string',
            'orientation'    => 'required|in:portrait,landscape,square',
            'width_px'       => 'nullable|integer',
            'height_px'      => 'nullable|integer',
            'price_credits'  => 'nullable|numeric|min:0',
            'is_free'        => 'boolean',
            'status'         => 'nullable|in:active,under_review,suspended,banned',
            'priority_score' => 'nullable|integer|min:0',
        ]);

        $data = $request->all();
        $data['creator_id'] = $request->user()->id;
        $data['status'] ??= 'active';
        $data['is_free'] ??= true;

        $frame = Frame::create($data);

        AdminAuditLog::create([
            'admin_id'    => $request->user()->id,
            'action'      => 'frame.create',
            'entity_type' => 'Frame',
            'entity_id'   => $frame->id,
            'after'       => $frame->toArray(),
            'ip_address'  => $request->ip(),
        ]);

        return response()->json(['success' => true, 'message' => 'Frame berhasil dibuat.', 'data' => $frame], 201);
    }

    /**
     * PUT/PATCH /api/v1/admin/frames/{uuid}
     * Update existing frame
     */
    public function update(Request $request, string $uuid): JsonResponse
    {
        $frame = Frame::where('uuid', $uuid)->firstOrFail();

        $request->validate([
            'title'          => 'sometimes|string|max:150',
            'category_id'    => 'nullable|exists:frame_categories,id',
            'description'    => 'nullable|string',
            'thumbnail_url'  => 'sometimes|string',
            'frame_url'      => 'sometimes|string',
            'orientation'    => 'sometimes|in:portrait,landscape,square',
            'width_px'       => 'nullable|integer',
            'height_px'      => 'nullable|integer',
            'price_credits'  => 'nullable|numeric|min:0',
            'is_free'        => 'boolean',
            'status'         => 'sometimes|in:active,under_review,suspended,banned',
            'priority_score' => 'nullable|integer|min:0',
        ]);

        $before = $frame->toArray();
        $frame->update($request->all());

        AdminAuditLog::create([
            'admin_id'    => $request->user()->id,
            'action'      => 'frame.update',
            'entity_type' => 'Frame',
            'entity_id'   => $frame->id,
            'before'      => $before,
            'after'       => $frame->fresh()->toArray(),
            'ip_address'  => $request->ip(),
        ]);

        return response()->json(['success' => true, 'message' => 'Frame berhasil diperbarui.', 'data' => $frame]);
    }

    /**
     * DELETE /api/v1/admin/frames/{uuid}
     * Soft delete frame
     */
    public function destroy(Request $request, string $uuid): JsonResponse
    {
        $frame = Frame::where('uuid', $uuid)->firstOrFail();
        $frame->delete();

        AdminAuditLog::create([
            'admin_id'    => $request->user()->id,
            'action'      => 'frame.delete',
            'entity_type' => 'Frame',
            'entity_id'   => $frame->id,
            'ip_address'  => $request->ip(),
        ]);

        return response()->json(['success' => true, 'message' => 'Frame berhasil dihapus.']);
    }
}
