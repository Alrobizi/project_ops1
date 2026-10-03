<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminProductPermissionsTest extends TestCase
{
    use RefreshDatabase;

    private function loginAndGetToken(User $user): string
    {
        $response = $this->postJson('/api/login', [
            'email' => $user->email,
            'password' => 'password',
        ]);

        $response->assertStatus(200);

        return $response->json('data.token');
    }

    public function test_admin_with_products_permission_can_list_and_create_products(): void
    {
        $category = Category::create(['name' => 'إلكترونيات', 'type' => 'main', 'is_active' => true]);

        $admin = User::create([
            'name' => 'أدمن المنتجات',
            'email' => 'products.admin@store.test',
            'phone' => '700000002',
            'role' => 'admin',
            'admin_permissions' => ['products'],
            'password' => bcrypt('password'),
        ]);

        $token = $this->loginAndGetToken($admin);

        // قائمة المنتجات
        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/admin/products')
            ->assertStatus(200)
            ->assertJsonPath('success', true);

        // إضافة منتج جديد
        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/admin/products', [
                'category_id' => $category->id,
                'name' => 'سماعات بلوتوث',
                'price' => 1500,
                'old_price' => 2000,
                'currency' => 'YER',
                'stock' => 25,
            ])
            ->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.name', 'سماعات بلوتوث')
            ->assertJsonPath('data.price', 1500)
            ->assertJsonPath('data.old_price', 2000)
            ->assertJsonPath('data.stock', 25);

        $this->assertDatabaseHas('products', ['name' => 'سماعات بلوتوث', 'price' => 1500]);
    }

    public function test_admin_without_products_permission_is_forbidden(): void
    {
        $admin = User::create([
            'name' => 'أدمن التقارير',
            'email' => 'reports.admin@store.test',
            'phone' => '700000003',
            'role' => 'admin',
            'admin_permissions' => ['reports'],
            'password' => bcrypt('password'),
        ]);

        $token = $this->loginAndGetToken($admin);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/admin/products')
            ->assertStatus(403);
    }

    public function test_customer_cannot_access_admin_products(): void
    {
        User::create([
            'name' => 'عميل',
            'email' => 'customer@store.test',
            'phone' => '700000004',
            'role' => 'customer',
            'password' => bcrypt('password'),
        ]);

        $token = $this->loginAndGetToken(User::where('email', 'customer@store.test')->first());

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/admin/products')
            ->assertStatus(403);
    }

    public function test_customer_cannot_access_other_admin_routes(): void
    {
        User::create([
            'name' => 'عميل ثاني',
            'email' => 'customer2@store.test',
            'phone' => '700000006',
            'role' => 'customer',
            'password' => bcrypt('password'),
        ]);

        $token = $this->loginAndGetToken(User::where('email', 'customer2@store.test')->first());

        // مسارات الأدمن الأخرى محمية بـ middleware 'admin'
        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/admin/customers')
            ->assertStatus(403);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/admin/settings')
            ->assertStatus(403);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/admin/campaigns', ['title' => 'حملة', 'type' => 'عرض'])
            ->assertStatus(403);
    }

    public function test_admin_can_manage_categories(): void
    {
        $admin = User::create([
            'name' => 'مدير المتجر',
            'email' => 'owner@store.test',
            'phone' => '700000005',
            'role' => 'admin',
            'admin_permissions' => User::ADMIN_PERMISSIONS,
            'password' => bcrypt('password'),
        ]);

        $token = $this->loginAndGetToken($admin);

        // إضافة تصنيف
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/admin/categories', [
                'name' => 'أزياء',
                'type' => 'main',
            ])
            ->assertStatus(201)
            ->assertJsonPath('data.name', 'أزياء');

        $categoryId = $response->json('data.id');

        // تعديل التصنيف
        $this->withHeader('Authorization', "Bearer {$token}")
            ->putJson("/api/admin/categories/{$categoryId}", ['name' => 'أزياء نسائية'])
            ->assertStatus(200)
            ->assertJsonPath('data.name', 'أزياء نسائية');

        // حذف التصنيف
        $this->withHeader('Authorization', "Bearer {$token}")
            ->deleteJson("/api/admin/categories/{$categoryId}")
            ->assertStatus(200);
    }

    public function test_filament_resources_respect_admin_permissions(): void
    {
        // مدير بصلاحية المنتجات فقط
        $manager = User::create([
            'name' => 'مسؤول منتجات',
            'email' => 'filament.manager@store.test',
            'phone' => '700000007',
            'role' => 'admin',
            'admin_permissions' => ['products'],
            'password' => bcrypt('password'),
        ]);

        $this->actingAs($manager);

        $this->assertTrue(\App\Filament\Resources\ProductResource::canAccess());
        $this->assertTrue(\App\Filament\Resources\CategoryResource::canAccess());
        $this->assertFalse(\App\Filament\Resources\OrderResource::canAccess());
        $this->assertFalse(\App\Filament\Resources\UserResource::canAccess());
        $this->assertFalse(\App\Filament\Resources\SettingResource::canAccess());

        // أدمن ممنوح كل الأقسام صراحةً
        $owner = User::create([
            'name' => 'مالك المتجر',
            'email' => 'filament.owner@store.test',
            'phone' => '700000008',
            'role' => 'admin',
            'admin_permissions' => User::ADMIN_PERMISSIONS,
            'password' => bcrypt('password'),
        ]);

        $this->actingAs($owner);

        $this->assertTrue(\App\Filament\Resources\ProductResource::canAccess());
        $this->assertTrue(\App\Filament\Resources\UserResource::canAccess());
        $this->assertTrue(\App\Filament\Resources\OrderResource::canAccess());
        $this->assertTrue(\App\Filament\Resources\SettingResource::canAccess());
        $this->assertTrue(\App\Filament\Resources\CampaignResource::canAccess());
        $this->assertTrue(\App\Filament\Resources\BannerResource::canAccess());
    }

    public function test_admin_with_no_permissions_has_access_to_nothing(): void
    {
        // أدمن جديد بدون منح أي أقسام = افتراضياً بدون صلاحيات
        $freshAdmin = User::create([
            'name' => 'أدمن بلا صلاحيات',
            'email' => 'no.permissions@store.test',
            'phone' => '700000009',
            'role' => 'admin',
            'admin_permissions' => [],
            'password' => bcrypt('password'),
        ]);

        // لا يملك أي صلاحية على أي قسم (Filament)
        $this->actingAs($freshAdmin);

        $this->assertFalse(\App\Filament\Resources\ProductResource::canAccess());
        $this->assertFalse(\App\Filament\Resources\CategoryResource::canAccess());
        $this->assertFalse(\App\Filament\Resources\OrderResource::canAccess());
        $this->assertFalse(\App\Filament\Resources\UserResource::canAccess());
        $this->assertFalse(\App\Filament\Resources\SettingResource::canAccess());
        $this->assertFalse(\App\Filament\Resources\CampaignResource::canAccess());
        $this->assertFalse(\App\Filament\Resources\BannerResource::canAccess());
        $this->assertFalse(\App\Filament\Resources\DiscountResource::canAccess());
        $this->assertFalse(\App\Filament\Resources\PageResource::canAccess());
        $this->assertFalse(\App\Filament\Resources\FaqResource::canAccess());

        // لا يصل لأي مسار إداري في الـ API
        $token = $this->loginAndGetToken($freshAdmin);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/admin/products')
            ->assertStatus(403);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/admin/customers')
            ->assertStatus(403);
    }
}
