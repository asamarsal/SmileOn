<?php namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;
class UserCollectible extends Model {
    protected $fillable = ['uuid','user_id','collection_id','strip_id','token_id','metadata_uri','traits','tx_hash','mint_tx_hash','status','minted_at'];
    protected $casts = ['traits'=>'array','minted_at'=>'datetime'];
    protected static function booted(): void {
        static::creating(fn($c) => $c->uuid ??= (string) Str::uuid());
    }
    public function user() { return $this->belongsTo(User::class); }
    public function collection() { return $this->belongsTo(NftCollection::class); }
    public function strip() { return $this->belongsTo(PhotoStrip::class,'strip_id'); }
}
