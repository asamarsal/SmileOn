<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class PhotoSession extends Model
{
    use SoftDeletes;

    protected $table = 'photo_sessions';

    protected $fillable = [
        'uuid', 'session_code', 'user_id', 'event_id', 'booth_id', 'frame_id',
        'status', 'mode', 'orientation', 'credits_required', 'photos_count',
        'photos_taken', 'participants', 'location', 'expires_at',
        'completed_at', 'cancelled_at',
    ];

    protected $casts = [
        'participants'  => 'array',
        'expires_at'    => 'datetime',
        'completed_at'  => 'datetime',
        'cancelled_at'  => 'datetime',
    ];

    // Valid state transitions
    public const TRANSITIONS = [
        'draft'      => ['waiting'],
        'waiting'    => ['active', 'cancelled'],
        'active'     => ['completing', 'cancelled'],
        'completing' => ['processing'],
        'processing' => ['completed', 'failed'],
        'completed'  => [],
        'cancelled'  => [],
        'expired'    => [],
        'failed'     => [],
    ];

    protected static function booted(): void
    {
        static::creating(function (PhotoSession $session) {
            if (empty($session->uuid)) {
                $session->uuid = (string) Str::uuid();
            }
            if (empty($session->session_code)) {
                $session->session_code = 'SO-' . date('Y') . '-' . strtoupper(Str::random(4));
            }
        });
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function event(): BelongsTo
    {
        return $this->belongsTo(Event::class);
    }

    public function frame(): BelongsTo
    {
        return $this->belongsTo(Frame::class);
    }

    public function photos(): HasMany
    {
        return $this->hasMany(Photo::class, 'session_id');
    }

    public function strip(): \Illuminate\Database\Eloquent\Relations\HasOne
    {
        return $this->hasOne(PhotoStrip::class, 'session_id');
    }

    /**
     * Check if transition to given status is valid.
     */
    public function canTransitionTo(string $newStatus): bool
    {
        return in_array($newStatus, self::TRANSITIONS[$this->status] ?? [], true);
    }
}
