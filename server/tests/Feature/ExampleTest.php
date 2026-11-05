<?php

namespace Tests\Feature;

// use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ExampleTest extends TestCase
{
    /**
     * جذر الموقع يحوّل إلى تطبيق Flutter (SPA) المستضاف على /app/.
     */
    public function test_the_root_url_redirects_to_the_flutter_app(): void
    {
        $response = $this->get('/');

        $response->assertRedirect('/app/');
    }

    /**
     * الواجهة الأمامية تُخدَم من public/app/index.html.
     */
    public function test_the_flutter_app_is_served(): void
    {
        $response = $this->get('/app/');

        $response->assertOk();
    }
}
