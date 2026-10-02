<?php namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;
class Photo extends Model {
    use SoftDeletes;
    protected $fillable = [
        'uuid','session_id','user_id','shot_number','storage_key','original_url',
        'watermarked_url','sha256_hash','file_size_bytes','width_px','height_px',
        'mime_type','show_watermark','status',
    ];
    protected $casts = ['show_watermark'=>'boolean'];
    protected static function booted(): void {
        static::creating(fn($p) => $p->uuid ??= (string) Str::uuid());
    }
    public function session() { return $this->belongsTo(PhotoSession::class,'session_id'); }
    public function user() { return $this->belongsTo(User::class); }
}
