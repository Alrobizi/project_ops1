<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Category extends Model
{
    protected $fillable = [
        'name',
        'slug',
        'icon',
        'image',
        'sort_order',
        'is_active',
        'parent_id',
        'type',
        'badge',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
        ];
    }

    public function parent(): BelongsTo
    {
        return $this->belongsTo(Category::class, 'parent_id');
    }

    public function children(): HasMany
    {
        return $this->hasMany(Category::class, 'parent_id')->orderBy('sort_order');
    }

    public function activeChildren(): HasMany
    {
        return $this->children()->where('is_active', true);
    }

    public function products(): HasMany
    {
        return $this->hasMany(Product::class);
    }

    public function scopeMainCategories($query)
    {
        return $query->whereNull('parent_id')->where('type', 'main')->where('is_active', true);
    }

    public function scopeMarketingSections($query)
    {
        return $query->where('type', 'marketing')->where('is_active', true);
    }

    public function getIsMainCategoryAttribute(): bool
    {
        return $this->type === 'main' && $this->parent_id === null;
    }

    public function getIsSubcategoryAttribute(): bool
    {
        return $this->type === 'sub' || $this->parent_id !== null;
    }

    public function getIsMarketingAttribute(): bool
    {
        return $this->type === 'marketing';
    }
}
