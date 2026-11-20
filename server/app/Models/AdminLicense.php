<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class AdminLicense extends Model
{
    protected $fillable = [
        'license_key',
        'label',
        'user_id',
        'is_active',
        'is_master',
        'expires_at',
        'last_used_at',
        'last_used_ip',
        'created_by',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'is_master' => 'boolean',
            'expires_at' => 'datetime',
            'last_used_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function isExpired(): bool
    {
        return $this->expires_at !== null && now()->greaterThan($this->expires_at);
    }

    public function isValidForUser(?User $user): bool
    {
        if (! $this->is_active || $this->isExpired()) {
            return false;
        }

        if ($this->user_id !== null && (! $user || $this->user_id !== $user->id)) {
            return false;
        }

        return true;
    }

    /**
     * توليد مفتاح ترخيص عشوائي آمن بنمط BRK-XXXX-XXXX-XXXX
     */
    public static function generateKey(): string
    {
        do {
            $key = sprintf(
                'BRK-%s-%s-%s',
                strtoupper(Str::random(4)),
                strtoupper(Str::random(4)),
                strtoupper(Str::random(4))
            );
        } while (self::where('license_key', $key)->exists());

        return $key;
    }

    /**
     * ضمان وجود الترخيص الرئيسي دائماً (في حال تم تفريغ الجدول أو قبل تشغيل السيدر)
     */
    public static function ensureMasterLicenseExists(): self
    {
        $master = self::where('is_master', true)->first();
        if ($master) {
            return $master;
        }

        $masterKey = strtoupper(trim((string) env('ADMIN_MASTER_LICENSE_KEY', 'BRK-ADEN-2026-MASTER')));
        return self::firstOrCreate(
            ['license_key' => $masterKey],
            [
                'label' => 'الترخيص الرئيسي (المالك)',
                'is_active' => true,
                'is_master' => true,
            ]
        );
    }
}
