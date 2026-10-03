<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureUserCanManageProducts
{
    /**
     * يسمح فقط لمستخدم لديه صلاحية "المنتجات" الممنوحة صراحةً.
     * (الأدمن افتراضياً بدون صلاحيات)
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (! $user || ! $user->canAccessAdminPanel() || ! $user->canManageProducts()) {
            return response()->json([
                'success' => false,
                'message' => 'ليس لديك صلاحية إدارة المنتجات',
            ], 403);
        }

        return $next($request);
    }
}
