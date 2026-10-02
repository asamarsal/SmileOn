<?php namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class UserShippingAddress extends Model {
    protected $fillable = ['user_id','label','recipient_name','phone_number','address_line1','address_line2','village','district','city','province','postal_code','is_default'];
    protected $casts = ['is_default'=>'boolean'];
    public function user() { return $this->belongsTo(User::class); }
}
