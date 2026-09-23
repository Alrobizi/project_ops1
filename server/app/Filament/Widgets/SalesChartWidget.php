<?php

namespace App\Filament\Widgets;

use App\Models\Order;
use Filament\Widgets\ChartWidget;

class SalesChartWidget extends ChartWidget
{
    protected static ?string $heading = 'المبيعات - آخر 30 يوماً';

    protected static ?int $sort = 2;

    protected function getData(): array
    {
        $days = collect(range(29, 0))->map(fn ($i) => now()->subDays($i)->startOfDay());

        $sales = $days->map(fn ($day) => Order::where('status', '!=', 'cancelled')
            ->whereDate('created_at', $day)
            ->sum('total'));

        return [
            'datasets' => [
                [
                    'label' => 'المبيعات (ر.س)',
                    'data' => $sales->toArray(),
                    'borderColor' => '#7C3AED',
                    'backgroundColor' => 'rgba(124, 58, 237, 0.1)',
                    'fill' => true,
                    'tension' => 0.4,
                ],
            ],
            'labels' => $days->map(fn ($day) => $day->format('d/m'))->toArray(),
        ];
    }

    protected function getType(): string
    {
        return 'line';
    }
}
