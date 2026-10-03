<?php

namespace App\Filament\Concerns;

/**
 * يقيّد الوصول لموارد لوحة Filament حسب صلاحيات المستخدم.
 * كل مورد يعرّف static::$adminPermission بمفتاح الصلاحية المطلوبة.
 * (الأدمن افتراضياً بدون صلاحيات — تُمنح صراحةً فقط)
 */
trait RestrictsByAdminPermission
{
    public static function canAccess(): bool
    {
        $permission = static::$adminPermission ?? null;

        if ($permission === null) {
            return true;
        }

        return auth()->user()?->hasAdminPermission($permission) ?? false;
    }
}
