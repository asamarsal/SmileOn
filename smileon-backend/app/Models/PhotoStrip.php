<?php namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;
class PhotoStrip extends Model {
    use SoftDeletes;
    protected $table = 'photo_strips';
    protected $fillable = [
        'uuid','session_id','user_id','storage_key','clean_url','watermarked_url',
        'gif_url','high_res_print_url','share_token','share_expires_at',
        'width_px','height_px','aspect_ratio','print_size_inch','file_size_bytes',
        'show_watermark','status',
    ];
    protected $casts = ['show_watermark'=>'boolean','share_expires_at'=>'datetime'];
    protected static function booted(): void {
        static::creating(fn($s) => $s->uuid ??= (string) Str::uuid());
    }
    public function session() { return $this->belongsTo(PhotoSession::class,'session_id'); }
    public function user() { return $this->belongsTo(User::class); }
}
