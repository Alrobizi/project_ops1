<?php

namespace App\Http\Controllers\Api;

use App\Http\Resources\ProductResource;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProductController extends BaseApiController
{
    public function index(Request $request): JsonResponse
    {
        $query = Product::query()
            ->with('category')
            ->where('is_active', true);

        if ($request->filled('category_id')) {
            $query->where('category_id', $request->integer('category_id'));
        }

        if ($request->filled('search')) {
            $search = $request->string('search');
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('description', 'like', "%{$search}%");
            });
        }

        if ($request->boolean('featured')) {
            $query->where('is_featured', true);
        }

        $products = $query->latest()->paginate(15);

        return response()->json([
            'success' => true,
            'data' => ProductResource::collection($products)->response()->getData(true)['data'],
            'meta' => [
                'current_page' => $products->currentPage(),
                'last_page' => $products->lastPage(),
                'per_page' => $products->perPage(),
                'total' => $products->total(),
            ],
            'message' => 'تم جلب المنتجات بنجاح',
        ]);
    }

    public function show(Product $product): JsonResponse
    {
        if (! $product->is_active) {
            return $this->error('المنتج غير متوفر', 404);
        }

        $product->load(['category', 'images']);

        return $this->success(new ProductResource($product));
    }
}
