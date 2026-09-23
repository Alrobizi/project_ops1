<?php

namespace App\Http\Controllers\Api;

use App\Http\Resources\OrderResource;
use App\Models\Address;
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
            ->with(['items', 'address'])
            ->latest()
            ->paginate(15);

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

        $order->load(['items', 'address']);

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
            'address_id' => ['required', 'exists:addresses,id'],
            'payment_method' => ['required', 'string', 'max:100'],
            'order_type' => ['nullable', 'string', 'max:100'],
        ]);

        $user = $request->user();

        $address = Address::where('id', $validated['address_id'])
            ->where('user_id', $user->id)
            ->first();

        if (! $address) {
            return $this->error('العنوان غير صالح', 422);
        }

        try {
            $order = DB::transaction(function () use ($validated, $user, $address) {
                $subtotal = 0;
                $itemsData = [];

                foreach ($validated['items'] as $item) {
                    $product = Product::lockForUpdate()->findOrFail($item['product_id']);

                    if (! $product->is_active) {
                        throw new \RuntimeException("المنتج «{$product->name}» غير متوفر حالياً");
                    }

                    if ($product->stock < $item['quantity']) {
                        throw new \RuntimeException("الكمية المطلوبة من «{$product->name}» غير متوفرة (المتبقي: {$product->stock})");
                    }

                    $product->decrement('stock', $item['quantity']);

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

                $order = Order::create([
                    'order_number' => Order::generateOrderNumber(),
                    'user_id' => $user->id,
                    'address_id' => $address->id,
                    'subtotal' => $subtotal,
                    'shipping' => $shipping,
                    'total' => $subtotal + $shipping,
                    'status' => 'pending',
                    'payment_method' => $validated['payment_method'],
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
}
