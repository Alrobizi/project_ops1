<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CategoryResource\Pages;
use App\Models\Category;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Livewire\Features\SupportFileUploads\TemporaryUploadedFile;

class CategoryResource extends Resource
{
    use \App\Filament\Concerns\RestrictsByAdminPermission;

    protected static ?string $model = Category::class;

    protected static ?string $adminPermission = 'products';

    protected static ?string $navigationIcon = 'heroicon-o-squares-2x2';

    protected static ?string $navigationLabel = 'التصنيفات';

    protected static ?string $modelLabel = 'تصنيف';

    protected static ?string $pluralModelLabel = 'التصنيفات';

    
    protected static ?string $navigationGroup = 'المنتجات';

    protected static ?int $navigationSort = 2;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('معلومات التصنيف')
                    ->schema([
                        Forms\Components\Select::make('type')
                            ->label('النوع')
                            ->options([
                                'main' => 'تصنيف رئيسي',
                                'sub' => 'تصنيف فرعي',
                                'marketing' => 'قسم تسويقي',
                            ])
                            ->default('main')
                            ->required()
                            ->live()
                            ->afterStateUpdated(fn (Forms\Set $set) => $set('parent_id', null)),

                        Forms\Components\Select::make('parent_id')
                            ->label('التصنيف الأب')
                            ->relationship('parent', 'name')
                            ->searchable()
                            ->preload()
                            ->placeholder('اختر التصنيف الأب (للأقسام الفرعية)')
                            ->visible(fn (Forms\Get $get) => $get('type') === 'sub')
                            ->required(fn (Forms\Get $get) => $get('type') === 'sub'),

                        Forms\Components\TextInput::make('name')
                            ->label('الاسم')
                            ->required()
                            ->maxLength(255)
                            ->live(onBlur: true)
                            ->afterStateUpdated(fn (Forms\Set $set, $state) => $set('slug', Str::slug($state))),

                        Forms\Components\TextInput::make('slug')
                            ->label('المعرّف (Slug)')
                            ->maxLength(255)
                            ->helperText('يُولّد تلقائياً من الاسم'),

                        Forms\Components\TextInput::make('badge')
                            ->label('الشارة (Badge)')
                            ->helperText('إيموجي أو نص قصير يظهر بجانب القسم التسويقي مثل: 🔥, ✨, ⭐')
                            ->maxLength(50)
                            ->visible(fn (Forms\Get $get) => $get('type') === 'marketing'),

                        Forms\Components\TextInput::make('icon')
                            ->label('الأيقونة')
                            ->helperText('اسم أيقونة Material مثل: checkroom, watch, shopping_bag, backpack, spa')
                            ->maxLength(255),

                        Forms\Components\FileUpload::make('image')
                            ->label('الصورة')
                            ->image()
                            ->maxSize(10240)
                            ->helperText('يتم ضبط الصورة تلقائياً إلى مقاس مربع 300×300 بكسل عند الرفع، دون أي تعديل يدوي')
                            ->saveUploadedFileUsing(function (TemporaryUploadedFile $file): ?string {
                                $source = @imagecreatefromstring(
                                    file_get_contents($file->getRealPath())
                                );

                                if ($source === false) {
                                    return null;
                                }

                                $width = imagesx($source);
                                $height = imagesy($source);
                                $side = min($width, $height);
                                $srcX = intdiv($width - $side, 2);
                                $srcY = intdiv($height - $side, 2);
                                $targetSize = 300;

                                $resized = imagecreatetruecolor($targetSize, $targetSize);

                                // خلفية بيضاء للصور الشفافة (PNG / WebP)
                                $white = imagecolorallocate($resized, 255, 255, 255);
                                imagefill($resized, 0, 0, $white);

                                // قصّ مركزي مربع ثم تصغير إلى 300×300
                                imagecopyresampled(
                                    $resized,
                                    $source,
                                    0, 0,
                                    $srcX, $srcY,
                                    $targetSize, $targetSize,
                                    $side, $side
                                );

                                ob_start();
                                imagejpeg($resized, null, 85);
                                $contents = ob_get_clean();

                                imagedestroy($source);
                                imagedestroy($resized);

                                $path = 'categories/' . Str::ulid() . '.jpg';
                                Storage::disk('public')->put($path, $contents);

                                return $path;
                            }),

                        Forms\Components\TextInput::make('sort_order')
                            ->label('الترتيب')
                            ->numeric()
                            ->default(0),

                        Forms\Components\Toggle::make('is_active')
                            ->label('مفعّل')
                            ->default(true),
                    ])->columns(2),
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
                    ->description(fn (Category $record): ?string => $record->badge ? "شارة: {$record->badge}" : null),

                Tables\Columns\TextColumn::make('type')
                    ->label('النوع')
                    ->badge()
                    ->colors([
                        'primary' => 'main',
                        'warning' => 'sub',
                        'danger' => 'marketing',
                    ])
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'main' => 'رئيسي',
                        'sub' => 'فرعي',
                        'marketing' => 'تسويقي',
                        default => $state,
                    }),

                Tables\Columns\TextColumn::make('parent.name')
                    ->label('التصنيف الأب')
                    ->sortable()
                    ->placeholder('—')
                    ->toggleable(),

                Tables\Columns\TextColumn::make('badge')
                    ->label('الشارة')
                    ->placeholder('—')
                    ->toggleable(),

                Tables\Columns\TextColumn::make('products_count')
                    ->label('عدد المنتجات')
                    ->counts('products')
                    ->sortable(),

                Tables\Columns\TextColumn::make('sort_order')
                    ->label('الترتيب')
                    ->sortable()
                    ->toggleable(),

                Tables\Columns\ToggleColumn::make('is_active')
                    ->label('مفعّل'),
            ])
            ->defaultSort('sort_order')
            ->filters([
                Tables\Filters\TernaryFilter::make('is_active')
                    ->label('الحالة'),
                Tables\Filters\SelectFilter::make('type')
                    ->label('النوع')
                    ->options([
                        'main' => 'تصنيف رئيسي',
                        'sub' => 'تصنيف فرعي',
                        'marketing' => 'قسم تسويقي',
                    ]),
                Tables\Filters\SelectFilter::make('parent_id')
                    ->label('التصنيف الأب')
                    ->relationship('parent', 'name'),
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
            ->reorderable('sort_order');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListCategories::route('/'),
            'create' => Pages\CreateCategory::route('/create'),
            'edit' => Pages\EditCategory::route('/{record}/edit'),
        ];
    }
}
