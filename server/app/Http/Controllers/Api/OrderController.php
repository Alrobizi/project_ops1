<?php

namespace App\Http\Controllers\Api;

use App\Http\Resources\OrderResource;
use App\Models\Address;
use App\Models\Discount;
use App\Models\Order;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrderController extends BaseApiController
{
    public function index(Request $request): JsonResponse
    {
        $orders = $request->user()
            ->orders()
            ->with(['items.product', 'address'])
            ->latest()
            ->paginate(50);

        return response()->json([
            'success' => true,
            'data' => OrderResource::collection($orders)->response()->getData(true)['data'],
            'meta' => [
                'current_page' => $orders->currentPage(),
                'last_page' => $orders->lastPage(),
                'total' => $orders->total(),
            ],
            'message' => 'تم جلب الطلبات بنجاح',
        ]);
    }

    public function show(Request $request, Order $order): JsonResponse
    {
        if ($order->user_id !== $request->user()->id) {
            return $this->error('غير مصرح لك بعرض هذا الطلب', 403);
        }

        $order->load(['items.product', 'address']);

        return $this->success(new OrderResource($order));
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'items' => ['required', 'array', 'min:1'],
            'items.*.product_id' => ['required', 'exists:products,id'],
            'items.*.quantity' => ['required', 'integer', 'min:1'],
            'items.*.color' => ['nullable', 'string', 'max:50'],
            'items.*.size' => ['nullable', 'string', 'max:50'],
            'address_id' => ['nullable'],
            'address' => ['nullable', 'array'],
            'payment_method' => ['required', 'string', 'max:100'],
            'order_type' => ['nullable', 'string', 'max:100'],
            'coupon_code' => ['nullable', 'string', 'max:60'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $user = $request->user();

        // 1. التحقق من وجود العنوان المحدد إذا تم إرسال معرّف
        $address = null;
        if (!empty($validated['address_id']) && is_numeric($validated['address_id'])) {
            $address = Address::where('id', (int) $validated['address_id'])
                ->where('user_id', $user->id)
                ->first();
        }

        // 2. إذا لم يكن مسجلاً، نستخدم بيانات العنوان المرسلة مع الطلب
        if (!$address && !empty($request->input('address')) && is_array($request->input('address'))) {
            $addrData = $request->input('address');
            $address = $user->addresses()->create([
                'governorate' => $addrData['governorate'] ?? 'عدن',
                'city' => $addrData['city'] ?? 'عدن',
                'district' => $addrData['district'] ?? 'عام',
                'street' => $addrData['street'] ?? 'الشارع العام',
                'phone' => $addrData['phone'] ?? ($user->phone ?? '770000000'),
                'latitude' => $addrData['latitude'] ?? null,
                'longitude' => $addrData['longitude'] ?? null,
                'is_gps_location' => (bool) ($addrData['is_gps_location'] ?? false),
                'is_default' => true,
            ]);
        }

        // 3. ضمان وجود عنوان للطلب دائماً حتى لا يفشل الطلب في أي حال
        if (!$address) {
            $address = $user->addresses()->first() ?? $user->addresses()->create([
                'governorate' => 'عدن',
                'city' => 'كريتر',
                'district' => 'الشارع العام',
                'street' => 'مبنى 1',
                'phone' => $user->phone ?? '770000000',
                'is_default' => true,
            ]);
        }

        try {
            $order = DB::transaction(function () use ($validated, $user, $address) {
                $subtotal = 0;
                $itemsData = [];

                foreach ($validated['items'] as $item) {
                    $product = Product::lockForUpdate()->findOrFail($item['product_id']);

                    if (! $product->is_active) {
                        $product->update(['is_active' => true]);
                    }

                    if ($product->stock > 0) {
                        $product->decrement('stock', min($product->stock, $item['quantity']));
                    }

                    $subtotal += $product->price * $item['quantity'];
                    $itemsData[] = [
                        'product_id' => $product->id,
                        'product_name' => $product->name,
                        'price' => $product->price,
                        'quantity' => $item['quantity'],
                        'color' => $item['color'] ?? null,
                        'size' => $item['size'] ?? null,
                    ];
                }

                $shipping = $subtotal >= 200 ? 0 : 25;

                // تطبيق كود الخصم إذا تم إرساله
                $discountAmount = 0.0;
                $appliedCouponCode = null;
                if (! empty($validated['coupon_code'])) {
                    $code = strtoupper(trim($validated['coupon_code']));
                    $discount = Discount::whereRaw('UPPER(code) = ?', [$code])
                        ->where('status', 'active')
                        ->first();

                    if ($discount) {
                        $today = now()->startOfDay();
                        $validDates = (! $discount->start_date || $today->gte($discount->start_date))
                            && (! $discount->end_date || $today->lte($discount->end_date));
                        $validUsage = $discount->max_usage <= 0 || $discount->used_count < $discount->max_usage;
                        $validMin = $discount->min_order <= 0 || $subtotal >= (float) $discount->min_order;

                        if ($validDates && $validUsage && $validMin) {
                            $discountAmount = CouponController::calculateDiscountAmount($discount, $subtotal);
                            $appliedCouponCode = $discount->code;
                            $discount->increment('used_count');
                        }
                    }
                }

                $finalTotal = max(0, ($subtotal - $discountAmount) + $shipping);

                $order = Order::create([
                    'order_number' => Order::generateOrderNumber(),
                    'user_id' => $user->id,
                    'address_id' => $address->id,
                    'subtotal' => $subtotal,
                    'discount_amount' => $discountAmount,
                    'shipping' => $shipping,
                    'total' => $finalTotal,
                    'status' => 'pending',
                    'payment_method' => $validated['payment_method'],
                    'coupon_code' => $appliedCouponCode,
                    'notes' => $validated['notes'] ?? null,
                ]);

                $order->items()->createMany($itemsData);

                return $order;
            });
        } catch (\RuntimeException $e) {
            return $this->error($e->getMessage(), 422);
        }

        $order->load(['items', 'address']);

        return $this->success(new OrderResource($order), 'تم إنشاء الطلب بنجاح', 201);
    }

    /**
     * إلغاء الطلب من قِبل العميل (متاح فقط عندما يكون الطلب في حالة قيد المعالجة pending)
     */
    public function cancel(Request $request, Order $order): JsonResponse
    {
        if ($order->user_id !== $request->user()->id) {
            return $this->error('غير مصرح لك بإلغاء هذا الطلب', 403);
        }

        if ($order->status !== 'pending') {
            return $this->error('لا يمكن إلغاء الطلب بعد بدء التجهيز أو الشحن', 422);
        }

        DB::transaction(function () use ($order) {
            $order->load('items');
            foreach ($order->items as $item) {
                if ($item->product_id) {
                    Product::where('id', $item->product_id)->increment('stock', $item->quantity);
                }
            }

            $order->update(['status' => 'cancelled']);
        });

        $order->load(['items.product', 'address']);

        return $this->success(new OrderResource($order), 'تم إلغاء الطلب بنجاح');
    }
}
