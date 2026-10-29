<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProductResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'description' => $this->description,
            'price' => (float) $this->price,
            'old_price' => $this->old_price ? (float) $this->old_price : null,
            'currency' => $this->currency ?? 'SAR',
            'currency_symbol' => $this->currency_symbol,
            'image' => $this->image_url,
            'images' => $this->whenLoaded('images', fn () => $this->images->pluck('url')->toArray(), []),
            'category_id' => $this->category_id,
            'category' => new CategoryResource($this->whenLoaded('category')),
            'rating' => (float) $this->rating,
            'reviews_count' => $this->reviews_count,
            'stock' => $this->stock,
            'colors' => $this->colors ?? [],
            'sizes' => $this->sizes ?? [],
            'is_featured' => $this->is_featured,
            'is_best_seller' => $this->is_featured,
            // [الموقع الجغرافي] موقع البائع (الافتراضي: عدن - كريتر)
            'seller_name' => $this->seller_name ?? 'متجر بركة عدن',
            'seller_governorate' => $this->seller_governorate ?? 'عدن',
            'seller_city' => $this->seller_city ?? 'كريتر',
            'seller_latitude' => (float) ($this->seller_latitude ?? 12.7917),
            'seller_longitude' => (float) ($this->seller_longitude ?? 45.0067),
            'created_at' => $this->created_at?->toISOString(),
        ];
    }
}
