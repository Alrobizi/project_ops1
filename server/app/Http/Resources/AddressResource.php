<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AddressResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'governorate' => $this->governorate ?? 'عدن',
            'city' => $this->city,
            'district' => $this->district,
            'street' => $this->street,
            'phone' => $this->phone,
            'is_default' => $this->is_default,
            // [الموقع الجغرافي] إحداثيات المشتري (GPS أو الخريطة)
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'is_gps_location' => (bool) $this->is_gps_location,
            'full_address' => $this->full_address,
        ];
    }
}
