<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class OrderResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'order_number' => $this->order_number,
            'date' => $this->created_at?->toISOString(),
            'items' => OrderItemResource::collection($this->whenLoaded('items')),
            'items_count' => $this->whenLoaded('items', fn () => (int) $this->items->sum('quantity')),
            'subtotal' => (float) $this->subtotal,
            'discount_amount' => (float) ($this->discount_amount ?? 0),
            'coupon_code' => $this->coupon_code,
            'shipping' => (float) $this->shipping,
            'total' => (float) $this->total,
            'status' => $this->status,
            'status_label' => $this->status_label,
            'address' => new AddressResource($this->whenLoaded('address')),
            'payment_method' => $this->payment_method,
            'order_type' => $this->wallet_name ?? $this->payment_method,
            'notes' => $this->notes,
        ];
    }
}
