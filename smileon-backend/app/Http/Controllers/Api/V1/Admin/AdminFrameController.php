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
}
