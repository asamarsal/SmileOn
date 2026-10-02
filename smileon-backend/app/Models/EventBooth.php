<?php namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;
class EventBooth extends Model {
    protected $fillable = [
        'uuid','event_id','organizer_id','booth_name','pairing_code','device_fingerprint',
        'access_token_hash','refresh_token_hash','access_token_expires_at','refresh_token_expires_at',
        'status','hardware_info','printer_status','paper_remaining','camera_status',
        'disk_free_pct','latency_ms','last_heartbeat_at','revoked_at',
    ];
    protected $casts = [
        'access_token_expires_at'=>'datetime','refresh_token_expires_at'=>'datetime',
        'last_heartbeat_at'=>'datetime','revoked_at'=>'datetime','hardware_info'=>'array',
    ];
    protected static function booted(): void {
        static::creating(fn($b) => $b->uuid ??= (string) Str::uuid());
    }
    public function event() { return $this->belongsTo(Event::class); }
    public function organizer() { return $this->belongsTo(User::class,'organizer_id'); }
}
