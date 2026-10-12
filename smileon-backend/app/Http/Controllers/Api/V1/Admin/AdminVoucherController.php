<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\Voucher;
use App\Models\UserVoucher;
use App\Models\EventGuestVoucher;
use App\Models\AdminAuditLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminVoucherController extends Controller
{
    /**
     * GET /api/v1/admin/vouchers
     * List all marketing & promo vouchers with filtering and search.
     */
    public function index(Request $request): JsonResponse
    {
        $search = $request->search ?? $request->q;

        $vouchers = Voucher::query()
            ->when($request->type, fn($q, $t) => $q->where('type', $t))
            ->when($request->has('is_active'), fn($q) => $q->where('is_active', filter_var($request->is_active, FILTER_VALIDATE_BOOLEAN)))
            ->when($search, function ($q, $s) {
                $term = '%' . strtolower($s) . '%';
                $q->where(fn($sub) => $sub->whereRaw('LOWER(code) LIKE ?', [$term])
                    ->orWhereRaw('LOWER(name) LIKE ?', [$term]));
            })
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 20);

        return response()->json(['success' => true, 'data' => $vouchers]);
    }

    /**
     * POST /api/v1/admin/vouchers
     * Create new voucher code.
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'code'               => 'required|string|max:50|unique:vouchers,code',
            'name'               => 'required|string|max:150',
            'description'        => 'nullable|string',
            'type'               => 'required|in:credit_bonus,discount_pct,discount_flat,free_print,strip_pct',
            'value'              => 'required|numeric|min:0',
            'discount_strip_pct' => 'nullable|numeric|min:0|max:100',
            'free_strip_copies'  => 'nullable|integer|min:0',
            'max_uses'           => 'nullable|integer|min:1',
            'valid_from'         => 'nullable|date',
            'valid_until'        => 'nullable|date|after_or_equal:valid_from',
            'is_active'          => 'boolean',
        ]);

        $data = $request->all();
        $data['code'] = strtoupper(trim($data['code']));
        $data['is_active'] ??= true;

        $voucher = Voucher::create($data);

        AdminAuditLog::create([
            'admin_id'    => $request->user()->id,
            'action'      => 'voucher.create',
            'entity_type' => 'Voucher',
            'entity_id'   => $voucher->id,
            'after'       => $voucher->toArray(),
            'ip_address'  => $request->ip(),
        ]);

        return response()->json(['success' => true, 'message' => 'Voucher berhasil dibuat.', 'data' => $voucher], 201);
    }

    /**
     * GET /api/v1/admin/vouchers/{id}
     * Show single voucher detail with usage statistics.
     */
    public function show(int $id): JsonResponse
    {
        $voucher = Voucher::findOrFail($id);

        return response()->json([
            'success' => true,
            'data'    => array_merge($voucher->toArray(), [
                'is_currently_valid' => $voucher->isValid(),
                'remaining_uses'     => $voucher->max_uses ? max(0, $voucher->max_uses - $voucher->used_count) : 'Unlimited',
            ]),
        ]);
    }

    /**
     * PUT/PATCH /api/v1/admin/vouchers/{id}
     * Update voucher.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $voucher = Voucher::findOrFail($id);

        $request->validate([
            'code'               => 'sometimes|string|max:50|unique:vouchers,code,' . $id,
            'name'               => 'sometimes|string|max:150',
            'description'        => 'nullable|string',
            'type'               => 'sometimes|in:credit_bonus,discount_pct,discount_flat,free_print,strip_pct',
            'value'              => 'sometimes|numeric|min:0',
            'discount_strip_pct' => 'nullable|numeric|min:0|max:100',
            'free_strip_copies'  => 'nullable|integer|min:0',
            'max_uses'           => 'nullable|integer|min:1',
            'valid_from'         => 'nullable|date',
            'valid_until'        => 'nullable|date',
            'is_active'          => 'boolean',
        ]);

        $data = $request->all();
        if (isset($data['code'])) {
            $data['code'] = strtoupper(trim($data['code']));
        }

        $before = $voucher->toArray();
        $voucher->update($data);

        AdminAuditLog::create([
            'admin_id'    => $request->user()->id,
            'action'      => 'voucher.update',
            'entity_type' => 'Voucher',
            'entity_id'   => $voucher->id,
            'before'      => $before,
            'after'       => $voucher->fresh()->toArray(),
            'ip_address'  => $request->ip(),
        ]);

        return response()->json(['success' => true, 'message' => 'Voucher berhasil diperbarui.', 'data' => $voucher]);
    }

    /**
     * PATCH /api/v1/admin/vouchers/{id}/toggle-active
     * Enable or disable voucher.
     */
    public function toggleActive(Request $request, int $id): JsonResponse
    {
        $voucher = Voucher::findOrFail($id);
        $voucher->update(['is_active' => !$voucher->is_active]);

        AdminAuditLog::create([
            'admin_id'    => $request->user()->id,
            'action'      => 'voucher.toggle_active',
            'entity_type' => 'Voucher',
            'entity_id'   => $voucher->id,
            'after'       => ['is_active' => $voucher->is_active],
            'ip_address'  => $request->ip(),
        ]);

        return response()->json([
            'success'   => true,
            'message'   => 'Status voucher berhasil diubah.',
            'is_active' => $voucher->is_active,
        ]);
    }

    /**
     * DELETE /api/v1/admin/vouchers/{id}
     * Soft delete voucher.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $voucher = Voucher::findOrFail($id);
        $voucher->delete();

        AdminAuditLog::create([
            'admin_id'    => $request->user()->id,
            'action'      => 'voucher.delete',
            'entity_type' => 'Voucher',
            'entity_id'   => $id,
            'ip_address'  => $request->ip(),
        ]);

        return response()->json(['success' => true, 'message' => 'Voucher berhasil dihapus.']);
    }

    /**
     * GET /api/v1/admin/user-vouchers
     * List user purchased vouchers across the ecosystem.
     */
    public function userVouchers(Request $request): JsonResponse
    {
        $search = $request->search ?? $request->q;

        $vouchers = UserVoucher::with('user:id,name,email')
            ->when($request->status, fn($q, $st) => $q->where('status', $st))
            ->when($request->category, fn($q, $cat) => $q->where('category', $cat))
            ->when($search, function ($q, $s) {
                $term = '%' . strtolower($s) . '%';
                $q->where(fn($sub) => $sub->whereRaw('LOWER(voucher_code) LIKE ?', [$term])
                    ->orWhereRaw('LOWER(title) LIKE ?', [$term]));
            })
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 20);

        return response()->json(['success' => true, 'data' => $vouchers]);
    }

    /**
     * DELETE /api/v1/admin/user-vouchers/{id}
     */
    public function deleteUserVoucher(Request $request, int $id): JsonResponse
    {
        $voucher = UserVoucher::findOrFail($id);
        $voucher->delete();

        AdminAuditLog::create([
            'admin_id'    => $request->user()->id,
            'action'      => 'user_voucher.delete',
            'entity_type' => 'UserVoucher',
            'entity_id'   => $id,
            'ip_address'  => $request->ip(),
        ]);

        return response()->json(['success' => true, 'message' => 'Voucher pengguna berhasil dihapus.']);
    }

    /**
     * GET /api/v1/admin/event-guest-vouchers
     * List guest vouchers generated for events.
     */
    public function eventGuestVouchers(Request $request): JsonResponse
    {
        $search = $request->search ?? $request->q;

        $vouchers = EventGuestVoucher::with('event:id,uuid,title,start_time')
            ->when($request->event_id, fn($q, $e) => $q->where('event_id', $e))
            ->when($request->status, fn($q, $st) => $q->where('status', $st))
            ->when($search, function ($q, $s) {
                $term = '%' . strtolower($s) . '%';
                $q->where(fn($sub) => $sub->whereRaw('LOWER(voucher_code) LIKE ?', [$term])
                    ->orWhereRaw('LOWER(guest_name) LIKE ?', [$term]));
            })
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 20);

        return response()->json(['success' => true, 'data' => $vouchers]);
    }

    /**
     * GET /api/v1/admin/vouchers/stats
     */
    public function stats(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data'    => [
                'total_promo_vouchers'  => Voucher::count(),
                'active_promo_vouchers' => Voucher::where('is_active', true)->count(),
                'total_user_vouchers'   => UserVoucher::count(),
                'active_user_vouchers'  => UserVoucher::where('status', 'Aktif')->count(),
                'used_user_vouchers'    => UserVoucher::where('status', 'Terpakai')->count(),
                'total_guest_vouchers'  => EventGuestVoucher::count(),
            ],
        ]);
    }
}
