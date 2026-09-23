<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Order extends Model
{
    public const STATUSES = [
        'pending' => 'قيد المعالجة',
        'processing' => 'قيد التجهيز',
        'shipped' => 'قيد الشحن',
        'delivered' => 'مكتمل',
        'cancelled' => 'ملغي',
    ];

    protected $fillable = [
        'order_number',
        'user_id',
        'address_id',
        'subtotal',
        'shipping',
        'total',
        'status',
        'payment_method',
        'payment_status',
        'wallet_name',
        'payment_expires_at',
    ];

    protected function casts(): array
    {
        return [
            'subtotal' => 'decimal:2',
            'shipping' => 'decimal:2',
            'total' => 'decimal:2',
            'payment_expires_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function address(): BelongsTo
    {
        return $this->belongsTo(Address::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    public function getItemsCountAttribute(): int
    {
        return (int) $this->items->sum('quantity');
    }

    public function getStatusLabelAttribute(): string
    {
        return self::STATUSES[$this->status] ?? $this->status;
    }

    public static function generateOrderNumber(): string
    {
        return 'ORD-'.now()->format('Y').'-'.str_pad((string) (static::max('id') + 1), 5, '0', STR_PAD_LEFT);
    }
}
