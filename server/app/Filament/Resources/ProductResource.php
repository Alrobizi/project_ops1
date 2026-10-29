<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ProductResource\Pages;
use App\Models\Product;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class ProductResource extends Resource
{
    use \App\Filament\Concerns\RestrictsByAdminPermission;

    protected static ?string $model = Product::class;

    protected static ?string $adminPermission = 'products';

    protected static ?string $navigationIcon = 'heroicon-o-shopping-bag';

    protected static ?string $navigationLabel = 'المنتجات';

    protected static ?string $modelLabel = 'منتج';

    protected static ?string $pluralModelLabel = 'المنتجات';

    
    protected static ?string $navigationGroup = 'المنتجات';

    protected static ?int $navigationSort = 1;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('المعلومات الأساسية')
                    ->schema([
                        Forms\Components\TextInput::make('name')
                            ->label('اسم المنتج')
                            ->required()
                            ->maxLength(255)
                            ->columnSpanFull(),

                        Forms\Components\RichEditor::make('description')
                            ->label('الوصف')
                            ->columnSpanFull(),

                        Forms\Components\Select::make('category_id')
                            ->label('التصنيف')
                            ->relationship('category', 'name')
                            ->searchable()
                            ->preload()
                            ->required(),
                    ])->columns(2),

                Forms\Components\Section::make('السعر والمخزون')
                    ->schema([
                        Forms\Components\TextInput::make('price')
                            ->label('السعر')
                            ->numeric()
                            ->required()
                            ->minValue(0),

                        Forms\Components\TextInput::make('old_price')
                            ->label('السعر قبل الخصم')
                            ->numeric()
                            ->minValue(0),

                        Forms\Components\Select::make('currency')
                            ->label('العملة')
                            ->options(Product::CURRENCIES)
                            ->default('YER')
                            ->required(),

                        Forms\Components\TextInput::make('stock')
                            ->label('الكمية بالمخزون')
                            ->numeric()
                            ->required()
                            ->minValue(0)
                            ->default(0)
                            ->helperText('تنبيه تلقائي عندما تقل الكمية عن 10'),
                    ])->columns(3),

                Forms\Components\Section::make('الصور')
                    ->schema([
                        Forms\Components\FileUpload::make('image')
                            ->label('الصورة الرئيسية')
                            ->image()
                            ->imageEditor()
                            ->imageEditorAspectRatios([
                                '1:1',
                                '4:3',
                                '16:9',
                            ])
                            ->maxSize(10240)
                            ->directory('products')
                            ->helperText('يمكنك قص وتعديل الصورة بمرونة. الحد الأقصى للحجم: 10 ميجابايت'),

                        Forms\Components\Repeater::make('images')
                            ->label('صور إضافية')
                            ->relationship('images')
                            ->schema([
                                Forms\Components\FileUpload::make('path')
                                    ->label('الصورة')
                                    ->image()
                                    ->imageEditor()
                                    ->imageEditorAspectRatios([
                                        '1:1',
                                    ])
                                    ->maxSize(10240)
                                    ->directory('products')
                                    ->required(),

                                Forms\Components\TextInput::make('sort_order')
                                    ->label('الترتيب')
                                    ->numeric()
                                    ->default(0),
                            ])
                            ->columns(2)
                            ->defaultItems(0)
                            ->columnSpanFull(),
                    ]),

                Forms\Components\Section::make('الخيارات')
                    ->schema([
                        Forms\Components\TagsInput::make('colors')
                            ->label('الألوان المتاحة')
                            ->placeholder('أضف لوناً'),

                        Forms\Components\TagsInput::make('sizes')
                            ->label('المقاسات المتاحة')
                            ->placeholder('أضف مقاساً'),

                        Forms\Components\Toggle::make('is_featured')
                            ->label('منتج مميز')
                            ->default(false),

                        Forms\Components\Toggle::make('is_active')
                            ->label('ظاهر في التطبيق')
                            ->default(true),
                    ])->columns(2),

                // =====================================================
                // [الموقع الجغرافي] موقع البائع - إتاحة اختيار المحافظة
                // والمديرية أو تحديد الإحداثيات يدوياً عبر الخريطة.
                // الافتراضي: اليمن - عدن - كريتر (جنوب اليمن).
                // =====================================================
                Forms\Components\Section::make('موقع البائع (التحديد الجغرافي)')
                    ->description('يُستخدم لترتيب المنتجات حسب الأقرب للمشتري ولحساب تكلفة وزمن التوصيل')
                    ->schema([
                        Forms\Components\TextInput::make('seller_name')
                            ->label('اسم البائع / المتجر')
                            ->default('متجر بركة عدن')
                            ->maxLength(255)
                            ->required(),

                        Forms\Components\Select::make('seller_governorate')
                            ->label('المحافظة')
                            ->options([
                                'عدن' => 'عدن',
                                'لحج' => 'لحج',
                                'أبين' => 'أبين',
                                'ضالع' => 'ضالع',
                                'تعز' => 'تعز',
                                'صنعاء' => 'صنعاء',
                                'الحديدة' => 'الحديدة',
                                'إب' => 'إب',
                                'ذمار' => 'ذمار',
                                'شبوة' => 'شبوة',
                                'حضرموت' => 'حضرموت',
                                'مأرب' => 'مأرب',
                                'البيضاء' => 'البيضاء',
                                'الجوف' => 'الجوف',
                                'عمران' => 'عمران',
                                'صعدة' => 'صعدة',
                                'ريمة' => 'ريمة',
                                'المهرّة' => 'المهرّة',
                                'سقطرى' => 'سقطرى',
                            ])
                            ->default('عدن')
                            ->live()
                            ->required(),

                        // مديريات عدن الثمانية عند اختيار محافظة عدن
                        Forms\Components\Select::make('seller_city')
                            ->label('المدينة / المديرية (عدن)')
                            ->options([
                                'كريتر' => 'كريتر',
                                'التواهي' => 'التواهي',
                                'المعلا' => 'المعلا',
                                'خور مكسر' => 'خور مكسر',
                                'الشيخ عثمان' => 'الشيخ عثمان',
                                'المنصورة' => 'المنصورة',
                                'دار سعد' => 'دار سعد',
                                'بورمياء' => 'بورمياء',
                            ])
                            ->default('كريتر')
                            ->visible(fn (Forms\Get $get): bool => ($get('seller_governorate') ?? 'عدن') === 'عدن')
                            ->required(),

                        // مدينة حرة عند اختيار محافظة غير عدن
                        Forms\Components\TextInput::make('seller_city')
                            ->label('المدينة / المديرية')
                            ->maxLength(100)
                            ->visible(fn (Forms\Get $get): bool => ($get('seller_governorate') ?? 'عدن') !== 'عدن')
                            ->required(),

                        Forms\Components\TextInput::make('seller_latitude')
                            ->label('خط العرض (Latitude)')
                            ->numeric()
                            ->default(12.7917)
                            ->helperText('يمكن نسخه من خرائط Google لموقع المتجر بدقة'),

                        Forms\Components\TextInput::make('seller_longitude')
                            ->label('خط الطول (Longitude)')
                            ->numeric()
                            ->default(45.0067)
                            ->helperText('الإحداثيات الافتراضية: عدن - كريتر'),
                    ])->columns(3),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\ImageColumn::make('image')
                    ->label('الصورة')
                    ->circular(),

                Tables\Columns\TextColumn::make('name')
                    ->label('الاسم')
                    ->searchable()
                    ->sortable()
                    ->limit(30),

                Tables\Columns\TextColumn::make('category.name')
                    ->label('التصنيف')
                    ->sortable()
                    ->badge()
                    ->color('info'),

                Tables\Columns\TextColumn::make('price')
                    ->label('السعر')
                    ->money(fn (Product $record): string => $record->currency ?? 'SAR')
                    ->sortable(),

                Tables\Columns\TextColumn::make('currency')
                    ->label('العملة')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => $state === 'YER' ? 'ر.ي' : 'ر.س')
                    ->color(fn (string $state): string => $state === 'YER' ? 'warning' : 'success'),

                Tables\Columns\TextColumn::make('stock')
                    ->label('الكمية')
                    ->sortable()
                    ->color(fn (Product $record): string => match ($record->stock_status) {
                        'out_of_stock' => 'danger',
                        'low_stock' => 'warning',
                        default => 'success',
                    }),

                Tables\Columns\TextColumn::make('stock_status')
                    ->label('الحالة')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'in_stock' => 'متوفر',
                        'low_stock' => 'قليل المخزون',
                        'out_of_stock' => 'نفد',
                        default => $state,
                    })
                    ->color(fn (string $state): string => match ($state) {
                        'in_stock' => 'success',
                        'low_stock' => 'warning',
                        'out_of_stock' => 'danger',
                        default => 'gray',
                    }),

                Tables\Columns\IconColumn::make('is_featured')
                    ->label('مميز')
                    ->boolean(),

                // [الموقع الجغرافي] عمود موقع البائع (المحافظة + المديرية)
                Tables\Columns\TextColumn::make('seller_location')
                    ->label('موقع البائع')
                    ->state(fn (Product $record): string => $record->seller_governorate.' - '.$record->seller_city)
                    ->badge()
                    ->color('primary')
                    ->sortable(query: fn (Builder $query, string $direction): Builder =>
                        $query->orderBy('seller_governorate', $direction)),

                Tables\Columns\ToggleColumn::make('is_active')
                    ->label('ظاهر في التطبيق'),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('currency')
                    ->label('العملة')
                    ->options(Product::CURRENCIES),

                Tables\Filters\SelectFilter::make('category_id')
                    ->label('التصنيف')
                    ->relationship('category', 'name'),

                // [الموقع الجغرافي] فلتر المحافظة (اليمن)
                Tables\Filters\SelectFilter::make('seller_governorate')
                    ->label('المحافظة')
                    ->options([
                        'عدن' => 'عدن',
                        'لحج' => 'لحج',
                        'أبين' => 'أبين',
                        'ضالع' => 'ضالع',
                        'تعز' => 'تعز',
                        'صنعاء' => 'صنعاء',
                        'الحديدة' => 'الحديدة',
                        'إب' => 'إب',
                        'ذمار' => 'ذمار',
                        'شبوة' => 'شبوة',
                        'حضرموت' => 'حضرموت',
                        'مأرب' => 'مأرب',
                        'البيضاء' => 'البيضاء',
                        'الجوف' => 'الجوف',
                        'عمران' => 'عمران',
                        'صعدة' => 'صعدة',
                        'ريمة' => 'ريمة',
                        'المهرّة' => 'المهرّة',
                        'سقطرى' => 'سقطرى',
                    ]),

                Tables\Filters\SelectFilter::make('stock_status')
                    ->label('حالة المخزون')
                    ->options([
                        'in_stock' => 'متوفر',
                        'low_stock' => 'قليل المخزون',
                        'out_of_stock' => 'نفد',
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        return match ($data['value'] ?? null) {
                            'in_stock' => $query->where('stock', '>=', Product::LOW_STOCK_THRESHOLD),
                            'low_stock' => $query->where('stock', '>', 0)->where('stock', '<', Product::LOW_STOCK_THRESHOLD),
                            'out_of_stock' => $query->where('stock', '<=', 0),
                            default => $query,
                        };
                    }),

                Tables\Filters\TernaryFilter::make('is_featured')
                    ->label('منتج مميز'),

                Tables\Filters\TernaryFilter::make('is_active')
                    ->label('ظاهر في التطبيق'),
            ])
            ->actions([
                Tables\Actions\EditAction::make()->label('تعديل'),
                Tables\Actions\DeleteAction::make()->label('حذف'),
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
        $lowStock = Product::where('stock', '>', 0)
            ->where('stock', '<', Product::LOW_STOCK_THRESHOLD)
            ->count();

        return $lowStock > 0 ? (string) $lowStock : null;
    }

    public static function getNavigationBadgeColor(): ?string
    {
        return 'warning';
    }

    public static function getNavigationBadgeTooltip(): ?string
    {
        return 'منتجات قليلة المخزون';
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListProducts::route('/'),
            'create' => Pages\CreateProduct::route('/create'),
            'edit' => Pages\EditProduct::route('/{record}/edit'),
        ];
    }
}
