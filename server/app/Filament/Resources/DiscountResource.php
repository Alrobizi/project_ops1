<?php

namespace App\Filament\Resources;

use App\Filament\Resources\DiscountResource\Pages;
use App\Models\Discount;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class DiscountResource extends Resource
{
    use \App\Filament\Concerns\RestrictsByAdminPermission;

    protected static ?string $model = Discount::class;

    protected static ?string $adminPermission = 'discounts';

    protected static ?string $navigationIcon = 'heroicon-o-ticket';

    protected static ?string $navigationLabel = 'الخصومات';

    protected static ?string $modelLabel = 'خصم';

    protected static ?string $pluralModelLabel = 'الخصومات';

    
    protected static ?string $navigationGroup = 'الخصومات';

    protected static ?int $navigationSort = 1;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\TextInput::make('code')
                    ->label('كود الخصم')
                    ->required()
                    ->unique(ignoreRecord: true)
                    ->maxLength(50)
                    ->uppercase(),

                Forms\Components\Select::make('type')
                    ->label('نوع الخصم')
                    ->options([
                        'نسبة مئوية' => 'نسبة مئوية',
                        'مبلغ ثابت' => 'مبلغ ثابت',
                    ])
                    ->default('نسبة مئوية')
                    ->required(),

                Forms\Components\TextInput::make('value')
                    ->label('قيمة الخصم')
                    ->numeric()
                    ->required()
                    ->prefix(fn (Forms\Get $get) => $get('type') === 'نسبة مئوية' ? '%' : 'ر.ي'),

                Forms\Components\TextInput::make('min_order')
                    ->label('الحد الأدنى للطلب')
                    ->numeric()
                    ->prefix('ر.ي')
                    ->default(0),

                Forms\Components\TextInput::make('max_usage')
                    ->label('الحد الأقصى للاستخدام')
                    ->numeric()
                    ->default(100),

                Forms\Components\TextInput::make('used_count')
                    ->label('عدد الاستخدامات')
                    ->numeric()
                    ->default(0)
                    ->disabled(),

                Forms\Components\Select::make('status')
                    ->label('الحالة')
                    ->options([
                        'active' => 'نشط',
                        'expired' => 'منتهي',
                        'scheduled' => 'مجدول',
                    ])
                    ->default('active')
                    ->required(),

                Forms\Components\DatePicker::make('start_date')
                    ->label('تاريخ البداية'),

                Forms\Components\DatePicker::make('end_date')
                    ->label('تاريخ النهاية'),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('code')
                    ->label('الكود')
                    ->searchable()
                    ->sortable()
                    ->badge()
                    ->color('primary'),

                Tables\Columns\TextColumn::make('type')
                    ->label('النوع')
                    ->badge(),

                Tables\Columns\TextColumn::make('value')
                    ->label('القيمة')
                    ->formatStateUsing(fn ($state, $record) => $record->type === 'نسبة مئوية' ? $state . '%' : $state . ' ر.ي')
                    ->sortable(),

                Tables\Columns\TextColumn::make('min_order')
                    ->label('الحد الأدنى')
                    ->money('YER'),

                Tables\Columns\TextColumn::make('used_count')
                    ->label('الاستخدام')
                    ->formatStateUsing(fn ($state, $record) => $state . ' / ' . $record->max_usage),

                Tables\Columns\TextColumn::make('status')
                    ->label('الحالة')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'active' => 'success',
                        'expired' => 'danger',
                        'scheduled' => 'warning',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'active' => 'نشط',
                        'expired' => 'منتهي',
                        'scheduled' => 'مجدول',
                        default => $state,
                    }),
            ])
            ->defaultSort('created_at', 'desc')
            ->actions([
                Tables\Actions\EditAction::make()->label('تعديل'),
                Tables\Actions\DeleteAction::make()->label('حذف'),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make()->label('حذف المحدد'),
                ]),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListDiscounts::route('/'),
            'create' => Pages\CreateDiscount::route('/create'),
            'edit' => Pages\EditDiscount::route('/{record}/edit'),
        ];
    }
}