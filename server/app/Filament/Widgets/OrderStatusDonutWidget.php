<?php

namespace App\Filament\Widgets;

use App\Models\Order;
use Filament\Widgets\ChartWidget;
use Illuminate\Support\Facades\Cache;

class OrderStatusDonutWidget extends ChartWidget
{
    protected static ?string $heading = 'توزيع حالات الطلبات';
    protected static ?string $description = 'نسبة الإنجاز ومعالجة طلبات العملاء';

    protected static ?int $sort = 3;
    protected int|string|array $columnSpan = [
        'default' => 'full',
        'sm'      => 'full',
        'lg'      => 1,
        'xl'      => 1,
    ];

    protected function getData(): array
    {
        return Cache::remember('order_status_donut_stats', 180, function () {
            $counts = Order::selectRaw('status, count(*) as count')
                ->groupBy('status')
                ->pluck('count', 'status')
                ->toArray();

            $statuses = [
                'delivered' => ['label' => 'مكتمل', 'color' => '#10B981'],
                'shipped' => ['label' => 'قيد الشحن', 'color' => '#3B82F6'],
                'processing' => ['label' => 'قيد المعالجة', 'color' => '#F59E0B'],
                'pending' => ['label' => 'في الانتظار', 'color' => '#8B5CF6'],
                'cancelled' => ['label' => 'ملغي', 'color' => '#EF4444'],
            ];

            $labels = [];
            $data = [];
            $colors = [];

            foreach ($statuses as $statusKey => $info) {
                $count = $counts[$statusKey] ?? 0;
                if ($count > 0 || empty($counts)) {
                    $labels[] = $info['label'];
                    $data[] = $count;
                    $colors[] = $info['color'];
                }
            }

            // في حال عدم وجود طلبات مسجلة بعد
            if (empty($data)) {
                $labels = ['مكتمل', 'قيد الشحن', 'قيد المعالجة'];
                $data = [1, 2, 3];
                $colors = ['#10B981', '#3B82F6', '#F59E0B'];
            }

            return [
                'datasets' => [
                    [
                        'label' => 'الطلبات',
                        'data' => $data,
                        'backgroundColor' => $colors,
                        'borderWidth' => 2,
                        'borderColor' => '#ffffff',
                    ],
                ],
                'labels' => $labels,
            ];
        });
    }

    protected function getType(): string
    {
        return 'doughnut';
    }

    protected function getOptions(): array
    {
        return [
            'plugins' => [
                'legend' => [
                    'position' => 'bottom',
                    'labels' => [
                        'font' => [
                            'family' => 'Cairo',
                            'weight' => 'bold',
                        ],
                        'padding' => 16,
                    ],
                ],
            ],
            'cutout' => '70%',
        ];
    }
}
