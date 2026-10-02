<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\AdminAuditLog;
use App\Models\PhotoCredit;
use App\Models\CreditTransaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminUserController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $users = User::withTrashed()
            ->with('photoCredit', 'loyaltyAccount')
            ->when($request->search, fn($q, $s) => $q->where('name', 'LIKE', "%$s%")->orWhere('email', 'LIKE', "%$s%"))
            ->when($request->role, fn($q, $r) => $q->where('role', $r))
            ->when($request->status === 'inactive', fn($q) => $q->where('is_active', false))
            ->when($request->status === 'deleted', fn($q) => $q->onlyTrashed())
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 20);

        return response()->json(['success' => true, 'data' => $users]);
    }

    public function destroy(Request $request, string $uuid): JsonResponse
    {
        $user = User::where('uuid', $uuid)->firstOrFail();
        $before = $user->toArray();
        $user->delete();

        AdminAuditLog::create([
            'admin_id'    => $request->user()->id,
            'action'      => 'user.delete',
            'entity_type' => 'User',
            'entity_id'   => $user->id,
            'before'      => $before,
            'after'       => null,
            'ip_address'  => $request->ip(),
        ]);

        return response()->json(['success' => true, 'message' => 'User dihapus.']);
    }

    public function restore(Request $request, string $uuid): JsonResponse
    {
        $user = User::onlyTrashed()->where('uuid', $uuid)->firstOrFail();
        $user->restore();

        AdminAuditLog::create([
            'admin_id'    => $request->user()->id,
            'action'      => 'user.restore',
            'entity_type' => 'User',
            'entity_id'   => $user->id,
            'after'       => ['restored_at' => now()],
            'ip_address'  => $request->ip(),
        ]);

        return response()->json(['success' => true, 'message' => 'User dipulihkan.']);
    }

    public function toggleActive(Request $request, string $uuid): JsonResponse
    {
        $user = User::where('uuid', $uuid)->firstOrFail();
        $user->update(['is_active' => !$user->is_active]);

        AdminAuditLog::create([
            'admin_id'    => $request->user()->id,
            'action'      => 'user.toggle_active',
            'entity_type' => 'User',
            'entity_id'   => $user->id,
            'after'       => ['is_active' => $user->is_active],
            'ip_address'  => $request->ip(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Status user diperbarui.',
            'data'    => ['is_active' => $user->is_active],
        ]);
    }

    public function adjustCredits(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'amount' => 'required|integer',
            'note'   => 'required|string|max:255',
        ]);

        $user = User::findOrFail($id);
        $amount = (int) $request->amount;

        DB::transaction(function () use ($user, $amount, $request) {
            $credit = $user->photoCredit ?? PhotoCredit::create(['user_id' => $user->id]);
            $before = $credit->balance;
            $newBalance = max(0, $before + $amount);
            $credit->update([
                'balance'         => $newBalance,
                'lifetime_earned' => $amount > 0 ? $credit->lifetime_earned + $amount : $credit->lifetime_earned,
            ]);

            CreditTransaction::create([
                'user_id'        => $user->id,
                'type'           => 'admin_adjust',
                'amount'         => $amount,
                'balance_before' => $before,
                'balance_after'  => $newBalance,
                'note'           => $request->note,
                'created_at'     => now(),
            ]);

            AdminAuditLog::create([
                'admin_id'    => $request->user()->id,
                'action'      => 'user.credits.adjust',
                'entity_type' => 'User',
                'entity_id'   => $user->id,
                'before'      => ['balance' => $before],
                'after'       => ['balance' => $newBalance],
                'reason'      => $request->note,
                'ip_address'  => $request->ip(),
            ]);
        });

        return response()->json(['success' => true, 'message' => 'Kredit user diperbarui.']);
    }

    public function activityLogs(Request $request, string $uuid): JsonResponse
    {
        $user = User::where('uuid', $uuid)->firstOrFail();
        $logs = $user->activityLogs()->orderByDesc('created_at')->paginate(30);
        return response()->json(['success' => true, 'data' => $logs]);
    }
}
