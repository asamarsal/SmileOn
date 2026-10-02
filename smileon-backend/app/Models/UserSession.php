<?php namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class UserSession extends Model {
    protected $fillable = [
        'user_id','device_name','device_type','platform','os_version','app_version',
        'browser','is_mobile','ip_address','user_agent','token_hash','last_seen_at',
    ];
    protected $casts = ['is_mobile'=>'boolean','last_seen_at'=>'datetime'];
    public function user() { return $this->belongsTo(User::class); }
}
