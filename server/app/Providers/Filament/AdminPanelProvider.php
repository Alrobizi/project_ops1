<?php

namespace App\Providers\Filament;

use App\Filament\Widgets\ModernStatsOverviewWidget;
use App\Filament\Widgets\ModernSalesAreaChartWidget;
use App\Filament\Widgets\OrderStatusDonutWidget;
use App\Filament\Widgets\TopSellingProductsWidget;
use App\Filament\Widgets\LatestOrdersWidget;
use Filament\Enums\ThemeMode;
use Filament\FontProviders\GoogleFontProvider;
use Filament\Http\Middleware\Authenticate;
use Filament\Http\Middleware\AuthenticateSession;
use Filament\Http\Middleware\DisableBladeIconComponents;
use Filament\Http\Middleware\DispatchServingFilamentEvent;
use Filament\Pages;
use Filament\Panel;
use Filament\PanelProvider;
use Filament\Support\Colors\Color;
use Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse;
use Illuminate\Cookie\Middleware\EncryptCookies;
use Illuminate\Foundation\Http\Middleware\VerifyCsrfToken;
use Illuminate\Routing\Middleware\SubstituteBindings;
use Illuminate\Session\Middleware\StartSession;
use Illuminate\View\Middleware\ShareErrorsFromSession;

class AdminPanelProvider extends PanelProvider
{
    public function panel(Panel $panel): Panel
    {
        return $panel
            ->default()
            ->id('admin')
            ->path('filament')
            ->login()
            ->brandName('بركة عدن')
            ->defaultThemeMode(ThemeMode::Light)
            ->font('Cairo', provider: GoogleFontProvider::class)
            ->colors([
                'primary' => Color::hex('#6D5DF6'),
                'info'    => Color::hex('#3B82F6'),
                'success' => Color::hex('#10B981'),
                'warning' => Color::hex('#F59E0B'),
                'danger'  => Color::hex('#EF4444'),
            ])
            // Custom theme (compiled with Tailwind v3 CLI)
            ->theme(asset('css/filament/admin/theme.css'))
            ->discoverResources(in: app_path('Filament/Resources'), for: 'App\\Filament\\Resources')
            ->discoverPages(in: app_path('Filament/Pages'), for: 'App\\Filament\\Pages')
            ->pages([
                \App\Filament\Pages\Dashboard::class,
            ])
            // Only register the modern widgets explicitly — discoverWidgets is disabled
            ->widgets([
                ModernStatsOverviewWidget::class,
                ModernSalesAreaChartWidget::class,
                OrderStatusDonutWidget::class,
                TopSellingProductsWidget::class,
                LatestOrdersWidget::class,
            ])
            ->middleware([
                EncryptCookies::class,
                AddQueuedCookiesToResponse::class,
                StartSession::class,
                AuthenticateSession::class,
                ShareErrorsFromSession::class,
                VerifyCsrfToken::class,
                SubstituteBindings::class,
                DisableBladeIconComponents::class,
                DispatchServingFilamentEvent::class,
            ])
            ->authMiddleware([
                Authenticate::class,
            ]);
    }
}
