<?php namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class LoyaltyAccount extends Model {
    protected $fillable = ['user_id','points_balance','lifetime_earned','lifetime_redeemed','tier','streak_days','last_check_in_date'];
    protected $casts = ['last_check_in_date'=>'date'];
    public function user() { return $this->belongsTo(User::class); }
}
