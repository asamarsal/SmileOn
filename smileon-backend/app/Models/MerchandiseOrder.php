<?php namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;
class MerchandiseOrder extends Model {
    protected $fillable = [
        'uuid','user_id','order_id','address_id','address_snapshot','courier',
        'courier_service','shipping_cost','tracking_number','high_res_print_url',
        'crop_config','status','shipped_at','delivered_at',
    ];
    protected $casts = ['address_snapshot'=>'array','crop_config'=>'array','shipped_at'=>'datetime','delivered_at'=>'datetime'];
    protected static function booted(): void {
        static::creating(fn($m) => $m->uuid ??= (string) Str::uuid());
    }
    public function user() { return $this->belongsTo(User::class); }
    public function order() { return $this->belongsTo(Order::class); }
}
