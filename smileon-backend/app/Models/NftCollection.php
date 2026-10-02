<?php namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class NftCollection extends Model {
    protected $fillable = ['name','contract_address','contract_type','chain_id','abi','is_active'];
    protected $casts = ['abi'=>'array','is_active'=>'boolean'];
}
