<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

/**
 * اختبارات تسجيل الدخول بواسطة Google.
 *
 * الخادم لا يثق ببيانات الهوية القادمة من التطبيق، بل يتحقق منها
 * مع خدمة TokenInfo الرسمية لـ Google قبل إنشاء الحساب/الجلسة.
 */
class GoogleLoginTest extends TestCase
{
    use RefreshDatabase;

    private const CLIENT_ID = '866528014908-ubkmbauq5ffitlqvc1ffc37f0k92uff0.apps.googleusercontent.com';

    /**
     * @param  array<string, mixed>  $overrides
     * @return array<string, mixed>
     */
    private function googleProfile(array $overrides = []): array
    {
        return array_merge([
            'aud' => self::CLIENT_ID,
            'sub' => '110000000000000000001',
            'email' => 'google.user@store.test',
            'email_verified' => 'true',
            'name' => 'مستخدم جوجل',
            'picture' => 'https://example.test/avatar.png',
        ], $overrides);
    }

    public function test_google_login_requires_a_google_credential(): void
    {
        Http::fake();

        $this->postJson('/api/google-login', [
            'email' => 'attacker@store.test',
            'name' => 'مهاجم',
            'google_id' => '999999',
        ])->assertStatus(422);

        $this->assertDatabaseMissing('users', ['email' => 'attacker@store.test']);
    }

    public function test_google_login_creates_user_from_verified_profile(): void
    {
        Http::fake([
            'oauth2.googleapis.com/tokeninfo*' => Http::response($this->googleProfile()),
        ]);

        $response = $this->postJson('/api/google-login', [
            'id_token' => 'fake-id-token',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.user.email', 'google.user@store.test')
            ->assertJsonPath('data.user.name', 'مستخدم جوجل')
            ->assertJsonStructure(['data' => ['token', 'user' => ['id']]]);

        $this->assertDatabaseHas('users', [
            'email' => 'google.user@store.test',
            'google_id' => '110000000000000000001',
        ]);
    }

    public function test_google_login_verifies_web_access_token(): void
    {
        Http::fake([
            'www.googleapis.com/oauth2/v3/tokeninfo*' => Http::response($this->googleProfile([
                'sub' => '220000000000000000002',
                'email' => 'web.user@store.test',
            ])),
        ]);

        $this->postJson('/api/google-login', [
            'access_token' => 'fake-access-token',
        ])
            ->assertStatus(200)
            ->assertJsonPath('data.user.email', 'web.user@store.test');

        $this->assertDatabaseHas('users', ['email' => 'web.user@store.test']);
    }

    public function test_google_login_accepts_tokeninfo_access_token_shape(): void
    {
        // شكل الاستجابة الفعلي الذي تعيده نقطة نهاية tokeninfo للـ access token
        Http::fake([
            'www.googleapis.com/oauth2/v3/tokeninfo*' => Http::response([
                'issued_to' => self::CLIENT_ID,
                'audience' => self::CLIENT_ID,
                'user_id' => '550000000000000000005',
                'email' => 'legacy.web@store.test',
                'verified_email' => true,
                'expires_in' => 3599,
            ]),
        ]);

        $this->postJson('/api/google-login', ['access_token' => 'fake-access-token'])
            ->assertStatus(200)
            ->assertJsonPath('data.user.email', 'legacy.web@store.test');

        $this->assertDatabaseHas('users', [
            'email' => 'legacy.web@store.test',
            'google_id' => '550000000000000000005',
        ]);
    }

    public function test_google_login_ignores_unverified_identity_sent_by_client(): void
    {
        Http::fake([
            'oauth2.googleapis.com/tokeninfo*' => Http::response($this->googleProfile()),
        ]);

        $this->postJson('/api/google-login', [
            'id_token' => 'fake-id-token',
            'email' => 'victim@store.test',
            'name' => 'منتحل',
            'google_id' => 'victim-google-id',
        ])
            ->assertStatus(200)
            ->assertJsonPath('data.user.email', 'google.user@store.test');

        $this->assertDatabaseMissing('users', ['email' => 'victim@store.test']);
        $this->assertDatabaseMissing('users', ['google_id' => 'victim-google-id']);
    }

    public function test_google_login_rejects_token_for_another_client(): void
    {
        Http::fake([
            'oauth2.googleapis.com/tokeninfo*' => Http::response($this->googleProfile([
                'aud' => 'another-app.apps.googleusercontent.com',
            ])),
        ]);

        $this->postJson('/api/google-login', ['id_token' => 'fake-id-token'])
            ->assertStatus(401);

        $this->assertDatabaseCount('users', 0);
    }

    public function test_google_login_rejects_unverified_email(): void
    {
        Http::fake([
            'oauth2.googleapis.com/tokeninfo*' => Http::response($this->googleProfile([
                'email_verified' => 'false',
            ])),
        ]);

        $this->postJson('/api/google-login', ['id_token' => 'fake-id-token'])
            ->assertStatus(401);

        $this->assertDatabaseCount('users', 0);
    }

    public function test_google_login_rejects_invalid_token(): void
    {
        Http::fake([
            'oauth2.googleapis.com/tokeninfo*' => Http::response(['error' => 'invalid_token'], 400),
        ]);

        $this->postJson('/api/google-login', ['id_token' => 'invalid-token'])
            ->assertStatus(401);

        $this->assertDatabaseCount('users', 0);
    }

    public function test_google_login_links_existing_account_with_same_email(): void
    {
        $user = User::create([
            'name' => 'عميل قديم',
            'email' => 'existing@store.test',
            'phone' => '700000010',
            'role' => 'customer',
            'password' => bcrypt('password'),
        ]);

        Http::fake([
            'oauth2.googleapis.com/tokeninfo*' => Http::response($this->googleProfile([
                'email' => 'existing@store.test',
                'sub' => '330000000000000000003',
            ])),
        ]);

        $this->postJson('/api/google-login', ['id_token' => 'fake-id-token'])
            ->assertStatus(200)
            ->assertJsonPath('data.user.id', $user->id);

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'google_id' => '330000000000000000003',
        ]);
        $this->assertNotNull($user->fresh()->email_verified_at);
    }

    public function test_blocked_user_cannot_login_with_google(): void
    {
        User::create([
            'name' => 'محظور',
            'email' => 'blocked@store.test',
            'phone' => '700000011',
            'role' => 'customer',
            'is_blocked' => true,
            'password' => bcrypt('password'),
        ]);

        Http::fake([
            'oauth2.googleapis.com/tokeninfo*' => Http::response($this->googleProfile([
                'email' => 'blocked@store.test',
                'sub' => '440000000000000000004',
            ])),
        ]);

        $this->postJson('/api/google-login', ['id_token' => 'fake-id-token'])
            ->assertStatus(403);
    }
}
