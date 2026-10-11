<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Package extends Model
{
    protected $fillable = [
        'name',
        'description',
        'category',
        'credits_amount',
        'price',        // IDR price default
        'price_usd',    // USD price
        'crypto_price', // e.g. "1.00 MON"
        'currency',
        'badge_label',
        'is_active',
        'sort_order',
    ];

    protected $casts = [
        'is_active'  => 'boolean',
        'price'      => 'decimal:2',
        'price_usd'  => 'decimal:2',
        'sort_order' => 'integer',
    ];

    /**
     * Dapatkan harga berdasarkan mata uang yang diminta (IDR / USD)
     */
    public function getPriceForCurrency(string $currency = 'IDR'): float
    {
        if (strtoupper($currency) === 'USD' && $this->price_usd) {
            return (float) $this->price_usd;
        }

        return (float) $this->price;
    }
}
