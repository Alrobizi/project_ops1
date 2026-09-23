<?php

namespace App\Filament\Widgets;

use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class StatsOverviewWidget extends BaseWidget
{
    protected static ?int $sort = 1;

    protected function getStats(): array
    {
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

        $thisMonthOrders = Order::whereMonth('created_at', now()->month)->count();
        $lastMonthOrders = Order::whereMonth('created_at', now()->subMonth()->month)->count();
        $ordersGrowth = $lastMonthOrders > 0
            ? round((($thisMonthOrders - $lastMonthOrders) / $lastMonthOrders) * 100, 1)
            : 100;

        $totalSales = Order::where('status', '!=', 'cancelled')->sum('total');
        $ordersCount = Order::count();
        $productsCount = Product::count();
        $usersCount = User::where('role', 'customer')->count();

        return [
            Stat::make('إجمالي المبيعات', number_format($totalSales, 2).' ر.س')
                ->description($salesGrowth.'% عن الشهر الماضي')
                ->descriptionIcon($salesGrowth >= 0 ? 'heroicon-m-arrow-trending-up' : 'heroicon-m-arrow-trending-down')
                ->color($salesGrowth >= 0 ? 'success' : 'danger')
                ->chart([7, 3, 4, 5, 6, 8, 9]),

            Stat::make('عدد الطلبات', number_format($ordersCount))
                ->description($ordersGrowth.'% عن الشهر الماضي')
                ->descriptionIcon($ordersGrowth >= 0 ? 'heroicon-m-arrow-trending-up' : 'heroicon-m-arrow-trending-down')
                ->color($ordersGrowth >= 0 ? 'success' : 'danger')
                ->chart([3, 5, 4, 6, 5, 7, 8]),

            Stat::make('عدد المنتجات', number_format($productsCount))
                ->description('منتج في المتجر')
                ->descriptionIcon('heroicon-m-shopping-bag')
                ->color('info'),

            Stat::make('عدد المستخدمين', number_format($usersCount))
                ->description('عميل مسجل')
                ->descriptionIcon('heroicon-m-users')
                ->color('warning'),
        ];
    }
}
