<?php namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class OrderItem extends Model {
    protected $fillable = ['order_id','item_type','item_id','item_name','quantity','unit_price','total'];
    public function order() { return $this->belongsTo(Order::class); }
}
