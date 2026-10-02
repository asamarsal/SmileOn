<?php namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class LoyaltyReward extends Model {
    protected $fillable = ['name','description','type','points_required','value','is_active','stock'];
    protected $casts = ['is_active'=>'boolean','value'=>'decimal:2'];
}
