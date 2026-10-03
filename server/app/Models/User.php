<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Filament\Models\Contracts\FilamentUser;
use Filament\Panel;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable implements FilamentUser
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'phone',
        'role',
        'admin_permissions',
        'is_blocked',
        'password',
        'fcm_token',
        'google_id',
        'avatar',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'is_blocked' => 'boolean',
            'admin_permissions' => 'array',
        ];
    }

    /// مفاتيح صلاحيات لوحة التحكم المتاحة
    public const ADMIN_PERMISSIONS = [
        'products',
        'orders',
        'customers',
        'discounts',
        'reports',
        'content',
        'marketing',
        'settings',
        'users',
    ];

    /// أسماء الصلاحيات بالعربية (تُستخدم في لوحة Filament)
    public const ADMIN_PERMISSIONS_LABELS = [
        'products' => 'المنتجات',
        'orders' => 'الطلبات',
        'customers' => 'العملاء',
        'discounts' => 'الخصومات',
        'reports' => 'التقارير',
        'content' => 'المحتوى',
        'marketing' => 'التسويق',
        'settings' => 'الإعدادات',
        'users' => 'المستخدمون',
    ];

    public function canAccessPanel(Panel $panel): bool
    {
        return $this->role === 'admin' && ! $this->is_blocked;
    }

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    /**
     * هل يملك المستخدم صلاحية معينة على لوحة التحكم؟
     * الأدمن افتراضياً بدون أي صلاحيات — لا يمكنه الوصول لقسم
     * إلا إذا مُنح ذلك القسم صراحةً في admin_permissions.
     */
    public function hasAdminPermission(string $permission): bool
    {
        if (! $this->isAdmin()) {
            return false;
        }

        $permissions = $this->admin_permissions ?? [];

        return in_array($permission, $permissions);
    }

    /**
     * كل صلاحيات الأدمن (تُمنح صراحةً — لا يوجد وصول كامل تلقائي).
     */
    public function hasAllAdminPermissions(): bool
    {
        if (! $this->isAdmin()) {
            return false;
        }

        $permissions = $this->admin_permissions ?? [];

        return collect(User::ADMIN_PERMISSIONS)->every(
            fn ($p) => in_array($p, $permissions)
        );
    }

    public function canAccessAdminPanel(): bool
    {
        return $this->isAdmin() && ! $this->is_blocked;
    }

    /// صلاحية إدارة المنتجات (إضافة/تعديل/تصنيف المنتجات وأسعارها)
    public function canManageProducts(): bool
    {
        return $this->hasAdminPermission('products');
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    public function addresses(): HasMany
    {
        return $this->hasMany(Address::class);
    }
}
