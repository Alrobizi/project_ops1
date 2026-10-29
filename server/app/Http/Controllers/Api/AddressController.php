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
}
