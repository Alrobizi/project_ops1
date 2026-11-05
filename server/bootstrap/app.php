<?php

use App\Http\Middleware\EnsureAdminPermission;
use App\Http\Middleware\EnsureUserCanManageProducts;
use App\Http\Middleware\EnsureUserIsAdmin;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias([
            'admin' => EnsureUserIsAdmin::class,
            'product.manager' => EnsureUserCanManageProducts::class,
            'permission' => EnsureAdminPermission::class,
        ]);

        // هذا التطبيق API فقط (لوحة Filament على /filament/login ولا يوجد مسار login للواجهة).
        // القيمة الافتراضية في Laravel 12 هي fn () => route('login')، وبما أن المسار غير موجود
        // فإن middleware "auth" يرمي RouteNotFoundException (500) قبل أن يصل استثناء
        // المصادقة إلى معالج الاستثناءات، أي قبل أن يُطبَّق shouldRenderJsonWhen أدناه.
        $middleware->redirectGuestsTo('/filament/login');
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // مسارات /api تُرجع JSON دائماً حتى لو لم يرسل العميل ترويسة Accept،
        // وإلا يحاول Laravel التحويل إلى مسار login غير الموجود فيرد 500 بدل 401.
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request, Throwable $e): bool => $request->is('api/*') || $request->expectsJson()
        );
    })->create();
