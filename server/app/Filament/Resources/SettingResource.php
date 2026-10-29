<?php

namespace App\Filament\Resources;

use App\Filament\Resources\SettingResource\Pages;
use App\Models\Setting;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class SettingResource extends Resource
{
    use \App\Filament\Concerns\RestrictsByAdminPermission;

    protected static ?string $model = Setting::class;

    protected static ?string $adminPermission = 'settings';

    protected static ?string $navigationIcon = 'heroicon-o-cog';

    protected static ?string $navigationLabel = 'الإعدادات';

    protected static ?string $modelLabel = 'إعداد';

    protected static ?string $pluralModelLabel = 'الإعدادات';

    
    protected static ?string $navigationGroup = 'الإعدادات';

    protected static ?int $navigationSort = 1;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\TextInput::make('key')
                    ->label('المفتاح')
                    ->required()
                    ->unique(ignoreRecord: true)
                    ->maxLength(255)
                    ->disabled(fn (string $operation): bool => $operation === 'edit'),

                Forms\Components\TextInput::make('value')
                    ->label('القيمة')
                    ->required(),

                Forms\Components\Select::make('group')
                    ->label('المجموعة')
                    ->options([
                        'general' => 'عام',
                        'payment' => 'الدفع',
                        'shipping' => 'الشحن',
                        'notification' => 'الإشعارات',
                    ])
                    ->required(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('key')
                    ->label('المفتاح')
                    ->searchable()
                    ->sortable()
                    ->badge()
                    ->color('primary'),

                Tables\Columns\TextColumn::make('value')
                    ->label('القيمة')
                    ->searchable()
                    ->limit(50),

                Tables\Columns\TextColumn::make('group')
                    ->label('المجموعة')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'general' => 'info',
                        'payment' => 'success',
                        'shipping' => 'warning',
                        'notification' => 'primary',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'general' => 'عام',
                        'payment' => 'الدفع',
                        'shipping' => 'الشحن',
                        'notification' => 'الإشعارات',
                        default => $state,
                    }),
            ])
            ->defaultSort('group')
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
            'index' => Pages\ListSettings::route('/'),
            'create' => Pages\CreateSetting::route('/create'),
            'edit' => Pages\EditSetting::route('/{record}/edit'),
        ];
    }
}