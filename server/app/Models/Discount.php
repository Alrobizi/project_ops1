<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Discount extends Model
{
    protected $fillable = [
        'code',
        'type',
        'value',
        'min_order',
        'used_count',
        'max_usage',
        'status',
        'start_date',
        'end_date',
    ];

    protected $casts = [
        'value' => 'decimal:2',
        'min_order' => 'decimal:2',
        'used_count' => 'integer',
        'max_usage' => 'integer',
        'start_date' => 'date',
        'end_date' => 'date',
    ];
}