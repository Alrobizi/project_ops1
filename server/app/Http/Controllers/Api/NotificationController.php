<?php

namespace App\Http\Controllers\Api;

use App\Models\NotificationLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends BaseApiController
{
    /**
     * جلب سجل إشعارات المستخدم الحالي مع عداد غير المقروء
     */
    public function index(Request $request): JsonResponse
    {
        $notifications = NotificationLog::where('user_id', $request->user()->id)
            ->latest()
            ->paginate(20);

        $unreadCount = NotificationLog::where('user_id', $request->user()->id)
            ->whereNull('read_at')
            ->count();

        return response()->json([
            'success' => true,
            'data' => $notifications->items(),
            'unread_count' => $unreadCount,
            'meta' => [
                'current_page' => $notifications->currentPage(),
                'last_page' => $notifications->lastPage(),
                'total' => $notifications->total(),
            ],
            'message' => 'تم جلب الإشعارات بنجاح',
        ]);
    }

    /**
     * تعليم إشعار كمقروء
     */
    public function markAsRead(Request $request, int $id): JsonResponse
    {
        $notification = NotificationLog::where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        $notification->update(['read_at' => now()]);

        return $this->success(null, 'تم تعليم الإشعار كمقروء');
    }

    /**
     * تعليم جميع الإشعارات كمقروءة
     */
    public function markAllAsRead(Request $request): JsonResponse
    {
        NotificationLog::where('user_id', $request->user()->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return $this->success(null, 'تم تعليم جميع الإشعارات كمقروءة');
    }
}
