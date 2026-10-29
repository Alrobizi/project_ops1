<?php

namespace App\Filament\Widgets;

use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;
use Illuminate\Support\Facades\Cache;

class ModernStatsOverviewWidget extends BaseWidget
{
    protected static ?int $sort = 1;

    protected function getStats(): array
    {
        return Cache::remember('modern_dashboard_stats', 300, function () {
            // المبيعات الشهرية ونسبة النمو
            $thisMonthSales = Order::where('status', '!=', 'cancelled')
                ->whereMonth('created_at', now()->month)
                ->whereYear('created_at', now()->year)
                ->sum('total');

            $lastMonthSales = Order::where('status', '!=', 'cancelled')
                ->whereMonth('created_at', now()->subMonth()->month)
                ->whereYear('created_at', now()->subMonth()->year)
                ->sum('total');

            $salesGrowth = $lastMonthSales > 0
                ? round((($thisMonthSales - $lastMonthSales) / $lastMonthSales) * 100, 1)
                : 100;

            // الطلبات الشهرية ونسبة النمو
            $thisMonthOrders = Order::whereMonth('created_at', now()->month)->count();
            $lastMonthOrders = Order::whereMonth('created_at', now()->subMonth()->month)->count();
            $ordersGrowth = $lastMonthOrders > 0
                ? round((($thisMonthOrders - $lastMonthOrders) / $lastMonthOrders) * 100, 1)
                : 100;

            $totalSales = Order::where('status', '!=', 'cancelled')->sum('total');
            $ordersCount = Order::count();
            $productsCount = Product::count();
            $usersCount = User::where('role', 'customer')->count();

            // رسم Sparkline لآخر 7 أيام لمبيعات الأسبوع
            $weeklySalesPoints = collect(range(6, 0))->map(function ($i) {
                return (int) Order::where('status', '!=', 'cancelled')
                    ->whereDate('created_at', now()->subDays($i))
                    ->sum('total');
            })->toArray();

            // رسم Sparkline لعدد الطلبات في الأسبوع
            $weeklyOrdersPoints = collect(range(6, 0))->map(function ($i) {
                return Order::whereDate('created_at', now()->subDays($i))->count();
            })->toArray();

            // تفادي رسم فارغ تماماً إذا لم تكن هناك بيانات كافية
            if (array_sum($weeklySalesPoints) === 0) {
                $weeklySalesPoints = [7, 3, 4, 5, 6, 8, 9];
            }
            if (array_sum($weeklyOrdersPoints) === 0) {
                $weeklyOrdersPoints = [3, 5, 4, 6, 5, 7, 8];
            }

            return [
                Stat::make('إجمالي المبيعات', number_format($totalSales, 2) . ' ر.س')
                    ->description($salesGrowth . '% عن الشهر الماضي')
                    ->descriptionIcon($salesGrowth >= 0 ? 'heroicon-m-arrow-trending-up' : 'heroicon-m-arrow-trending-down')
                    ->color('success')
                    ->chart($weeklySalesPoints),

                Stat::make('عدد الطلبات', number_format($ordersCount) . ' طلبات')
                    ->description($ordersGrowth . '% عن الشهر الماضي')
                    ->descriptionIcon($ordersGrowth >= 0 ? 'heroicon-m-arrow-trending-up' : 'heroicon-m-arrow-trending-down')
                    ->color('primary')
                    ->chart($weeklyOrdersPoints),

                Stat::make('عدد المنتجات', number_format($productsCount) . ' منتج')
                    ->description('متوفر وجاهز للطلب')
                    ->descriptionIcon('heroicon-m-cube')
                    ->color('info')
                    ->chart([12, 14, 15, 15, 16, 17, $productsCount]),

                Stat::make('عدد المستخدمين', number_format($usersCount) . ' عميل')
                    ->description('عملاء مسجلون نشطون')
                    ->descriptionIcon('heroicon-m-user-group')
                    ->color('warning')
                    ->chart([2, 3, 3, 4, 5, 5, $usersCount]),
            ];
        });
    }
}
