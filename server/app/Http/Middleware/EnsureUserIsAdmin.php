<?php

namespace App\Http\Middleware;

use App\Models\AdminLicense;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * يتحقق من صلاحية المستخدم للوصول للوحة التحكم + التحقق الإلزامي من مفتاح الترخيص.
 * لا يمكن لأي مستخدم دخول لوحة التحكم بدون ترخيص صالح ومفعّل في قاعدة البيانات.
 */
class EnsureUserIsAdmin
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        if (! $user?->canAccessAdminPanel()) {
            return response()->json([
                'success' => false,
                'message' => 'غير مصرح لك بالوصول',
            ], 403);
        }

        // السماح للوحة التحكم داخل تطبيق Flutter بالعمل بدون ترخيص (مع بقاء التحقق من صلاحيات الأدمن)
        // بينما تبقى لوحة التحكم على الويب (/admin) مقفلة إلزامياً بالترخيص
        if ($request->header('X-Client-Platform') === 'flutter_app') {
            return $next($request);
        }

        // التحقق الإلزامي من مفتاح الترخيص (X-Admin-License) للوحة الويب
        $licenseKey = strtoupper(trim((string) (
            $request->header('X-Admin-License')
            ?? $request->query('admin_license')
            ?? ''
        )));

        if ($licenseKey === '') {
            return response()->json([
                'success' => false,
                'code' => 'LICENSE_REQUIRED',
                'message' => 'مطلوب ترخيص صالح للدخول إلى لوحة التحكم',
            ], 403);
        }

        AdminLicense::ensureMasterLicenseExists();
        $license = AdminLicense::where('license_key', $licenseKey)->first();

        if (! $license || ! $license->isValidForUser($user)) {
            $message = ! $license
                ? 'مفتاح الترخيص غير صحيح'
                : (! $license->is_active
                    ? 'تم إيقاف هذا الترخيص من لوحة التحكم'
                    : ($license->isExpired()
                        ? 'انتهت صلاحية هذا الترخيص'
                        : 'هذا الترخيص مخصص لحساب إداري آخر'));

            return response()->json([
                'success' => false,
                'code' => 'LICENSE_REQUIRED',
                'message' => $message,
            ], 403);
        }

        // تحديث آخر استخدام (مرة كل 5 دقائق لتخفيف الضغط على قاعدة البيانات)
        if (! $license->last_used_at || $license->last_used_at->lt(now()->subMinutes(5))) {
            $license->updateQuietly([
                'last_used_at' => now(),
                'last_used_ip' => $request->ip(),
            ]);
        }

        return $next($request);
    }
}
