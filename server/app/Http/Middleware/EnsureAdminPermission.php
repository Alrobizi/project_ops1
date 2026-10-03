<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * يتحقق من ملكية المستخدم صلاحية قسم معين في لوحة التحكم.
 * الاستخدام: Route::middleware('permission:customers')
 * الأدمن افتراضياً بدون صلاحيات — تُمنح صراحةً فقط.
 */
class EnsureAdminPermission
{
    public function handle(Request $request, Closure $next, string $permission): Response
    {
        $user = $request->user();

        if (! $user || ! $user->canAccessAdminPanel() || ! $user->hasAdminPermission($permission)) {
            return response()->json([
                'success' => false,
                'message' => 'ليس لديك صلاحية الوصول لهذا القسم',
            ], 403);
        }

        return $next($request);
    }
}
