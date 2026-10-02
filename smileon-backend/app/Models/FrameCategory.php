<?php namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
class FrameCategory extends Model {
    protected $fillable = ['name','slug','icon','badge_label','is_active','sort_order'];
    protected $casts = ['is_active'=>'boolean'];
    public function frames() { return $this->hasMany(Frame::class,'category_id'); }
}
