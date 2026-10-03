<?php

namespace App\Filament\Resources;

use App\Filament\Resources\UserResource\Pages;
use App\Models\User;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Support\Facades\Hash;

class UserResource extends Resource
{
    use \App\Filament\Concerns\RestrictsByAdminPermission;

    protected static ?string $model = User::class;

    protected static ?string $adminPermission = 'users';

    protected static ?string $navigationIcon = 'heroicon-o-users';

    protected static ?string $navigationLabel = 'المستخدمون';

    protected static ?string $modelLabel = 'مستخدم';

    protected static ?string $pluralModelLabel = 'المستخدمون';

    
    protected static ?string $navigationGroup = 'العملاء';

    protected static ?int $navigationSort = 1;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\TextInput::make('name')
                    ->label('الاسم')
                    ->required()
                    ->maxLength(255),

                Forms\Components\TextInput::make('email')
                    ->label('البريد الإلكتروني')
                    ->email()
                    ->required()
                    ->unique(ignoreRecord: true),

                Forms\Components\TextInput::make('phone')
                    ->label('رقم الجوال')
                    ->tel()
                    ->maxLength(20),

                Forms\Components\Select::make('role')
                    ->label('الصلاحية')
                    ->options([
                        'admin' => 'أدمن',
                        'customer' => 'عميل',
                    ])
                    ->required()
                    ->default('customer')
                    ->live(),

                Forms\Components\CheckboxList::make('admin_permissions')
                    ->label('أقسام لوحة التحكم المسموحة')
                    ->options(User::ADMIN_PERMISSIONS_LABELS)
                    ->columns(2)
                    ->helperText('افتراضياً بدون أي صلاحيات — حدد الأقسام التي تريد منحها لهذا الأدمن')
                    ->visible(fn (Forms\Get $get): bool => $get('role') === 'admin')
                    ->dehydrated(fn (Forms\Get $get): bool => $get('role') === 'admin'),

                Forms\Components\TextInput::make('password')
                    ->label('كلمة المرور')
                    ->password()
                    ->revealable()
                    ->dehydrateStateUsing(fn (string $state): string => Hash::make($state))
                    ->dehydrated(fn (?string $state): bool => filled($state))
                    ->required(fn (string $operation): bool => $operation === 'create')
                    ->minLength(6),

                Forms\Components\Toggle::make('is_blocked')
                    ->label('محظور')
                    ->default(false),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('name')
                    ->label('الاسم')
                    ->searchable()
                    ->sortable(),

                Tables\Columns\TextColumn::make('email')
                    ->label('البريد الإلكتروني')
                    ->searchable(),

                Tables\Columns\TextColumn::make('phone')
                    ->label('رقم الجوال'),

                Tables\Columns\TextColumn::make('role')
                    ->label('الصلاحية')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => $state === 'admin' ? 'أدمن' : 'عميل')
                    ->color(fn (string $state): string => $state === 'admin' ? 'primary' : 'gray'),

                Tables\Columns\TextColumn::make('admin_permissions')
                    ->label('أقسام لوحة التحكم')
                    ->badge()
                    ->state(function (User $record): array {
                        if ($record->role !== 'admin') {
                            return [];
                        }

                        $permissions = $record->admin_permissions ?? [];

                        if (empty($permissions)) {
                            return ['بدون صلاحيات'];
                        }

                        return collect($permissions)
                            ->map(fn ($p) => User::ADMIN_PERMISSIONS_LABELS[$p] ?? $p)
                            ->values()
                            ->toArray();
                    })
                    ->color(fn (User $record): string => empty($record->admin_permissions) ? 'gray' : 'success'),

                Tables\Columns\TextColumn::make('orders_count')
                    ->label('عدد الطلبات')
                    ->counts('orders')
                    ->sortable(),

                Tables\Columns\IconColumn::make('is_blocked')
                    ->label('محظور')
                    ->boolean()
                    ->trueColor('danger'),

                Tables\Columns\TextColumn::make('created_at')
                    ->label('تاريخ التسجيل')
                    ->date('Y/m/d')
                    ->sortable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('role')
                    ->label('الصلاحية')
                    ->options([
                        'admin' => 'أدمن',
                        'customer' => 'عميل',
                    ]),

                Tables\Filters\TernaryFilter::make('is_blocked')
                    ->label('محظور'),
            ])
            ->actions([
                Tables\Actions\EditAction::make()->label('تعديل'),

                Tables\Actions\Action::make('toggleBlock')
                    ->label(fn (User $record): string => $record->is_blocked ? 'إلغاء الحظر' : 'حظر')
                    ->icon(fn (User $record): string => $record->is_blocked ? 'heroicon-o-lock-open' : 'heroicon-o-lock-closed')
                    ->color(fn (User $record): string => $record->is_blocked ? 'success' : 'danger')
                    ->requiresConfirmation()
                    ->action(fn (User $record) => $record->update(['is_blocked' => ! $record->is_blocked])),

                Tables\Actions\Action::make('toggleRole')
                    ->label(fn (User $record): string => $record->role === 'admin' ? 'تحويل لعميل' : 'تحويل لأدمن')
                    ->icon('heroicon-o-shield-check')
                    ->color('warning')
                    ->requiresConfirmation()
                    ->action(fn (User $record) => $record->update([
                        'role' => $record->role === 'admin' ? 'customer' : 'admin',
                    ])),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make()->label('حذف المحدد'),
                ]),
            ])
            ->defaultSort('created_at', 'desc');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListUsers::route('/'),
            'create' => Pages\CreateUser::route('/create'),
            'edit' => Pages\EditUser::route('/{record}/edit'),
        ];
    }
}
