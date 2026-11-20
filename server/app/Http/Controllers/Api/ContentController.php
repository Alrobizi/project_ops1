<?php

namespace App\Http\Controllers\Api;

use App\Models\Faq;
use App\Models\Page;
use Illuminate\Http\JsonResponse;

class ContentController extends BaseApiController
{
    /**
     * جلب الصفحات التعريفية العامة (سياسة الخصوصية، الشروط، سياسة الاسترجاع)
     */
    public function pages(): JsonResponse
    {
        $pages = Page::where('status', 'published')
            ->orWhere('status', 'منشور')
            ->latest()
            ->get(['id', 'title', 'slug', 'content', 'updated_at']);

        return $this->success($pages, 'تم جلب الصفحات بنجاح');
    }

    /**
     * جلب الأسئلة الشائعة للعملاء
     */
    public function faqs(): JsonResponse
    {
        $faqs = Faq::orderBy('sort_order')
            ->orderBy('id')
            ->get(['id', 'question', 'answer']);

        return $this->success($faqs, 'تم جلب الأسئلة الشائعة بنجاح');
    }
}
