<?php

namespace App\Filament\Resources;

use App\Filament\Resources\AdminNotificationResource\Pages;
use App\Models\AdminNotification;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class AdminNotificationResource extends Resource
{
    use \App\Filament\Concerns\RestrictsByAdminPermission;

    protected static ?string $model = AdminNotification::class;

    protected static ?string $adminPermission = 'marketing';

    protected static ?string $navigationIcon = 'heroicon-o-bell';

    protected static ?string $navigationLabel = 'الإشعارات';

    protected static ?string $modelLabel = 'إشعار';

    protected static ?string $pluralModelLabel = 'الإشعارات';

    
    protected static ?string $navigationGroup = 'المحتوى';

    protected static ?int $navigationSort = 3;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\TextInput::make('title')
                    ->label('العنوان')
                    ->required()
                    ->maxLength(255),

                Forms\Components\Textarea::make('body')
                    ->label('النص')
                    ->rows(4)
                    ->columnSpanFull(),

                Forms\Components\Select::make('type')
                    ->label('النوع')
                    ->options([
                        'general' => 'عام',
                        'order' => 'طلب',
                        'marketing' => 'تسويق',
                    ])
                    ->default('general'),

                Forms\Components\Toggle::make('is_sent')
                    ->label('تم الإرسال')
                    ->default(false),
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

                Tables\Columns\TextColumn::make('body')
                    ->label('النص')
                    ->limit(50)
                    ->color('gray'),

                Tables\Columns\TextColumn::make('type')
                    ->label('النوع')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'general' => 'عام',
                        'order' => 'طلب',
                        'marketing' => 'تسويق',
                        default => $state,
                    }),

                Tables\Columns\IconColumn::make('is_sent')
                    ->label('تم الإرسال')
                    ->boolean(),

                Tables\Columns\TextColumn::make('created_at')
                    ->label('التاريخ')
                    ->dateTime('Y/m/d')
                    ->sortable(),
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
            'index' => Pages\ListAdminNotifications::route('/'),
            'create' => Pages\CreateAdminNotification::route('/create'),
            'edit' => Pages\EditAdminNotification::route('/{record}/edit'),
        ];
    }
}