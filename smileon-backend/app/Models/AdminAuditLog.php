<?php namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class AdminAuditLog extends Model {
    public $timestamps = false;
    protected $fillable = ['admin_id','action','entity_type','entity_id','before','after','reason','ip_address','user_agent','created_at'];
    protected $casts = ['before'=>'array','after'=>'array','created_at'=>'datetime'];
    public function admin() { return $this->belongsTo(User::class,'admin_id'); }
}
