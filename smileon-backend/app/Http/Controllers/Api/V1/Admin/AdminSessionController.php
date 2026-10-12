<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\PhotoSession;
use App\Models\Photo;
use App\Models\AdminAuditLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminSessionController extends Controller
{
    /**
     * GET /api/v1/admin/sessions
     * List all photo sessions (personal & event) with filters.
     */
    public function index(Request $request): JsonResponse
    {
        $search = $request->search ?? $request->q;

        $sessions = PhotoSession::with([
            'user:id,name,email',
            'event:id,uuid,title',
            'frame:id,uuid,title,thumbnail_url',
            'strip:id,uuid,clean_url,status',
        ])
            ->when($request->mode, fn($q, $m) => $q->where('mode', $m))
            ->when($request->status, fn($q, $s) => $q->where('status', $s))
            ->when($request->event_id, fn($q, $e) => $q->where('event_id', $e))
            ->when($request->user_id, fn($q, $u) => $q->where('user_id', $u))
            ->when($request->date_from, fn($q, $d) => $q->whereDate('created_at', '>=', $d))
            ->when($request->date_to, fn($q, $d) => $q->whereDate('created_at', '<=', $d))
            ->when($search, function ($q, $s) {
                $term = '%' . strtolower($s) . '%';
                $q->where(fn($sub) => $sub->whereRaw('LOWER(session_code) LIKE ?', [$term])
                    ->orWhereRaw('LOWER(title) LIKE ?', [$term])
                    ->orWhereHas('user', fn($u) => $u->whereRaw('LOWER(name) LIKE ?', [$term])
                        ->orWhereRaw('LOWER(email) LIKE ?', [$term])));
            })
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 20);

        return response()->json(['success' => true, 'data' => $sessions]);
    }

    /**
     * GET /api/v1/admin/sessions/{uuid}
     * Detail full sebuah sesi foto untuk inspeksi admin.
     */
    public function show(string $uuid): JsonResponse
    {
        $session = PhotoSession::with([
            'user:id,name,email,avatar_url',
            'event:id,uuid,title,status,start_time,end_time',
            'guestVoucher',
            'frame:id,uuid,title,thumbnail_url,frame_url',
            'photos',
            'strip',
        ])->where('uuid', $uuid)->firstOrFail();

        return response()->json(['success' => true, 'data' => $session]);
    }

    /**
     * DELETE /api/v1/admin/sessions/{uuid}
     * Admin menghapus sesi foto.
     */
    public function destroy(Request $request, string $uuid): JsonResponse
    {
        $session = PhotoSession::where('uuid', $uuid)->firstOrFail();
        $sessionId = $session->id;
        $sessionCode = $session->session_code;

        $session->delete();

        AdminAuditLog::create([
            'admin_id'    => $request->user()->id,
            'action'      => 'photo_session.delete',
            'entity_type' => 'PhotoSession',
            'entity_id'   => $sessionId,
            'before'      => ['session_code' => $sessionCode],
            'ip_address'  => $request->ip(),
        ]);

        return response()->json(['success' => true, 'message' => "Sesi foto {$sessionCode} berhasil dihapus."]);
    }

    /**
     * GET /api/v1/admin/sessions/stats
     * Statistik sesi foto sistem (Personal vs Event, Tingkat Sukses).
     */
    public function stats(): JsonResponse
    {
        $total = PhotoSession::count();
        $completed = PhotoSession::where('status', 'completed')->count();
        $personal = PhotoSession::where('mode', 'personal')->count();
        $event = PhotoSession::where('mode', 'event')->count();
        $totalPhotos = Photo::count();

        return response()->json([
            'success' => true,
            'data'    => [
                'total_sessions'       => $total,
                'personal_sessions'    => $personal,
                'event_sessions'       => $event,
                'completed_sessions'   => $completed,
                'cancelled_sessions'   => PhotoSession::where('status', 'cancelled')->count(),
                'active_sessions'      => PhotoSession::whereIn('status', ['waiting', 'active', 'completing'])->count(),
                'completion_rate_pct'  => $total > 0 ? round(($completed / $total) * 100, 2) : 0,
                'total_photos_shot'    => $totalPhotos,
            ],
        ]);
    }
}
