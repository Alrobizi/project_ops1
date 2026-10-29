<?php

namespace App\Filament\Widgets;

use App\Filament\Resources\OrderResource;
use App\Models\Order;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget as BaseWidget;

class LatestOrdersWidget extends BaseWidget
{
    protected static ?string $heading = 'آخر الطلبات';
    protected static ?string $description = 'أحدث المعاملات في المتجر';

    protected static ?int $sort = 5;

    protected int|string|array $columnSpan = 'full';

    public function table(Table $table): Table
    {
        return $table
            ->query(Order::query()->with('user')->latest()->limit(8))
            ->columns([
                Tables\Columns\TextColumn::make('order_number')
                    ->label('رقم الطلب')
                    ->searchable()
                    ->weight('bold')
                    ->color('primary')
                    ->url(fn (Order $record): string => OrderResource::getUrl('view', ['record' => $record])),

                Tables\Columns\ImageColumn::make('user.avatar')
                    ->label('العميل')
                    ->circular()
                    ->defaultImageUrl(fn (Order $record): string =>
                        'https://ui-avatars.com/api/?name=' . urlencode($record->user?->name ?? 'عميل')
                        . '&background=6D5DF6&color=ffffff&size=40&font-size=0.4'
                    )
                    ->extraImgAttributes(['loading' => 'lazy']),

                Tables\Columns\TextColumn::make('user.name')
                    ->label('اسم العميل')
                    ->searchable()
                    ->description(fn (Order $record): ?string => $record->user?->email),

                Tables\Columns\TextColumn::make('status')
                    ->label('الحالة')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => Order::STATUSES[$state] ?? $state)
                    ->color(fn (string $state): string => match ($state) {
                        'pending'    => 'warning',
                        'processing' => 'info',
                        'shipped'    => 'primary',
                        'delivered'  => 'success',
                        'cancelled'  => 'danger',
                        default      => 'gray',
                    }),

                Tables\Columns\TextColumn::make('total')
                    ->label('الإجمالي')
                    ->money('SAR')
                    ->weight('bold'),

                Tables\Columns\TextColumn::make('created_at')
                    ->label('التاريخ')
                    ->dateTime('d/m/Y H:i')
                    ->sortable()
                    ->color('gray'),
            ])
            ->actions([
                Tables\Actions\Action::make('view')
                    ->label('عرض')
                    ->icon('heroicon-m-eye')
                    ->color('primary')
                    ->url(fn (Order $record): string => OrderResource::getUrl('view', ['record' => $record])),
            ])
            ->paginated(false)
            ->striped(false);
    }
}
