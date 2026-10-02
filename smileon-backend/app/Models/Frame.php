<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class Frame extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'uuid', 'creator_id', 'category_id', 'title', 'description',
        'thumbnail_url', 'frame_url', 'orientation', 'width_px', 'height_px',
        'price_credits', 'is_free', 'status', 'report_count', 'download_count',
        'use_count', 'priority_score', 'promoted_until',
    ];

    protected $casts = [
        'is_free'        => 'boolean',
        'price_credits'  => 'decimal:2',
        'promoted_until' => 'datetime',
    ];

    protected static function booted(): void
    {
        static::creating(fn (Frame $f) => $f->uuid ??= (string) Str::uuid());
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'creator_id');
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(FrameCategory::class);
    }

    public function reports(): HasMany
    {
        return $this->hasMany(FrameReport::class);
    }

    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    public function scopePromoted($query)
    {
        return $query->where(function ($q) {
            $q->where('priority_score', '>', 0)
              ->where(fn ($r) => $r->whereNull('promoted_until')->orWhere('promoted_until', '>', now()));
        });
    }
}
