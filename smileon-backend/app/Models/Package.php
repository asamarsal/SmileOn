<?php namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Package extends Model {
    protected $fillable = ['name','description','category','credits_amount','price','currency','badge_label','is_active','sort_order'];
    protected $casts = ['is_active'=>'boolean','price'=>'decimal:2'];
}
