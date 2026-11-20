<?php

namespace App\Http\Controllers\Api;

use App\Models\AdminLicense;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminLicenseController extends BaseApiController
{
    /**
     * التحقق من مفتاح الترخيص قبل فتح لوحة التحكم (يستدعى بعد تسجيل دخول الأدمن)
     */
    public function verify(Request $request): JsonResponse
    {
        $user = $request->user();
        if (! $user || ! $user->canAccessAdminPanel()) {
            return $this->error('هذا الحساب غير مصرح له بدخول لوحة التحكم', 403);
        }

        $key = strtoupper(trim((string) (
            $request->input('license_key')
            ?? $request->header('X-Admin-License')
            ?? ''
        )));

        if ($key === '') {
            return response()->json([
                'success' => false,
                'code' => 'LICENSE_REQUIRED',
                'message' => 'الرجاء إدخال مفتاح الترخيص للدخول إلى لوحة التحكم',
            ], 403);
        }

        AdminLicense::ensureMasterLicenseExists();

        $license = AdminLicense::where('license_key', $key)->first();
        if (! $license) {
            return response()->json([
                'success' => false,
                'code' => 'LICENSE_INVALID',
                'message' => 'مفتاح الترخيص غير صحيح',
            ], 403);
        }

        if (! $license->is_active) {
            return response()->json([
                'success' => false,
                'code' => 'LICENSE_REVOKED',
                'message' => 'تم إيقاف هذا الترخيص من لوحة التحكم',
            ], 403);
        }

        if ($license->isExpired()) {
            return response()->json([
                'success' => false,
                'code' => 'LICENSE_EXPIRED',
                'message' => 'انتهت صلاحية هذا الترخيص',
            ], 403);
        }

        if (! $license->isValidForUser($user)) {
            return response()->json([
                'success' => false,
                'code' => 'LICENSE_USER_MISMATCH',
                'message' => 'هذا الترخيص مخصص لحساب إداري آخر',
            ], 403);
        }

        $license->update([
            'last_used_at' => now(),
            'last_used_ip' => $request->ip(),
        ]);

        return $this->success([
            'id' => $license->id,
            'license_key' => $license->license_key,
            'label' => $license->label,
            'is_master' => (bool) $license->is_master,
            'expires_at' => $license->expires_at?->toISOString(),
        ], 'تم التحقق من الترخيص بنجاح');
    }

    /**
     * عرض جميع التراخيص داخل لوحة التحكم
     */
    public function index(): JsonResponse
    {
        AdminLicense::ensureMasterLicenseExists();

        $licenses = AdminLicense::with(['user:id,name,email', 'creator:id,name'])
            ->orderByDesc('is_master')
            ->latest()
            ->get()
            ->map(fn (AdminLicense $l) => [
                'id' => $l->id,
                'license_key' => $l->license_key,
                'label' => $l->label,
                'is_active' => (bool) $l->is_active,
                'is_master' => (bool) $l->is_master,
                'is_expired' => $l->isExpired(),
                'user_id' => $l->user_id,
                'user_name' => $l->user?->name,
                'user_email' => $l->user?->email,
                'created_by_name' => $l->creator?->name,
                'expires_at' => $l->expires_at?->toISOString(),
                'last_used_at' => $l->last_used_at?->toISOString(),
                'last_used_ip' => $l->last_used_ip,
                'created_at' => $l->created_at?->toISOString(),
            ]);

        return $this->success($licenses, 'تم جلب التراخيص بنجاح');
    }

    /**
     * إصدار ترخيص جديد من داخل لوحة التحكم
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'label' => ['required', 'string', 'max:150'],
            'license_key' => ['nullable', 'string', 'min:6', 'max:80', 'unique:admin_licenses,license_key'],
            'user_id' => ['nullable', 'exists:users,id'],
            'expires_at' => ['nullable', 'date'],
        ]);

        $key = ! empty($validated['license_key'])
            ? strtoupper(trim($validated['license_key']))
            : AdminLicense::generateKey();

        $license = AdminLicense::create([
            'license_key' => $key,
            'label' => $validated['label'],
            'user_id' => $validated['user_id'] ?? null,
            'is_active' => true,
            'is_master' => false,
            'expires_at' => $validated['expires_at'] ?? null,
            'created_by' => $request->user()->id,
        ]);

        return $this->success($license, 'تم إصدار الترخيص الجديد بنجاح', 201);
    }

    /**
     * تفعيل أو إيقاف ترخيص فوراً
     */
    public function toggle(int $id): JsonResponse
    {
        $license = AdminLicense::findOrFail($id);

        if ($license->is_master && $license->is_active) {
            $otherActive = AdminLicense::where('id', '!=', $license->id)
                ->where('is_active', true)
                ->exists();
            if (! $otherActive) {
                return $this->error('لا يمكن إيقاف الترخيص الرئيسي وهو الترخيص النشط الوحيد', 422);
            }
        }

        $license->update(['is_active' => ! $license->is_active]);

        return $this->success(
            $license->fresh(),
            $license->is_active ? 'تم تفعيل الترخيص بنجاح' : 'تم إيقاف الترخيص فوراً'
        );
    }

    /**
     * حذف ترخيص غير رئيسي
     */
    public function destroy(int $id): JsonResponse
    {
        $license = AdminLicense::findOrFail($id);

        if ($license->is_master) {
            return $this->error('لا يمكن حذف الترخيص الرئيسي', 422);
        }

        $license->delete();

        return $this->success(null, 'تم حذف الترخيص بنجاح');
    }
}
