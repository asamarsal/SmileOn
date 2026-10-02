<?php namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class UserActivityLog extends Model {
    public $timestamps = false;
    protected $fillable = ['user_id','action','entity_type','entity_id','description','metadata','ip_address','user_agent','created_at'];
    protected $casts = ['metadata'=>'array','created_at'=>'datetime'];
}
