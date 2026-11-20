<?php

namespace App\Http\Controllers\Api;

use App\Models\OrderItem;
use App\Models\Product;
use App\Models\ProductReview;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ReviewController extends BaseApiController
{
    /**
     * جلب مراجعات منتج معين مع إحصائيات التقييم وملاءمة المقاس (نمط SHEIN)
     */
    public function index(Product $product): JsonResponse
    {
        $reviews = ProductReview::with('user:id,name')
            ->where('product_id', $product->id)
            ->latest()
            ->limit(50)
            ->get();

        $total = $reviews->count();
        $avgRating = $total > 0 ? round($reviews->avg('rating'), 1) : (float) $product->rating;

        $fitCounts = [
            'small' => $reviews->where('size_fit', 'small')->count(),
            'true_to_size' => $reviews->where('size_fit', 'true_to_size')->count(),
            'large' => $reviews->where('size_fit', 'large')->count(),
        ];

        $data = $reviews->map(fn (ProductReview $r) => [
            'id' => $r->id,
            'user_name' => $r->user?->name ?? 'عميل',
            'rating' => $r->rating,
            'comment' => $r->comment ?? '',
            'size_fit' => $r->size_fit ?? 'true_to_size',
            'is_verified_purchase' => (bool) $r->is_verified_purchase,
            'created_at' => $r->created_at?->toISOString(),
        ]);

        return $this->success([
            'reviews' => $data,
            'summary' => [
                'average_rating' => $avgRating,
                'total_reviews' => $total,
                'size_fit' => $fitCounts,
            ],
        ], 'تم جلب التقييمات بنجاح');
    }

    /**
     * إضافة أو تحديث تقييم عميل لمنتج
     */
    public function store(Request $request, Product $product): JsonResponse
    {
        $validated = $request->validate([
            'rating' => ['required', 'integer', 'min:1', 'max:5'],
            'comment' => ['nullable', 'string', 'max:1000'],
            'size_fit' => ['nullable', 'string', 'in:small,true_to_size,large'],
        ]);

        $user = $request->user();

        $isVerifiedPurchase = OrderItem::where('product_id', $product->id)
            ->whereHas('order', fn ($q) => $q->where('user_id', $user->id))
            ->exists();

        $review = ProductReview::updateOrCreate(
            [
                'product_id' => $product->id,
                'user_id' => $user->id,
            ],
            [
                'rating' => $validated['rating'],
                'comment' => $validated['comment'] ?? '',
                'size_fit' => $validated['size_fit'] ?? 'true_to_size',
                'is_verified_purchase' => $isVerifiedPurchase,
            ]
        );

        // تحديث متوسط التقييم وعدد التقييمات في جدول المنتجات
        $stats = ProductReview::where('product_id', $product->id)
            ->selectRaw('COUNT(*) as cnt, AVG(rating) as avg_rating')
            ->first();

        $product->update([
            'rating' => round((float) ($stats->avg_rating ?? $validated['rating']), 1),
            'reviews_count' => (int) ($stats->cnt ?? 1),
        ]);

        return $this->success([
            'id' => $review->id,
            'user_name' => $user->name,
            'rating' => $review->rating,
            'comment' => $review->comment ?? '',
            'size_fit' => $review->size_fit,
            'is_verified_purchase' => (bool) $review->is_verified_purchase,
            'created_at' => $review->created_at?->toISOString(),
        ], 'تم حفظ تقييمك بنجاح', 201);
    }
}
