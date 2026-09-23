<?php

namespace App\Http\Controllers\Api;

use App\Http\Resources\CategoryResource;
use App\Models\Category;
use Illuminate\Http\JsonResponse;

class CategoryController extends BaseApiController
{
    public function index(): JsonResponse
    {
        $categories = Category::where('is_active', true)
            ->whereNull('parent_id')
            ->where('type', 'main')
            ->with(['activeChildren' => function ($query) {
                $query->withCount('products');
            }])
            ->withCount('products')
            ->orderBy('sort_order')
            ->get();

        return $this->success(CategoryResource::collection($categories));
    }

    public function marketing(): JsonResponse
    {
        $sections = Category::where('is_active', true)
            ->where('type', 'marketing')
            ->withCount('products')
            ->orderBy('sort_order')
            ->get();

        return $this->success(CategoryResource::collection($sections));
    }

    public function show(Category $category): JsonResponse
    {
        $category->load(['activeChildren' => function ($query) {
            $query->withCount('products');
        }])->loadCount('products');

        return $this->success(new CategoryResource($category));
    }
}
