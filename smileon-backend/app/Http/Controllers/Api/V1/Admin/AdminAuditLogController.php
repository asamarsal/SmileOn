<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use App\Models\UserActivityLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminAuditLogController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $logs = AdminAuditLog::with('admin:id,name,email')
            ->when($request->action, fn($q, $a) => $q->where('action', 'LIKE', "%$a%"))
            ->when($request->admin_id, fn($q, $id) => $q->where('admin_id', $id))
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 30);

        return response()->json(['success' => true, 'data' => $logs]);
    }

    public function activityFeed(Request $request): JsonResponse
    {
        $logs = UserActivityLog::with('user:id,name,uuid')
            ->when($request->user_id, fn($q, $id) => $q->where('user_id', $id))
            ->when($request->action, fn($q, $a) => $q->where('action', 'LIKE', "%$a%"))
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 30);

        return response()->json(['success' => true, 'data' => $logs]);
    }
}
