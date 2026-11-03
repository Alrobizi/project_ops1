<?php

namespace Tests\Feature;

use App\Filament\Resources\UserResource\Pages\EditUser;
use App\Models\User;
use Filament\Facades\Filament;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;

/**
 * يتحقق من أن صلاحيات لوحة التحكم (admin_permissions) ظاهرة وقابلة للتعديل
 * من نموذج المستخدم في لوحة Filament.
 */
class UserPermissionsFormTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Filament::setCurrentPanel(Filament::getPanel('admin'));
    }

    private function makeSuperAdmin(string $email = 'super@store.test'): User
    {
        return User::create([
            'name' => 'مدير المتجر',
            'email' => $email,
            'phone' => '700000099',
            'role' => 'admin',
            'admin_permissions' => array_keys(User::ADMIN_PERMISSIONS_LABELS),
            'password' => bcrypt('password'),
        ]);
    }

    public function test_permissions_field_is_visible_for_admin(): void
    {
        $superAdmin = $this->makeSuperAdmin();
        $this->actingAs($superAdmin);

        Livewire::test(EditUser::class, ['record' => $superAdmin->getRouteKey()])
            ->assertSuccessful()
            ->assertFormFieldExists('admin_permissions')
            ->assertFormFieldIsEnabled('admin_permissions');
    }

    public function test_permissions_can_be_granted_from_the_form(): void
    {
        $superAdmin = $this->makeSuperAdmin();
        $this->actingAs($superAdmin);

        $target = User::create([
            'name' => 'أدمن جديد',
            'email' => 'new.admin@store.test',
            'phone' => '700000098',
            'role' => 'admin',
            'admin_permissions' => [],
            'password' => bcrypt('password'),
        ]);

        Livewire::test(EditUser::class, ['record' => $target->getRouteKey()])
            ->fillForm([
                'role' => 'admin',
                'admin_permissions' => ['products', 'orders'],
            ])
            ->call('save')
            ->assertHasNoFormErrors();

        $this->assertSame(['products', 'orders'], $target->refresh()->admin_permissions);
    }

    public function test_permissions_field_is_disabled_for_customers(): void
    {
        $superAdmin = $this->makeSuperAdmin();
        $this->actingAs($superAdmin);

        $customer = User::create([
            'name' => 'عميل',
            'email' => 'customer@store.test',
            'phone' => '700000097',
            'role' => 'customer',
            'password' => bcrypt('password'),
        ]);

        Livewire::test(EditUser::class, ['record' => $customer->getRouteKey()])
            ->assertFormFieldIsDisabled('admin_permissions');
    }
}
