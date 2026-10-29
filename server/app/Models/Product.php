<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\Storage;

class Product extends Model
{
    public const LOW_STOCK_THRESHOLD = 10;

    public const CURRENCIES = [
        'SAR' => 'ريال سعودي (ر.س)',
        'YER' => 'ريال يمني (ر.ي)',
    ];

    protected $fillable = [
        'category_id',
        'name',
        'description',
        'price',
        'old_price',
        'currency',
        'image',
        'stock',
        'rating',
        'reviews_count',
        'colors',
        'sizes',
        'is_featured',
        'is_active',
        // [الموقع الجغرافي] موقع البائع (الافتراضي: متجر بركة عدن - كريتر)
        'seller_name',
        'seller_governorate',
        'seller_city',
        'seller_latitude',
        'seller_longitude',
    ];

    protected function casts(): array
    {
        return [
            'price' => 'decimal:2',
            'old_price' => 'decimal:2',
            'rating' => 'decimal:1',
            'colors' => 'array',
            'sizes' => 'array',
            'is_featured' => 'boolean',
            'is_active' => 'boolean',
            'seller_latitude' => 'double',
            'seller_longitude' => 'double',
        ];
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function images(): HasMany
    {
        return $this->hasMany(ProductImage::class)->orderBy('sort_order');
    }

    public function orderItems(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    public function getStockStatusAttribute(): string
    {
        if ($this->stock <= 0) {
            return 'out_of_stock';
        }

        if ($this->stock < self::LOW_STOCK_THRESHOLD) {
            return 'low_stock';
        }

        return 'in_stock';
    }

    public function getCurrencySymbolAttribute(): string
    {
        return $this->currency === 'YER' ? 'ر.ي' : 'ر.س';
    }

    public function getImageUrlAttribute(): ?string
    {
        if (! $this->image) {
            return null;
        }

        return str_starts_with($this->image, 'http')
            ? $this->image
            : Storage::disk('public')->url($this->image);
    }
}
