<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class PhotoCredit extends Model
{
    protected $fillable = ['user_id', 'balance', 'reserved_balance', 'lifetime_earned', 'lifetime_used'];

    protected $casts = [
        'balance'          => 'integer',
        'reserved_balance' => 'integer',
        'lifetime_earned'  => 'integer',
        'lifetime_used'    => 'integer',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function transactions(): HasMany
    {
        return $this->hasMany(CreditTransaction::class, 'user_id', 'user_id');
    }
}
