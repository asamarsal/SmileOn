<?php namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
class FrameReport extends Model {
    protected $fillable = ['frame_id','reporter_id','reason','notes','status'];
    public function frame(): BelongsTo { return $this->belongsTo(Frame::class); }
    public function reporter(): BelongsTo { return $this->belongsTo(User::class,'reporter_id'); }
}
