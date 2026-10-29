<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Address extends Model
{
    protected $fillable = [
        'user_id',
        'governorate',
        'city',
        'district',
        'street',
        'phone',
        'is_default',
        'latitude',
        'longitude',
        'is_gps_location',
    ];

    protected function casts(): array
    {
        return [
            'is_default' => 'boolean',
            'is_gps_location' => 'boolean',
            'latitude' => 'double',
            'longitude' => 'double',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function getFullAddressAttribute(): string
    {
        return "{$this->governorate}، {$this->city}، {$this->district}، {$this->street}";
    }

    /**
     * [الموقع الجغرافي] حساب المسافة بالكيلومترات بين موقع المشتري
     * وموقع البائع (صيغة Haversine) لتقدير تكلفة وزمن التوصيل.
     */
    public function distanceToSeller(?Product $product = null): ?float
    {
        if (is_null($this->latitude) || is_null($this->longitude)) {
            return null;
        }

        $sellerLat = $product->seller_latitude ?? 12.7917; // عدن - كريتر
        $sellerLng = $product->seller_longitude ?? 45.0067;

        $earthRadiusKm = 6371.0;

        $dLat = deg2rad($sellerLat - $this->latitude);
        $dLng = deg2rad($sellerLng - $this->longitude);

        $a = sin($dLat / 2) ** 2
            + cos(deg2rad($this->latitude)) * cos(deg2rad($sellerLat))
            * sin($dLng / 2) ** 2;

        return $earthRadiusKm * 2 * asin(min(1.0, sqrt($a)));
    }
}
