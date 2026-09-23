<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * يتحقق من صلاحية المستخدم للوصول للوحة التحكم.
 * مستخدم بصلاحيات فارغة/null = وصول كامل لكل الأقسام.
 */
class EnsureUserIsAdmin
{
    public function handle(Request $request, Closure $next): Response
    {
        if (! $request->user()?->canAccessAdminPanel()) {
            return response()->json([
                'success' => false,
                'message' => 'غير مصرح لك بالوصول',
            ], 403);
        }

        return $next($request);
    }
}
