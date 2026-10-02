<?php namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class StorageSync extends Model {
    protected $fillable = ['user_id','strip_id','source_url','destination_type','destination_id','destination_url','status','attempts','last_error','synced_at'];
    protected $casts = ['synced_at'=>'datetime'];
    public function user() { return $this->belongsTo(User::class); }
    public function strip() { return $this->belongsTo(PhotoStrip::class,'strip_id'); }
}
