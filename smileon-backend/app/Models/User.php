<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Support\Str;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes;

    /**
     * The attributes that are mass assignable.
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'username',
        'avatar_url',
        'phone_number',
        'auth_method',
        'wallet_address',
        'wallet_type',
        'network',
        'google_access_token',
        'google_refresh_token',
        'google_token_expires_at',
        'role',
        'locale',
        'is_active',
        'referral_code',
        'referred_by',
        'last_login_at',
    ];

    /**
     * The attributes that should be hidden for serialization.
     */
    protected $hidden = [
        'password',
        'remember_token',
        'google_access_token',
        'google_refresh_token',
    ];

    /**
     * Get the attributes that should be cast.
     */
    protected function casts(): array
    {
        return [
            'email_verified_at'       => 'datetime',
            'google_token_expires_at' => 'datetime',
            'last_login_at'           => 'datetime',
            'is_active'               => 'boolean',
        ];
    }

    /**
     * Boot — auto-generate UUID and referral code.
     */
    protected static function booted(): void
    {
        static::creating(function (User $user) {
            if (empty($user->uuid)) {
                $user->uuid = (string) Str::uuid();
            }
            if (empty($user->referral_code)) {
                $user->referral_code = strtoupper(Str::random(8));
            }
        });
    }

    // ============================================================
    // RELATIONSHIPS
    // ============================================================

    public function photoCredit(): HasOne
    {
        return $this->hasOne(PhotoCredit::class);
    }

    public function loyaltyAccount(): HasOne
    {
        return $this->hasOne(LoyaltyAccount::class);
    }

    public function sessions(): HasMany
    {
        return $this->hasMany(PhotoSession::class);
    }

    public function userSessions(): HasMany
    {
        return $this->hasMany(UserSession::class);
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    public function collectibles(): HasMany
    {
        return $this->hasMany(UserCollectible::class);
    }

    public function referredByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'referred_by');
    }

    public function referrals(): HasMany
    {
        return $this->hasMany(Referral::class, 'referrer_id');
    }

    public function activityLogs(): HasMany
    {
        return $this->hasMany(UserActivityLog::class);
    }

    public function shippingAddresses(): HasMany
    {
        return $this->hasMany(UserShippingAddress::class);
    }

    // ============================================================
    // HELPERS
    // ============================================================

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    public function isOrganizer(): bool
    {
        return in_array($this->role, ['admin', 'organizer'], true);
    }

    public function isActive(): bool
    {
        return (bool) $this->is_active;
    }

    /**
     * Get available credit balance.
     */
    public function availableCredits(): int
    {
        return (int) ($this->photoCredit?->balance ?? 0);
    }

    /**
     * Get reserved credit balance (held by active sessions).
     */
    public function reservedCredits(): int
    {
        return (int) ($this->photoCredit?->reserved_balance ?? 0);
    }

    /**
     * Log user activity asynchronously (non-blocking).
     */
    public function logActivity(string $action, ?string $entityType = null, ?int $entityId = null, array $metadata = []): void
    {
        try {
            UserActivityLog::create([
                'user_id'     => $this->id,
                'action'      => $action,
                'entity_type' => $entityType,
                'entity_id'   => $entityId,
                'metadata'    => $metadata ?: null,
            ]);
        } catch (\Throwable) {
            // Non-blocking — don't fail the main request
        }
    }
}
