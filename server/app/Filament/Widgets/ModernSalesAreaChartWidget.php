<?php

namespace App\Filament\Widgets;

use App\Models\Order;
use Filament\Widgets\ChartWidget;
use Illuminate\Support\Facades\Cache;

class ModernSalesAreaChartWidget extends ChartWidget
{
    protected static ?string $heading = 'المبيعات - آخر 30 يوماً';
    protected static ?string $description = 'تحليل بياني لحجم المبيعات والإيرادات بالريال السعودي';

    protected static ?int $sort = 2;
    protected int|string|array $columnSpan = [
        'default' => 'full',
        'sm'      => 'full',
        'lg'      => 2,
        'xl'      => 2,
    ];

    public ?string $filter = '30';

    protected function getFilters(): ?array
    {
        return [
            '7' => 'آخر 7 أيام',
            '30' => 'آخر 30 يوماً',
            '90' => 'آخر 90 يوماً',
        ];
    }

    protected function getData(): array
    {
        $daysCount = match ($this->filter) {
            '7' => 7,
            '90' => 90,
            default => 30,
        };

        return Cache::remember("sales_chart_days_{$daysCount}", 180, function () use ($daysCount) {
            $days = collect(range($daysCount - 1, 0))->map(fn ($i) => now()->subDays($i)->startOfDay());

            $salesByDate = Order::where('status', '!=', 'cancelled')
                ->where('created_at', '>=', now()->subDays($daysCount)->startOfDay())
                ->get()
                ->groupBy(fn ($order) => $order->created_at->format('Y-m-d'))
                ->map(fn ($orders) => $orders->sum('total'));

            $sales = $days->map(fn ($day) => (float) ($salesByDate->get($day->format('Y-m-d'), 0)));

            // تنسيق عرض التواريخ
            $labels = $days->map(function ($day) use ($daysCount) {
                return $daysCount > 30 ? $day->format('m/d') : $day->format('d/m');
            })->toArray();

            return [
                'datasets' => [
                    [
                        'label' => 'المبيعات (ر.س)',
                        'data' => $sales->toArray(),
                        'fill' => 'start',
                        'borderColor' => '#6D5DF6',
                        'backgroundColor' => 'rgba(109, 93, 246, 0.16)',
                        'borderWidth' => 3,
                        'tension' => 0.4,
                        'pointBackgroundColor' => '#6D5DF6',
                        'pointBorderColor' => '#ffffff',
                        'pointBorderWidth' => 2,
                        'pointRadius' => $daysCount > 30 ? 2 : 4,
                        'pointHoverRadius' => 6,
                    ],
                ],
                'labels' => $labels,
            ];
        });
    }

    protected function getType(): string
    {
        return 'line';
    }

    protected function getOptions(): array
    {
        return [
            'plugins' => [
                'legend' => [
                    'display' => false,
                ],
                'tooltip' => [
                    'rtl' => true,
                    'textDirection' => 'rtl',
                    'padding' => 12,
                    'cornerRadius' => 12,
                    'backgroundColor' => '#1E293B',
                ],
            ],
            'scales' => [
                'y' => [
                    'grid' => [
                        'color' => 'rgba(226, 232, 240, 0.6)',
                    ],
                    'ticks' => [
                        'font' => [
                            'family' => 'Cairo',
                        ],
                    ],
                ],
                'x' => [
                    'grid' => [
                        'display' => false,
                    ],
                    'ticks' => [
                        'font' => [
                            'family' => 'Cairo',
                        ],
                    ],
                ],
            ],
        ];
    }
}
