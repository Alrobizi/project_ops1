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
            'created_at' => $this->created_at?->toISOString(),
        ];
    }
}
