<?php

namespace App\Http\Controllers\Api;

use App\Http\Resources\ProductResource;
use App\Models\Category;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * إدارة المنتجات والتصنيفات من تطبيق لوحة التحكم.
 * محمي بـ middleware: admin + product.manager
 */
class AdminProductController extends BaseApiController
{
    // ============================================
    // المنتجات
    // ============================================

    public function index(Request $request): JsonResponse
    {
        $query = Product::query()->with('category');

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

        $products = $query->latest()->paginate((int) $request->integer('per_page', 50));

        return response()->json([
            'success' => true,
            'data' => ProductResource::collection($products->items()),
            'meta' => [
                'current_page' => $products->currentPage(),
                'last_page' => $products->lastPage(),
                'per_page' => $products->perPage(),
                'total' => $products->total(),
            ],
            'message' => 'تم جلب المنتجات بنجاح',
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'category_id' => ['required', 'integer', 'exists:categories,id'],
            'name' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'price' => ['required', 'numeric', 'min:0'],
            'old_price' => ['nullable', 'numeric', 'min:0'],
            'currency' => ['nullable', 'in:SAR,YER'],
            'image' => ['nullable', 'string'],
            'stock' => ['nullable', 'integer', 'min:0'],
            'colors' => ['nullable', 'array'],
            'sizes' => ['nullable', 'array'],
            'is_featured' => ['nullable', 'boolean'],
            'is_active' => ['nullable', 'boolean'],
            // [الموقع الجغرافي] موقع البائع (واجهة إضافة منتج لدى البائع)
            'seller_name' => ['nullable', 'string', 'max:255'],
            'seller_governorate' => ['nullable', 'string', 'max:100'],
            'seller_city' => ['nullable', 'string', 'max:100'],
            'seller_latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'seller_longitude' => ['nullable', 'numeric', 'between:-180,180'],
        ]);

        $validated['is_active'] = $validated['is_active'] ?? true;

        $product = Product::create($validated);
        $product->load('category');

        return $this->success(new ProductResource($product), 'تم إضافة المنتج بنجاح', 201);
    }

    public function update(Request $request, Product $product): JsonResponse
    {
        $validated = $request->validate([
            'category_id' => ['sometimes', 'integer', 'exists:categories,id'],
            'name' => ['sometimes', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'price' => ['sometimes', 'numeric', 'min:0'],
            'old_price' => ['nullable', 'numeric', 'min:0'],
            'currency' => ['nullable', 'in:SAR,YER'],
            'image' => ['nullable', 'string'],
            'stock' => ['nullable', 'integer', 'min:0'],
            'colors' => ['nullable', 'array'],
            'sizes' => ['nullable', 'array'],
            'is_featured' => ['nullable', 'boolean'],
            'is_active' => ['nullable', 'boolean'],
            // [الموقع الجغرافي] موقع البائع
            'seller_name' => ['nullable', 'string', 'max:255'],
            'seller_governorate' => ['nullable', 'string', 'max:100'],
            'seller_city' => ['nullable', 'string', 'max:100'],
            'seller_latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'seller_longitude' => ['nullable', 'numeric', 'between:-180,180'],
        ]);

        $product->update($validated);
        $product->load('category');

        return $this->success(new ProductResource($product->fresh()), 'تم تحديث المنتج بنجاح');
    }

    public function destroy(Product $product): JsonResponse
    {
        $product->delete();

        return $this->success(null, 'تم حذف المنتج بنجاح');
    }

    // ============================================
    // التصنيفات
    // ============================================

    public function categories(): JsonResponse
    {
        $categories = Category::withCount('products')
            ->orderBy('sort_order')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $categories->map(fn ($c) => [
                'id' => $c->id,
                'name' => $c->name,
                'parent_id' => $c->parent_id,
                'type' => $c->type,
                'sort_order' => $c->sort_order,
                'is_active' => $c->is_active,
                'products_count' => $c->products_count,
            ]),
            'message' => 'تم جلب التصنيفات بنجاح',
        ]);
    }

    public function storeCategory(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'type' => ['nullable', 'in:main,sub,marketing'],
            'parent_id' => ['nullable', 'integer', 'exists:categories,id'],
            'icon' => ['nullable', 'string', 'max:50'],
            'sort_order' => ['nullable', 'integer', 'min:0'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $validated['type'] = $validated['type'] ?? ($request->filled('parent_id') ? 'sub' : 'main');
        $validated['is_active'] = $validated['is_active'] ?? true;

        $category = Category::create($validated);

        return $this->success([
            'id' => $category->id,
            'name' => $category->name,
            'parent_id' => $category->parent_id,
            'type' => $category->type,
            'sort_order' => $category->sort_order,
            'is_active' => $category->is_active,
            'products_count' => 0,
        ], 'تم إضافة التصنيف بنجاح', 201);
    }

    public function updateCategory(Request $request, Category $category): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'type' => ['sometimes', 'in:main,sub,marketing'],
            'parent_id' => ['nullable', 'integer', 'exists:categories,id'],
            'icon' => ['nullable', 'string', 'max:50'],
            'sort_order' => ['nullable', 'integer', 'min:0'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $category->update($validated);

        return $this->success([
            'id' => $category->id,
            'name' => $category->name,
            'parent_id' => $category->parent_id,
            'type' => $category->type,
            'sort_order' => $category->sort_order,
            'is_active' => $category->is_active,
            'products_count' => $category->products()->count(),
        ], 'تم تحديث التصنيف بنجاح');
    }

    public function destroyCategory(Category $category): JsonResponse
    {
        if ($category->products()->exists()) {
            return $this->error('لا يمكن حذف تصنيف يحتوي على منتجات', 422);
        }

        if ($category->children()->exists()) {
            return $this->error('لا يمكن حذف تصنيف يحتوي على تصنيفات فرعية', 422);
        }

        $category->delete();

        return $this->success(null, 'تم حذف التصنيف بنجاح');
    }
}
