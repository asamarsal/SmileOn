<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class UserVoucher extends Model
{
    protected $table = 'user_vouchers';

    protected $fillable = [
        'uuid',
        'user_id',
        'order_id',
        'voucher_code',
        'title',
        'category',
        'photo_count',
        'credit_amount',
        'price_formatted',
        'crypto_price',
        'payment_method',
        'status',
        'image_path',
        'used_for_event',
        'used_at',
        'expires_at',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
        'used_at'    => 'datetime',
    ];

    protected static function booted(): void
    {
        static::creating(function (UserVoucher $voucher) {
            if (empty($voucher->uuid)) {
                $voucher->uuid = (string) Str::uuid();
            }
            if (empty($voucher->voucher_code)) {
                $voucher->voucher_code = self::generateUniqueCode();
            }
            if (empty($voucher->expires_at)) {
                $voucher->expires_at = now()->addDays(60);
            }
        });
    }

    /**
     * Helper generator kode unik voucher maksimal 32 karakter
     * Format: SMLON-XXXXXXXX-XXXXXXXX-XXXXXXXX (Tepat 32 karakter)
     */
    public static function generateUniqueCode(string $prefix = 'SMLON'): string
    {
        $chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
        $randomSegment = function (int $len) use ($chars): string {
            $res = '';
            $max = strlen($chars) - 1;
            for ($i = 0; $i < $len; $i++) {
                $res .= $chars[random_int(0, $max)];
            }
            return $res;
        };

        $cleanPrefix = strtoupper(preg_replace('/[^A-Z0-9]/', '', $prefix));
        $pfx = strlen($cleanPrefix) > 5 ? substr($cleanPrefix, 0, 5) : str_pad($cleanPrefix, 5, 'X');
        $code = "{$pfx}-{$randomSegment(8)}-{$randomSegment(8)}-{$randomSegment(8)}";

        return strlen($code) > 32 ? substr($code, 0, 32) : $code;
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function isActive(): bool
    {
        if ($this->status !== 'Aktif') {
            return false;
        }
        if ($this->expires_at && now()->gt($this->expires_at)) {
            return false;
        }
        return true;
    }

    public function isUsed(): bool
    {
        return $this->status === 'Digunakan';
    }

    public function isExpired(): bool
    {
        return $this->status === 'Kadaluarsa' || ($this->expires_at && now()->gt($this->expires_at));
    }
}
