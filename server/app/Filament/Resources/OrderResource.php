<?php

namespace App\Filament\Resources;

use App\Filament\Resources\OrderResource\Pages;
use App\Models\Order;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Infolists;
use Filament\Infolists\Infolist;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class OrderResource extends Resource
{
    use \App\Filament\Concerns\RestrictsByAdminPermission;

    protected static ?string $model = Order::class;

    protected static ?string $adminPermission = 'orders';

    protected static ?string $navigationIcon = 'heroicon-o-receipt-percent';

    protected static ?string $navigationLabel = 'الطلبات';

    protected static ?string $modelLabel = 'طلب';

    protected static ?string $pluralModelLabel = 'الطلبات';

    
    protected static ?string $navigationGroup = 'الطلبات';

    protected static ?int $navigationSort = 1;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('بيانات الطلب')
                    ->schema([
                        Forms\Components\TextInput::make('order_number')
                            ->label('رقم الطلب')
                            ->disabled()
                            ->dehydrated(false),

                        Forms\Components\Select::make('user_id')
                            ->label('العميل')
                            ->relationship('user', 'name')
                            ->searchable()
                            ->preload()
                            ->required()
                            ->disabledOn('edit'),

                        Forms\Components\Select::make('status')
                            ->label('الحالة')
                            ->options(Order::STATUSES)
                            ->required(),

                        Forms\Components\Select::make('payment_method')
                            ->label('طريقة الدفع')
                            ->options([
                                'cod' => 'الدفع عند الاستلام',
                                'card' => 'بطاقة ائتمانية',
                            ])
                            ->required(),

                        Forms\Components\TextInput::make('subtotal')
                            ->label('المجموع الفرعي')
                            ->numeric()
                            ->prefix('ر.س')
                            ->disabledOn('edit'),

                        Forms\Components\TextInput::make('shipping')
                            ->label('الشحن')
                            ->numeric()
                            ->prefix('ر.س'),

                        Forms\Components\TextInput::make('total')
                            ->label('الإجمالي')
                            ->numeric()
                            ->prefix('ر.س')
                            ->disabledOn('edit'),
                    ])->columns(2),

                Forms\Components\Section::make('منتجات الطلب')
                    ->schema([
                        Forms\Components\Repeater::make('items')
                            ->label('')
                            ->relationship('items')
                            ->schema([
                                Forms\Components\Select::make('product_id')
                                    ->label('المنتج')
                                    ->relationship('product', 'name')
                                    ->searchable()
                                    ->preload()
                                    ->required()
                                    ->reactive()
                                    ->afterStateUpdated(function ($state, Forms\Set $set) {
                                        $product = \App\Models\Product::find($state);
                                        if ($product) {
                                            $set('product_name', $product->name);
                                            $set('price', $product->price);
                                        }
                                    }),

                                Forms\Components\Hidden::make('product_name'),

                                Forms\Components\TextInput::make('price')
                                    ->label('السعر')
                                    ->numeric()
                                    ->required(),

                                Forms\Components\TextInput::make('quantity')
                                    ->label('الكمية')
                                    ->numeric()
                                    ->required()
                                    ->default(1)
                                    ->minValue(1),

                                Forms\Components\TextInput::make('color')
                                    ->label('اللون'),

                                Forms\Components\TextInput::make('size')
                                    ->label('المقاس'),
                            ])
                            ->columns(5)
                            ->defaultItems(1)
                            ->columnSpanFull(),
                    ]),
            ]);
    }

    public static function infolist(Infolist $infolist): Infolist
    {
        return $infolist
            ->schema([
                Infolists\Components\Section::make('معلومات الطلب')
                    ->schema([
                        Infolists\Components\TextEntry::make('order_number')
                            ->label('رقم الطلب'),

                        Infolists\Components\TextEntry::make('user.name')
                            ->label('العميل'),

                        Infolists\Components\TextEntry::make('status')
                            ->label('الحالة')
                            ->badge()
                            ->formatStateUsing(fn (string $state): string => Order::STATUSES[$state] ?? $state)
                            ->color(fn (string $state): string => match ($state) {
                                'pending' => 'warning',
                                'processing' => 'info',
                                'shipped' => 'primary',
                                'delivered' => 'success',
                                'cancelled' => 'danger',
                                default => 'gray',
                            }),

                        Infolists\Components\TextEntry::make('payment_method')
                            ->label('طريقة الدفع')
                            ->formatStateUsing(fn (string $state): string => $state === 'cod' ? 'الدفع عند الاستلام' : 'بطاقة ائتمانية'),

                        Infolists\Components\TextEntry::make('created_at')
                            ->label('تاريخ الطلب')
                            ->dateTime('Y/m/d h:i A'),
                    ])->columns(3),

                Infolists\Components\Section::make('عنوان التوصيل')
                    ->schema([
                        Infolists\Components\TextEntry::make('address.full_address')
                            ->label('العنوان'),

                        Infolists\Components\TextEntry::make('address.phone')
                            ->label('هاتف التوصيل'),
                    ])->columns(2),

                Infolists\Components\Section::make('منتجات الطلب')
                    ->schema([
                        Infolists\Components\RepeatableEntry::make('items')
                            ->label('')
                            ->schema([
                                Infolists\Components\TextEntry::make('product_name')
                                    ->label('المنتج'),

                                Infolists\Components\TextEntry::make('price')
                                    ->label('السعر')
                                    ->money('SAR'),

                                Infolists\Components\TextEntry::make('quantity')
                                    ->label('الكمية'),

                                Infolists\Components\TextEntry::make('color')
                                    ->label('اللون')
                                    ->placeholder('—'),

                                Infolists\Components\TextEntry::make('size')
                                    ->label('المقاس')
                                    ->placeholder('—'),
                            ])
                            ->columns(5),
                    ]),

                Infolists\Components\Section::make('الملخص المالي')
                    ->schema([
                        Infolists\Components\TextEntry::make('subtotal')
                            ->label('المجموع الفرعي')
                            ->money('SAR'),

                        Infolists\Components\TextEntry::make('shipping')
                            ->label('الشحن')
                            ->money('SAR'),

                        Infolists\Components\TextEntry::make('total')
                            ->label('الإجمالي')
                            ->money('SAR')
                            ->weight('bold'),
                    ])->columns(3),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('order_number')
                    ->label('رقم الطلب')
                    ->searchable()
                    ->sortable(),

                Tables\Columns\TextColumn::make('user.name')
                    ->label('العميل')
                    ->searchable()
                    ->sortable(),

                Tables\Columns\TextColumn::make('items_count')
                    ->label('عدد المنتجات')
                    ->getStateUsing(fn (Order $record): int => (int) $record->items->sum('quantity')),

                Tables\Columns\TextColumn::make('total')
                    ->label('الإجمالي')
                    ->money('SAR')
                    ->sortable(),

                Tables\Columns\TextColumn::make('status')
                    ->label('الحالة')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => Order::STATUSES[$state] ?? $state)
                    ->color(fn (string $state): string => match ($state) {
                        'pending' => 'warning',
                        'processing' => 'info',
                        'shipped' => 'primary',
                        'delivered' => 'success',
                        'cancelled' => 'danger',
                        default => 'gray',
                    }),

                Tables\Columns\TextColumn::make('created_at')
                    ->label('التاريخ')
                    ->dateTime('Y/m/d h:i A')
                    ->sortable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->label('الحالة')
                    ->options(Order::STATUSES),

                Tables\Filters\Filter::make('created_at')
                    ->label('التاريخ')
                    ->form([
                        Forms\Components\DatePicker::make('from')->label('من تاريخ'),
                        Forms\Components\DatePicker::make('until')->label('إلى تاريخ'),
                    ])
                    ->query(function ($query, array $data) {
                        return $query
                            ->when($data['from'], fn ($q, $date) => $q->whereDate('created_at', '>=', $date))
                            ->when($data['until'], fn ($q, $date) => $q->whereDate('created_at', '<=', $date));
                    }),
            ])
            ->actions([
                Tables\Actions\ViewAction::make()->label('عرض'),
                Tables\Actions\EditAction::make()->label('تعديل'),

                Tables\Actions\Action::make('changeStatus')
                    ->label('تغيير الحالة')
                    ->icon('heroicon-o-arrow-path')
                    ->color('info')
                    ->form([
                        Forms\Components\Select::make('status')
                            ->label('الحالة الجديدة')
                            ->options(Order::STATUSES)
                            ->required()
                            ->default(fn (Order $record): string => $record->status),
                    ])
                    ->action(function (Order $record, array $data): void {
                        $record->update(['status' => $data['status']]);

                        \Filament\Notifications\Notification::make()
                            ->title('تم تحديث حالة الطلب')
                            ->body("تم إشعار العميل {$record->user->name} بالحالة الجديدة")
                            ->success()
                            ->send();
                    }),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make()->label('حذف المحدد'),
                ]),
            ])
            ->defaultSort('created_at', 'desc');
    }

    public static function getNavigationBadge(): ?string
    {
        $pending = Order::where('status', 'pending')->count();

        return $pending > 0 ? (string) $pending : null;
    }

    public static function getNavigationBadgeColor(): ?string
    {
        return 'warning';
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListOrders::route('/'),
            'create' => Pages\CreateOrder::route('/create'),
            'view' => Pages\ViewOrder::route('/{record}'),
            'edit' => Pages\EditOrder::route('/{record}/edit'),
        ];
    }
}
