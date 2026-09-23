<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AdminNotification extends Model
{
    protected $fillable = [
        'title',
        'body',
        'type',
        'is_sent',
    ];

    protected $casts = [
        'is_sent' => 'boolean',
    ];
}