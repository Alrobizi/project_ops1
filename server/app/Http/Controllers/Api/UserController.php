<?php

namespace App\Http\Controllers\Api;

use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class UserController extends BaseApiController
{
    public function show(Request $request): JsonResponse
    {
        return $this->success(new UserResource($request->user()));
    }

    public function update(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'phone' => ['sometimes', 'string', 'max:20'],
            'email' => ['sometimes', 'email', Rule::unique('users')->ignore($user->id)],
            'password' => ['sometimes', 'string', 'min:6', 'confirmed'],
        ]);

        if (isset($validated['password'])) {
            $validated['password'] = Hash::make($validated['password']);
        }

        $user->update($validated);

        return $this->success(new UserResource($user->fresh()), 'تم تحديث الملف الشخصي بنجاح');
    }

    /**
     * تسجيل/تحديث توكن FCM للمستخدم الحالي
     */
    public function updateFcmToken(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'fcm_token' => ['required', 'string', 'max:500'],
        ]);

        // توكن FCM فريد للجهاز، فلا يجوز أن يبقى مربوطاً بحسابين.
        // يفصل التوكن عن أي حساب آخر (مثلاً خرج المستخدم السابق دون اتصال،
        // فلم يصل طلب الحذف إلى الخادم) قبل ربطه بالحساب الحالي، وإلا وصلت
        // إشعارات الحساب القديم إلى من يستخدم الجهاز الآن.
        User::where('fcm_token', $validated['fcm_token'])
            ->where('id', '!=', $request->user()->getKey())
            ->update(['fcm_token' => null]);

        $request->user()->update(['fcm_token' => $validated['fcm_token']]);

        return $this->success(null, 'تم تسجيل توكن الإشعارات بنجاح');
    }

    /**
     * فصل جهاز المستخدم الحالي عن إشعاراته (عند تسجيل الخروج)
     */
    public function clearFcmToken(Request $request): JsonResponse
    {
        $request->user()->update(['fcm_token' => null]);

        return $this->success(null, 'تم إلغاء تسجيل جهاز الإشعارات');
    }
}
