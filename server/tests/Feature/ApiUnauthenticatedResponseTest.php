<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\Route;
use Tests\TestCase;

/**
 * يجب أن تُرجع مسارات /api استجابة JSON (401) حتى لو لم يرسل العميل
 * ترويسة Accept: application/json — وإلا سقط الطلب بخطأ 500.
 */
class ApiUnauthenticatedResponseTest extends TestCase
{
    public function test_api_routes_answer_json_even_without_accept_header(): void
    {
        $response = $this->get('/api/user');

        $response->assertStatus(401)
            ->assertHeader('Content-Type', 'application/json')
            ->assertJson(['message' => 'Unauthenticated.']);
    }

    /**
     * المتصفح (أو curl الافتراضي) يرسل Accept: text/html، ومع ذلك يجب أن تبقى
     * استجابة مسارات /api هي 401 JSON لا تحويلاً إلى مسار login غير موجود.
     */
    public function test_api_routes_answer_json_when_browser_accept_header_is_sent(): void
    {
        $response = $this->get('/api/user', ['Accept' => 'text/html,application/xhtml+xml']);

        $response->assertStatus(401)
            ->assertHeader('Content-Type', 'application/json')
            ->assertJson(['message' => 'Unauthenticated.']);
    }

    /**
     * لا يوجد مسار login في التطبيق، ويجب ألا يحاول أي مسار استدعاءه.
     */
    public function test_login_route_does_not_exist(): void
    {
        $this->assertFalse(Route::has('login'));
    }

    public function test_protected_admin_route_answers_json_without_accept_header(): void
    {
        $response = $this->get('/api/admin/customers');

        $response->assertStatus(401)
            ->assertHeader('Content-Type', 'application/json');
    }
}
