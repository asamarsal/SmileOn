<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SystemPricingSetting extends Model
{
    protected $table = 'system_pricing_settings';

    protected $fillable = [
        'key',
        'label',
        'category',
        'value_idr',
        'value_usd',
        'crypto_value',
        'description',
    ];

    protected $casts = [
        'value_idr' => 'decimal:2',
        'value_usd' => 'decimal:2',
    ];

    /**
     * Helper untuk mengambil value IDR atau USD berdasarkan key
     */
    public static function getPrice(string $key, string $currency = 'IDR'): float
    {
        $setting = static::where('key', $key)->first();
        if (!$setting) {
            return 0.0;
        }

        return strtoupper($currency) === 'USD'
            ? (float) $setting->value_usd
            : (float) $setting->value_idr;
    }
}
