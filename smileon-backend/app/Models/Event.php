<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class Event extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'uuid', 'organizer_id', 'name', 'description', 'banner_url', 'cover_visual',
        'starts_at', 'ends_at', 'expired_at', 'is_event_started', 'status',
        'access_code', 'total_credits', 'used_credits', 'reserved_credits',
        'force_remove_watermark', 'settings',
    ];

    protected $casts = [
        'starts_at'              => 'datetime',
        'ends_at'                => 'datetime',
        'expired_at'             => 'datetime',
        'is_event_started'       => 'boolean',
        'force_remove_watermark' => 'boolean',
        'cover_visual'           => 'array',
        'settings'               => 'array',
    ];

    protected static function booted(): void
    {
        static::creating(function (Event $event) {
            if (empty($event->uuid)) {
                $event->uuid = (string) Str::uuid();
            }
            if (empty($event->access_code)) {
                $event->access_code = strtoupper(Str::random(8));
            }
        });
    }

    public function organizer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'organizer_id');
    }

    public function frames(): HasMany
    {
        return $this->hasMany(EventFrame::class)->orderBy('slot_index');
    }

    public function booths(): HasMany
    {
        return $this->hasMany(EventBooth::class);
    }

    public function participants(): HasMany
    {
        return $this->hasMany(EventParticipant::class);
    }

    public function sessions(): HasMany
    {
        return $this->hasMany(PhotoSession::class);
    }

    public function vouchers(): BelongsToMany
    {
        return $this->belongsToMany(Voucher::class, 'event_vouchers')
                    ->withPivot('expires_at')
                    ->withTimestamps();
    }

    /**
     * Remaining pool credits available.
     */
    public function availablePoolCredits(): int
    {
        return max(0, $this->total_credits - $this->used_credits - $this->reserved_credits);
    }
}
