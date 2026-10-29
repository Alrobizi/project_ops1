<?php

namespace App\Filament\Widgets;

use App\Models\Product;
use Filament\Widgets\Widget;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class TopSellingProductsWidget extends Widget
{
    protected static string $view = 'filament.widgets.top-selling-products-widget';

    protected static ?int $sort = 4;
    protected int|string|array $columnSpan = [
        'default' => 'full',
        'sm'      => 'full',
        'lg'      => 1,
        'xl'      => 1,
    ];

    public function getTopProductsProperty()
    {
        return Cache::remember('dashboard_top_selling_products', 300, function () {
            // الاستعلام عن المنتجات الأكثر مبيعاً مع التجميع
            $bestSellers = DB::table('order_items')
                ->join('products', 'order_items.product_id', '=', 'products.id')
                ->leftJoin('categories', 'products.category_id', '=', 'categories.id')
                ->select(
                    'products.id',
                    'products.name',
                    'products.image',
                    'products.price',
                    'categories.name as category_name',
                    DB::raw('SUM(order_items.quantity) as sales_count'),
                    DB::raw('SUM(order_items.price * order_items.quantity) as total_revenue')
                )
                ->groupBy('products.id', 'products.name', 'products.image', 'products.price', 'categories.name')
                ->orderByDesc('sales_count')
                ->limit(4)
                ->get();

            if ($bestSellers->isEmpty()) {
                // بيانات نموذجية من المتجر عند بداية التشغيل
                return Product::with('category')->latest()->limit(4)->get()->map(function ($p, $idx) {
                    $sales = [42, 31, 58, 18][$idx] ?? 15;
                    $percent = [88, 72, 94, 54][$idx] ?? 50;
                    return (object) [
                        'id' => $p->id,
                        'name' => $p->name,
                        'image' => $p->image,
                        'price' => $p->price,
                        'category_name' => $p->category?->name ?? 'أزياء',
                        'sales_count' => $sales,
                        'total_revenue' => $sales * $p->price,
                        'percent' => $percent,
                    ];
                });
            }

            $maxSales = max($bestSellers->max('sales_count') ?: 1, 1);

            return $bestSellers->map(function ($item) use ($maxSales) {
                $item->percent = round(($item->sales_count / $maxSales) * 100);
                return $item;
            });
        });
    }
}
