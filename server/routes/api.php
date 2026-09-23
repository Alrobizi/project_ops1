<?php

use App\Http\Controllers\Api\AddressController;
use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\AdminProductController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BannerController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\PaymentWebhookController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Support\Facades\Route;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/google-login', [AuthController::class, 'googleLogin']);

// Webhook استقبال نتيجة الدفع من بوابة المحفظة
Route::post('/webhooks/payment', [PaymentWebhookController::class, 'handleWebhook']);

Route::get('/categories', [CategoryController::class, 'index']);
Route::get('/categories/marketing', [CategoryController::class, 'marketing']);
Route::get('/categories/{category}', [CategoryController::class, 'show']);
Route::get('/products', [ProductController::class, 'index']);
Route::get('/products/{product}', [ProductController::class, 'show']);
Route::get('/banners', [BannerController::class, 'index']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/user', [UserController::class, 'show']);
    Route::put('/user', [UserController::class, 'update']);
    Route::post('/user/fcm-token', [UserController::class, 'updateFcmToken']);

    // مسارات المدفوعات والـ Webhook للمحاكي
    Route::post('/payments/initiate', [PaymentWebhookController::class, 'initiatePayment']);
    Route::post('/payments/mock-webhook', [PaymentWebhookController::class, 'mockWebhook']);
    Route::get('/orders/{order}/status', [PaymentWebhookController::class, 'getOrderStatus']);
    Route::post('/orders/{order}/switch-to-cod', [PaymentWebhookController::class, 'switchToCod']);

    Route::get('/orders', [OrderController::class, 'index']);
    Route::get('/orders/{order}', [OrderController::class, 'show']);
    Route::post('/orders', [OrderController::class, 'store']);

    // مسارات سجل إشعارات العميل
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::patch('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
    Route::post('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);

    Route::get('/addresses', [AddressController::class, 'index']);
    Route::post('/addresses', [AddressController::class, 'store']);

    // ============================================
    // مسارات لوحة التحكم (Admin Routes)
    // ============================================
    Route::middleware('admin')->group(function () {

    // لوحة التحكم - الإحصائيات
    Route::get('/admin/dashboard', [AdminController::class, 'dashboard']);
    Route::get('/admin/reports', [AdminController::class, 'reports']);

    // العملاء
    Route::get('/admin/customers', [AdminController::class, 'customers']);
    Route::patch('/admin/customers/{id}/toggle', [AdminController::class, 'toggleCustomerStatus']);

    // الحملات التسويقية
    Route::get('/admin/campaigns', [AdminController::class, 'campaigns']);
    Route::post('/admin/campaigns', [AdminController::class, 'storeCampaign']);
    Route::delete('/admin/campaigns/{id}', [AdminController::class, 'destroyCampaign']);

    // الخصومات
    Route::get('/admin/discounts', [AdminController::class, 'discounts']);
    Route::post('/admin/discounts', [AdminController::class, 'storeDiscount']);
    Route::delete('/admin/discounts/{id}', [AdminController::class, 'destroyDiscount']);
    Route::patch('/admin/discounts/{id}/toggle', [AdminController::class, 'toggleDiscount']);

    // البانرات
    Route::get('/admin/banners', [AdminController::class, 'banners']);
    Route::post('/admin/banners', [AdminController::class, 'storeBanner']);
    Route::delete('/admin/banners/{id}', [AdminController::class, 'destroyBanner']);
    Route::patch('/admin/banners/{id}/toggle', [AdminController::class, 'toggleBanner']);

    // الصفحات
    Route::get('/admin/pages', [AdminController::class, 'pages']);
    Route::post('/admin/pages', [AdminController::class, 'storePage']);
    Route::delete('/admin/pages/{id}', [AdminController::class, 'destroyPage']);

    // الإشعارات
    Route::get('/admin/notifications', [AdminController::class, 'notifications']);
    Route::post('/admin/notifications', [AdminController::class, 'storeNotification']);
    Route::delete('/admin/notifications/{id}', [AdminController::class, 'destroyNotification']);

    // الأسئلة الشائعة
    Route::get('/admin/faqs', [AdminController::class, 'faqs']);
    Route::post('/admin/faqs', [AdminController::class, 'storeFaq']);
    Route::delete('/admin/faqs/{id}', [AdminController::class, 'destroyFaq']);

    // الإعدادات
    Route::get('/admin/settings', [AdminController::class, 'settings']);
    Route::put('/admin/settings', [AdminController::class, 'updateSettings']);

    // ============================================
    // إدارة المنتجات والتصنيفات (صلاحية: products)
    // ============================================
    Route::middleware('product.manager')->group(function () {
        Route::get('/admin/products', [AdminProductController::class, 'index']);
        Route::post('/admin/products', [AdminProductController::class, 'store']);
        Route::put('/admin/products/{product}', [AdminProductController::class, 'update']);
        Route::delete('/admin/products/{product}', [AdminProductController::class, 'destroy']);

        Route::get('/admin/categories', [AdminProductController::class, 'categories']);
        Route::post('/admin/categories', [AdminProductController::class, 'storeCategory']);
        Route::put('/admin/categories/{category}', [AdminProductController::class, 'updateCategory']);
        Route::delete('/admin/categories/{category}', [AdminProductController::class, 'destroyCategory']);
    });
    });
});