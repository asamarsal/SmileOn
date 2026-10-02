<?php namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class OutboxEvent extends Model {
    public $timestamps = false;
    protected $fillable = ['aggregate_type','aggregate_id','event_type','payload','status','attempts','last_error','dispatched_at','created_at'];
    protected $casts = ['payload'=>'array','dispatched_at'=>'datetime','created_at'=>'datetime'];
}
