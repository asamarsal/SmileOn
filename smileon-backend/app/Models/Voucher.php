<?php namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
class Voucher extends Model {
    use SoftDeletes;
    protected $fillable = [
        'code','name','description','type','value','discount_strip_pct',
        'free_strip_copies','max_uses','used_count','valid_from','valid_until','is_active',
    ];
    protected $casts = ['valid_from'=>'datetime','valid_until'=>'datetime','is_active'=>'boolean'];
    public function isValid(): bool {
        if (!$this->is_active) return false;
        if ($this->valid_from && now()->lt($this->valid_from)) return false;
        if ($this->valid_until && now()->gt($this->valid_until)) return false;
        if ($this->max_uses && $this->used_count >= $this->max_uses) return false;
        return true;
    }
}
