<?php

namespace Database\Seeders;

use App\Models\Category;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class BoysCategoriesSeeder extends Seeder
{
    public function run(): void
    {
        // ============================================================
        // 🧒 قسم الاطفال — أقسام الأولاد (بنفس بنية القسم النسائي)
        // ============================================================
        $children = Category::firstOrCreate(
            ['name' => 'الاطفال', 'type' => 'main'],
            [
                'slug' => 'children',
                'icon' => 'checkroom',
                'sort_order' => 15,
                'is_active' => true,
            ]
        );

        $boysSubs = [
            // القمصان والشميز (يوازي: البلوزات والتوبات)
            ['name' => 'قمصان أولاد', 'icon' => 'checkroom'],
            ['name' => 'شميز وفانلات', 'icon' => 'checkroom'],
            ['name' => 'تيشيرتات وبولو', 'icon' => 'checkroom'],
            // السراويل (يوازي: البناطيل)
            ['name' => 'سراويل أولاد', 'icon' => 'checkroom'],
            ['name' => 'شورتات أولاد', 'icon' => 'checkroom'],
            // البدلات والأطقم (يوازي: البدلات والأطقم)
            ['name' => 'بدلات وأطقم أولاد', 'icon' => 'checkroom'],
            // الملابس الخارجية
            ['name' => 'جاكيتات وهوديز أولاد', 'icon' => 'checkroom'],
            // الملابس الرياضية
            ['name' => 'ملابس رياضية أولاد', 'icon' => 'sports'],
            // الأحذية
            ['name' => 'أحذية أولاد', 'icon' => 'shopping_bag'],
            // الجرم (الجوارب)
            ['name' => 'جرم (جوارب)', 'icon' => 'checkroom'],
            // الملابس الداخلية والنوم
            ['name' => 'ملابس داخلية أولاد', 'icon' => 'checkroom'],
            ['name' => 'بيجامات وملابس نوم أولاد', 'icon' => 'checkroom'],
            // الحقائب
            ['name' => 'حقائب مدرسية وظهر', 'icon' => 'backpack'],
            // الإكسسوارات (يوازي: الإكسسوارات والمجوهرات)
            ['name' => 'إكسسوارات أولاد', 'icon' => 'diamond'],
            // ملابس المناسبات (يوازي: ملابس المناسبات الخاصة)
            ['name' => 'ملابس مناسبات وأعياد أولاد', 'icon' => 'celebration'],
        ];

        foreach ($boysSubs as $index => $sub) {
            Category::firstOrCreate([
                'name' => $sub['name'],
                'slug' => Str::slug($sub['name']),
                'icon' => $sub['icon'],
                'parent_id' => $children->id,
                'type' => 'sub',
                'sort_order' => $index + 1,
                'is_active' => true,
            ]);
        }
    }
}
