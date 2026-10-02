<?php namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class PersonalQrToken extends Model {
    protected $table = 'personal_qr_tokens';
    protected $fillable = ['token','user_id','status','ip_address','expires_at'];
    protected $casts = ['expires_at'=>'datetime'];
    public function user() { return $this->belongsTo(User::class); }
    public function isExpired(): bool { return now()->gt($this->expires_at); }
    public function isPending(): bool { return $this->status === 'pending'; }
}
