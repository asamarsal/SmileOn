<?php namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;
class Order extends Model {
    use SoftDeletes;
    protected $fillable = [
        'uuid','order_number','user_id','payment_method_id','voucher_id',
        'subtotal','discount_amount','admin_fee','total','currency',
        'status','type','payment_details','paid_at','expired_at',
    ];
    protected $casts = ['payment_details'=>'array','paid_at'=>'datetime','expired_at'=>'datetime'];
    protected static function booted(): void {
        static::creating(function(Order $o) {
            $o->uuid ??= (string) Str::uuid();
            $o->order_number ??= 'SO-ORD-' . strtoupper(Str::random(6));
        });
    }
    public function user() { return $this->belongsTo(User::class); }
    public function paymentMethod() { return $this->belongsTo(PaymentMethod::class); }
    public function voucher() { return $this->belongsTo(Voucher::class); }
    public function items() { return $this->hasMany(OrderItem::class); }
}
