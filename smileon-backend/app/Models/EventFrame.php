<?php namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class EventFrame extends Model {
    public $timestamps = false;
    protected $fillable = ['event_id','frame_id','slot_index','is_custom','custom_frame_url'];
    protected $casts = ['is_custom'=>'boolean'];
    public function event() { return $this->belongsTo(Event::class); }
    public function frame() { return $this->belongsTo(Frame::class); }
}
