<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CampaignResource\Pages;
use App\Models\Campaign;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class CampaignResource extends Resource
{
    use \App\Filament\Concerns\RestrictsByAdminPermission;

    protected static ?string $model = Campaign::class;

    protected static ?string $adminPermission = 'marketing';

    protected static ?string $navigationIcon = 'heroicon-o-megaphone';

    protected static ?string $navigationLabel = 'التسويق';

    protected static ?string $navigationGroup = 'التسويق';

    protected static ?string $modelLabel = 'حملة';

    protected static ?string $pluralModelLabel = 'الحملات التسويقية';

    protected static ?int $navigationSort = 1;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\TextInput::make('title')
                    ->label('عنوان الحملة')
                    ->required()
                    ->maxLength(255),

                Forms\Components\Select::make('type')
                    ->label('نوع الحملة')
                    ->options([
                        'حملة إعلانية' => 'حملة إعلانية',
                        'عرض ترويجي' => 'عرض ترويجي',
                        'إعلان ممول' => 'إعلان ممول',
                    ])
                    ->default('حملة إعلانية')
                    ->required(),

                Forms\Components\TextInput::make('budget')
                    ->label('الميزانية')
                    ->numeric()
                    ->prefix('ر.ي')
                    ->default(0),

                Forms\Components\TextInput::make('views')
                    ->label('المشاهدات')
                    ->numeric()
                    ->default(0)
                    ->disabled(),

                Forms\Components\TextInput::make('clicks')
                    ->label('النقرات')
                    ->numeric()
                    ->default(0)
                    ->disabled(),

                Forms\Components\DatePicker::make('start_date')
                    ->label('تاريخ البداية'),

                Forms\Components\DatePicker::make('end_date')
                    ->label('تاريخ النهاية'),

                Forms\Components\Toggle::make('is_active')
                    ->label('نشطة')
                    ->default(true),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('title')
                    ->label('العنوان')
                    ->searchable()
                    ->sortable(),

                Tables\Columns\TextColumn::make('type')
                    ->label('النوع')
                    ->badge(),

                Tables\Columns\TextColumn::make('budget')
                    ->label('الميزانية')
                    ->money('YER')
                    ->sortable(),

                Tables\Columns\TextColumn::make('views')
                    ->label('المشاهدات')
                    ->sortable(),

                Tables\Columns\TextColumn::make('clicks')
                    ->label('النقرات')
                    ->sortable(),

                Tables\Columns\ToggleColumn::make('is_active')
                    ->label('نشطة'),
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
            'index' => Pages\ListCampaigns::route('/'),
            'create' => Pages\CreateCampaign::route('/create'),
            'edit' => Pages\EditCampaign::route('/{record}/edit'),
        ];
    }
}