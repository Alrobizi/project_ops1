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
            'city' => $this->city,
            'district' => $this->district,
            'street' => $this->street,
            'phone' => $this->phone,
            'is_default' => $this->is_default,
            'full_address' => $this->full_address,
        ];
    }
}
