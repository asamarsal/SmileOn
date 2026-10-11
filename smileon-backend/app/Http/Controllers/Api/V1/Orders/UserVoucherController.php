<?php

namespace App\Http\Controllers\Api\V1\Orders;

use App\Http\Controllers\Controller;
use App\Models\UserVoucher;
use App\Models\Package;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class UserVoucherController extends Controller
{
    /**
     * GET /api/v1/vouchers/my
     * Mengambil daftar tiket voucher yang dimiliki oleh user (menu Voucher Saya).
     */
    public function myVouchers(Request $request): JsonResponse
    {
        $user = $request->user();
        $query = UserVoucher::where('user_id', $user->id);

        if ($request->has('status') && !empty($request->status) && $request->status !== 'Semua') {
            $query->where('status', $request->status);
        }

        $vouchers = $query->orderByDesc('created_at')->get();

        // Calculate summary metrics
        $allUserVouchers = UserVoucher::where('user_id', $user->id)->get();
        $activeCount = $allUserVouchers->where('status', 'Aktif')->count();
        $totalCreditsAvailable = $allUserVouchers->where('status', 'Aktif')->sum('credit_amount');

        return response()->json([
            'success' => true,
            'data'    => $vouchers,
            'meta'    => [
                'total_vouchers'  => $allUserVouchers->count(),
                'active_vouchers' => $activeCount,
                'total_credits'   => $totalCreditsAvailable,
            ],
        ]);
    }

    /**
     * POST /api/v1/vouchers/purchase
     * Membuat tiket voucher unik 32-karakter setelah transaksi pembelian berhasil.
     */
    public function purchase(Request $request): JsonResponse
    {
        $request->validate([
            'title'          => 'required|string|max:150',
            'category'       => 'nullable|string|max:50',
            'photo_count'    => 'required|string|max:50',
            'credit_amount'  => 'required|integer|min:1',
            'price_formatted'=> 'required|string|max:50',
            'crypto_price'   => 'nullable|string|max:50',
            'payment_method' => 'nullable|string|max:50',
            'image_path'     => 'nullable|string|max:255',
            'package_id'     => 'nullable|integer',
        ]);

        $user = $request->user();

        $voucher = DB::transaction(function () use ($request, $user) {
            $code = UserVoucher::generateUniqueCode();
            while (UserVoucher::where('voucher_code', $code)->exists()) {
                $code = UserVoucher::generateUniqueCode();
            }

            return UserVoucher::create([
                'user_id'        => $user->id,
                'voucher_code'   => $code,
                'title'          => $request->title,
                'category'       => $request->category ?? 'Event',
                'photo_count'    => $request->photo_count,
                'credit_amount'  => $request->credit_amount,
                'price_formatted'=> $request->price_formatted,
                'crypto_price'   => $request->crypto_price ?? '0 MON',
                'payment_method' => $request->payment_method ?? 'QRIS',
                'image_path'     => $request->image_path ?? 'assets/images/voucher/wedding_package.jpg',
                'status'         => 'Aktif',
                'expires_at'     => now()->addDays(60),
            ]);
        });

        return response()->json([
            'success' => true,
            'message' => 'Tiket voucher berhasil digenerate dan ditambahkan ke Voucher Saya.',
            'data'    => $voucher,
        ], 201);
    }

    /**
     * POST /api/v1/vouchers/verify-code
     * Memverifikasi kode voucher yang dimasukkan di kamera atau form.
     */
    public function verifyCode(Request $request): JsonResponse
    {
        $request->validate(['code' => 'required|string']);

        $cleanCode = strtoupper(preg_replace('/[\s-]/', '', $request->code));

        $voucher = UserVoucher::whereRaw("UPPER(REPLACE(voucher_code, '-', '')) = ?", [$cleanCode])
            ->orWhere('voucher_code', strtoupper(trim($request->code)))
            ->first();

        if (!$voucher) {
            return response()->json([
                'success'    => false,
                'message'    => 'Kode voucher tidak ditemukan atau belum terdaftar.',
                'error_code' => 'VOUCHER_NOT_FOUND',
            ], 404);
        }

        if ($voucher->isExpired()) {
            return response()->json([
                'success'    => false,
                'message'    => "Voucher {$voucher->voucher_code} telah melewati batas masa berlaku.",
                'error_code' => 'VOUCHER_EXPIRED',
                'data'       => $voucher,
            ], 422);
        }

        if ($voucher->isUsed()) {
            return response()->json([
                'success'    => false,
                'message'    => "Voucher {$voucher->voucher_code} sudah digunakan untuk acara sebelumnya.",
                'error_code' => 'VOUCHER_ALREADY_USED',
                'data'       => $voucher,
            ], 422);
        }

        return response()->json([
            'success' => true,
            'message' => "Voucher {$voucher->title} ({$voucher->credit_amount} foto) siap digunakan.",
            'data'    => $voucher,
        ]);
    }
}
