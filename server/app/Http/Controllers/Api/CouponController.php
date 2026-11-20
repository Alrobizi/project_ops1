<?php

namespace App\Http\Controllers\Api;

use App\Models\Discount;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CouponController extends BaseApiController
{
    /**
     * التحقق من كود الخصم وحساب قيمة الخصم بناءً على المجموع الفرعي للسلة
     */
    public function validateCoupon(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'code' => ['required', 'string', 'max:60'],
            'subtotal' => ['required', 'numeric', 'min:0'],
        ]);

        $code = strtoupper(trim($validated['code']));
        $subtotal = (float) $validated['subtotal'];

        $discount = Discount::whereRaw('UPPER(code) = ?', [$code])->first();

        if (! $discount) {
            return $this->error('كود الخصم غير صحيح', 404);
        }

        if ($discount->status !== 'active') {
            return $this->error('كود الخصم غير مفعّل حالياً', 422);
        }

        $today = now()->startOfDay();
        if ($discount->start_date && $today->lt($discount->start_date)) {
            return $this->error('كود الخصم لم يبدأ بعد', 422);
        }

        if ($discount->end_date && $today->gt($discount->end_date)) {
            return $this->error('انتهت صلاحية كود الخصم', 422);
        }

        if ($discount->max_usage > 0 && $discount->used_count >= $discount->max_usage) {
            return $this->error('تم الوصول للحد الأقصى لاستخدام هذا الكود', 422);
        }

        if ($discount->min_order > 0 && $subtotal < (float) $discount->min_order) {
            return $this->error(
                'الحد الأدنى للطلب لاستخدام هذا الكود هو ' . number_format((float) $discount->min_order, 0),
                422
            );
        }

        $amount = self::calculateDiscountAmount($discount, $subtotal);

        return $this->success([
            'code' => $discount->code,
            'type' => $discount->type,
            'value' => (float) $discount->value,
            'discount_amount' => $amount,
            'min_order' => (float) $discount->min_order,
        ], 'تم تطبيق كود الخصم بنجاح');
    }

    /**
     * حساب قيمة الخصم مع ضمان عدم تجاوز المجموع الفرعي
     */
    public static function calculateDiscountAmount(Discount $discount, float $subtotal): float
    {
        $type = mb_strtolower(trim((string) $discount->type));
        $isPercent = str_contains($type, 'نسبة') || str_contains($type, 'percent') || $type === '%';

        $amount = $isPercent
            ? round($subtotal * ((float) $discount->value / 100), 2)
            : (float) $discount->value;

        return max(0.0, min($amount, $subtotal));
    }
}
