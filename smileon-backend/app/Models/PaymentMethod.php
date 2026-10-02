<?php namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class PaymentMethod extends Model {
    protected $fillable = ['type','name','logo_url','admin_fee','admin_fee_flat','instructions','is_active','sort_order','metadata'];
    protected $casts = ['is_active'=>'boolean','metadata'=>'array','admin_fee'=>'decimal:2','admin_fee_flat'=>'decimal:2'];
}
