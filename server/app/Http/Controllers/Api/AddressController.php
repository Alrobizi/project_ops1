<?php

namespace App\Http\Controllers\Api;

use App\Http\Resources\AddressResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AddressController extends BaseApiController
{
    public function index(Request $request): JsonResponse
    {
        $addresses = $request->user()->addresses()->latest()->get();

        return $this->success(AddressResource::collection($addresses));
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'governorate' => ['sometimes', 'string', 'max:100'],
            'city' => ['required', 'string', 'max:100'],
            'district' => ['required', 'string', 'max:100'],
            'street' => ['required', 'string', 'max:255'],
            'phone' => ['required', 'string', 'max:20'],
            'is_default' => ['sometimes', 'boolean'],
            // [الموقع الجغرافي] إحداثيات المشتري (GPS أو تحديد من الخريطة)
            'latitude' => ['sometimes', 'nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['sometimes', 'nullable', 'numeric', 'between:-180,180'],
            'is_gps_location' => ['sometimes', 'boolean'],
        ]);

        // المحافظة الافتراضية: عدن (جنوب اليمن)
        $validated['governorate'] = $validated['governorate'] ?? 'عدن';

        $user = $request->user();

        if ($validated['is_default'] ?? false) {
            $user->addresses()->update(['is_default' => false]);
        }

        $address = $user->addresses()->create($validated);

        return $this->success(new AddressResource($address), 'تم إضافة العنوان بنجاح', 201);
    }

    public function update(Request $request, \App\Models\Address $address): JsonResponse
    {
        if ($address->user_id !== $request->user()->id) {
            return $this->error('غير مصرح لك بتعديل هذا العنوان', 403);
        }

        $validated = $request->validate([
            'governorate' => ['sometimes', 'string', 'max:100'],
            'city' => ['sometimes', 'string', 'max:100'],
            'district' => ['sometimes', 'string', 'max:100'],
            'street' => ['sometimes', 'string', 'max:255'],
            'phone' => ['sometimes', 'string', 'max:20'],
            'is_default' => ['sometimes', 'boolean'],
            'latitude' => ['sometimes', 'nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['sometimes', 'nullable', 'numeric', 'between:-180,180'],
            'is_gps_location' => ['sometimes', 'boolean'],
        ]);

        if ($validated['is_default'] ?? false) {
            $request->user()->addresses()->where('id', '!=', $address->id)->update(['is_default' => false]);
        }

        $address->update($validated);

        return $this->success(new AddressResource($address->fresh()), 'تم تحديث العنوان بنجاح');
    }

    public function destroy(Request $request, \App\Models\Address $address): JsonResponse
    {
        if ($address->user_id !== $request->user()->id) {
            return $this->error('غير مصرح لك بحذف هذا العنوان', 403);
        }

        $wasDefault = (bool) $address->is_default;
        $address->delete();

        if ($wasDefault) {
            $next = $request->user()->addresses()->latest()->first();
            if ($next) {
                $next->update(['is_default' => true]);
            }
        }

        return $this->success(null, 'تم حذف العنوان بنجاح');
    }

    public function setDefault(Request $request, \App\Models\Address $address): JsonResponse
    {
        if ($address->user_id !== $request->user()->id) {
            return $this->error('غير مصرح لك بتعديل هذا العنوان', 403);
        }

        $request->user()->addresses()->update(['is_default' => false]);
        $address->update(['is_default' => true]);

        return $this->success(new AddressResource($address->fresh()), 'تم تعيين العنوان الافتراضي بنجاح');
    }
}
