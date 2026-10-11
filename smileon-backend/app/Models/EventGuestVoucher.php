<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class EventGuestVoucher extends Model
{
    protected $table = 'event_guest_vouchers';

    protected $fillable = [
        'uuid',
        'event_id',
        'guest_name',
        'guest_slug',
        'voucher_code',
        'category',
        'quota_limit',
        'quota_used',
        'has_photo',
        'last_photo_at',
        'qr_code_url',
        'status',
    ];

    protected $casts = [
        'has_photo'     => 'boolean',
        'last_photo_at' => 'datetime',
        'quota_limit'   => 'integer',
        'quota_used'    => 'integer',
    ];

    protected static function booted(): void
    {
        static::creating(function (EventGuestVoucher $voucher) {
            if (empty($voucher->uuid)) {
                $voucher->uuid = (string) Str::uuid();
            }
            if (empty($voucher->guest_slug)) {
                $voucher->guest_slug = self::slugify($voucher->guest_name);
            }
        });
    }

    /**
     * Helper generator slug kode tamu dan event
     * Format: [namatamu]-[namaevent] (misal: haikalronald-stevenbirthday)
     */
    public static function generateCode(string $guestName, string $eventName): string
    {
        $cleanGuest = self::slugify($guestName);
        $cleanEvent = self::slugify($eventName);
        return "{$cleanGuest}-{$cleanEvent}";
    }

    public static function slugify(string $text): string
    {
        $slug = strtolower(trim($text));
        $slug = preg_replace('/[^a-z0-9]/', '', $slug);
        return !empty($slug) ? $slug : 'guest';
    }

    public function event(): BelongsTo
    {
        return $this->belongsTo(Event::class);
    }

    public function photoSessions(): HasMany
    {
        return $this->hasMany(PhotoSession::class, 'guest_voucher_id');
    }

    public function isQuotaAvailable(): bool
    {
        return $this->status === 'active' && $this->quota_used < $this->quota_limit;
    }

    public function remainingQuota(): int
    {
        return max(0, $this->quota_limit - $this->quota_used);
    }
}
