<?php namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class LoyaltyTransaction extends Model {
    public $timestamps = false;
    protected $fillable = ['user_id','type','points','balance_before','balance_after','reference_type','reference_id','description','created_at'];
    protected $casts = ['created_at'=>'datetime'];
    public function user() { return $this->belongsTo(User::class); }
}
