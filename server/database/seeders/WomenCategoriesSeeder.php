<?php

namespace Database\Seeders;

use App\Models\Category;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class WomenCategoriesSeeder extends Seeder
{
    public function run(): void
    {
        // ============================================================
        // 1️⃣ الفساتين
        // ============================================================
        $dresses = Category::firstOrCreate([
            'name' => 'الفساتين',
            'slug' => 'dresses',
            'icon' => 'checkroom',
            'type' => 'main',
            'sort_order' => 1,
            'is_active' => true,
        ]);

        $dressesSubs = [
            'فساتين سهرة',
            'فساتين زفاف',
            'فساتين كاجوال يومية',
            'فساتين ماكسي طويلة',
            'فساتين قصيرة',
            'فساتين ميدي',
            'فساتين صيفية (فلورال)',
            'فساتين محتشمة بأكمام طويلة',
            'فساتين حمل ورضاعة',
        ];

        foreach ($dressesSubs as $index => $name) {
            Category::firstOrCreate([
                'name' => $name,
                'slug' => Str::slug($name),
                'icon' => 'checkroom',
                'parent_id' => $dresses->id,
                'type' => 'sub',
                'sort_order' => $index + 1,
                'is_active' => true,
            ]);
        }

        // ============================================================
        // 2️⃣ العبايات والجلابيات
        // ============================================================
        $abayas = Category::firstOrCreate([
            'name' => 'العبايات والجلابيات',
            'slug' => 'abayas-jalabiyas',
            'icon' => 'checkroom',
            'type' => 'main',
            'sort_order' => 2,
            'is_active' => true,
        ]);

        $abayasSubs = [
            'عبايات سوداء كلاسيك',
            'عبايات ملونة',
            'عبايات مطرزة',
            'عبايات كاجوال يومية',
            'عبايات مناسبات',
            'جلابيات خليجية',
            'جلابيات مغربية',
            'عبايات سفر',
            'خمار ونقاب',
        ];

        foreach ($abayasSubs as $index => $name) {
            Category::firstOrCreate([
                'name' => $name,
                'slug' => Str::slug($name),
                'icon' => 'checkroom',
                'parent_id' => $abayas->id,
                'type' => 'sub',
                'sort_order' => $index + 1,
                'is_active' => true,
            ]);
        }

        // ============================================================
        // 3️⃣ البلوزات والتوبات
        // ============================================================
        $blouses = Category::firstOrCreate([
            'name' => 'البلوزات والتوبات',
            'slug' => 'blouses-tops',
            'icon' => 'checkroom',
            'type' => 'main',
            'sort_order' => 3,
            'is_active' => true,
        ]);

        $blousesSubs = [
            'بلوزات قماش',
            'بلوزات شيفون',
            'بلوزات حرير',
            'توبات أساسية',
            'كروب توب',
            'بلوزات بأكمام واسعة',
            'قمصان نسائية',
            'تونيكات طويلة',
        ];

        foreach ($blousesSubs as $index => $name) {
            Category::firstOrCreate([
                'name' => $name,
                'slug' => Str::slug($name),
                'icon' => 'checkroom',
                'parent_id' => $blouses->id,
                'type' => 'sub',
                'sort_order' => $index + 1,
                'is_active' => true,
            ]);
        }

        // ============================================================
        // 4️⃣ التنانير
        // ============================================================
        $skirts = Category::firstOrCreate([
            'name' => 'التنانير',
            'slug' => 'skirts',
            'icon' => 'checkroom',
            'type' => 'main',
            'sort_order' => 4,
            'is_active' => true,
        ]);

        $skirtsSubs = [
            'تنانير طويلة (ماكسي)',
            'تنانير قصيرة',
            'تنانير ميدي',
            'تنانير جينز',
            'تنانير بليسيه',
            'تنانير رسمية',
        ];

        foreach ($skirtsSubs as $index => $name) {
            Category::firstOrCreate([
                'name' => $name,
                'slug' => Str::slug($name),
                'icon' => 'checkroom',
                'parent_id' => $skirts->id,
                'type' => 'sub',
                'sort_order' => $index + 1,
                'is_active' => true,
            ]);
        }

        // ============================================================
        // 5️⃣ البناطيل
        // ============================================================
        $pants = Category::firstOrCreate([
            'name' => 'البناطيل',
            'slug' => 'pants',
            'icon' => 'checkroom',
            'type' => 'main',
            'sort_order' => 5,
            'is_active' => true,
        ]);

        $pantsSubs = [
            'جينز (سكيني، وايد ليق، موم فيت)',
            'بناطيل قماش',
            'بناطيل رسمية',
            'ليقنز',
            'بناطيل كارجو',
            'شورتات',
        ];

        foreach ($pantsSubs as $index => $name) {
            Category::firstOrCreate([
                'name' => $name,
                'slug' => Str::slug($name),
                'icon' => 'checkroom',
                'parent_id' => $pants->id,
                'type' => 'sub',
                'sort_order' => $index + 1,
                'is_active' => true,
            ]);
        }

        // ============================================================
        // 6️⃣ البدلات والأطقم
        // ============================================================
        $suits = Category::firstOrCreate([
            'name' => 'البدلات والأطقم',
            'slug' => 'suits-sets',
            'icon' => 'checkroom',
            'type' => 'main',
            'sort_order' => 6,
            'is_active' => true,
        ]);

        $suitsSubs = [
            'بدلات رسمية نسائية',
            'أطقم كاجوال (تو بيس)',
            'بليزرات نسائية',
            'أطقم تنورة وبلوزة',
            'أطقم رياضية',
            'جمبسوت',
        ];

        foreach ($suitsSubs as $index => $name) {
            Category::firstOrCreate([
                'name' => $name,
                'slug' => Str::slug($name),
                'icon' => 'checkroom',
                'parent_id' => $suits->id,
                'type' => 'sub',
                'sort_order' => $index + 1,
                'is_active' => true,
            ]);
        }

        // ============================================================
        // 7️⃣ الملابس الخارجية
        // ============================================================
        $outerwear = Category::firstOrCreate([
            'name' => 'الملابس الخارجية',
            'slug' => 'outerwear',
            'icon' => 'checkroom',
            'type' => 'main',
            'sort_order' => 7,
            'is_active' => true,
        ]);

        $outerwearSubs = [
            'جاكيتات جلد',
            'جاكيتات جينز',
            'معاطف شتوية',
            'معاطف ترنش',
            'كارديغان',
            'كاب وبونشو',
            'فيستات',
        ];

        foreach ($outerwearSubs as $index => $name) {
            Category::firstOrCreate([
                'name' => $name,
                'slug' => Str::slug($name),
                'icon' => 'checkroom',
                'parent_id' => $outerwear->id,
                'type' => 'sub',
                'sort_order' => $index + 1,
                'is_active' => true,
            ]);
        }

        // ============================================================
        // 8️⃣ الحجاب والأوشحة
        // ============================================================
        $hijab = Category::firstOrCreate([
            'name' => 'الحجاب والأوشحة',
            'slug' => 'hijab-scarves',
            'icon' => 'spa',
            'type' => 'main',
            'sort_order' => 8,
            'is_active' => true,
        ]);

        $hijabSubs = [
            'حجابات شيفون',
            'حجابات قطن وجيرسي',
            'حجابات حرير',
            'أوشحة مطبوعة',
            'شالات',
            'باندات وبونيهات تحت الحجاب',
            'دبابيس وإكسسوارات حجاب',
        ];

        foreach ($hijabSubs as $index => $name) {
            Category::firstOrCreate([
                'name' => $name,
                'slug' => Str::slug($name),
                'icon' => 'spa',
                'parent_id' => $hijab->id,
                'type' => 'sub',
                'sort_order' => $index + 1,
                'is_active' => true,
            ]);
        }

        // ============================================================
        // 9️⃣ الملابس الرياضية
        // ============================================================
        $sports = Category::firstOrCreate([
            'name' => 'الملابس الرياضية',
            'slug' => 'sportswear',
            'icon' => 'sports',
            'type' => 'main',
            'sort_order' => 9,
            'is_active' => true,
        ]);

        $sportsSubs = [
            'أطقم رياضية نسائية',
            'ليقنز رياضي',
            'توبات رياضية',
            'حجاب رياضي',
            'ملابس يوجا',
            'ملابس سباحة محتشمة (بوركيني)',
        ];

        foreach ($sportsSubs as $index => $name) {
            Category::firstOrCreate([
                'name' => $name,
                'slug' => Str::slug($name),
                'icon' => 'sports',
                'parent_id' => $sports->id,
                'type' => 'sub',
                'sort_order' => $index + 1,
                'is_active' => true,
            ]);
        }

        // ============================================================
        // 🔟 الأحذية
        // ============================================================
        $shoes = Category::firstOrCreate([
            'name' => 'الأحذية',
            'slug' => 'shoes',
            'icon' => 'shopping_bag',
            'type' => 'main',
            'sort_order' => 10,
            'is_active' => true,
        ]);

        $shoesSubs = [
            'كعب عالي',
            'فلات وباليرينا',
            'سنيكرز',
            'صنادل',
            'بوتس',
            'شباشب',
            'أحذية رياضية',
        ];

        foreach ($shoesSubs as $index => $name) {
            Category::firstOrCreate([
                'name' => $name,
                'slug' => Str::slug($name),
                'icon' => 'shopping_bag',
                'parent_id' => $shoes->id,
                'type' => 'sub',
                'sort_order' => $index + 1,
                'is_active' => true,
            ]);
        }

        // ============================================================
        // 1️⃣1️⃣ الحقائب
        // ============================================================
        $bags = Category::firstOrCreate([
            'name' => 'الحقائب',
            'slug' => 'bags',
            'icon' => 'backpack',
            'type' => 'main',
            'sort_order' => 11,
            'is_active' => true,
        ]);

        $bagsSubs = [
            'حقائب يد',
            'حقائب كتف',
            'حقائب كروس',
            'حقائب ظهر',
            'كلتش سهرة',
            'حقائب تسوق (توت)',
            'محافظ نسائية',
        ];

        foreach ($bagsSubs as $index => $name) {
            Category::firstOrCreate([
                'name' => $name,
                'slug' => Str::slug($name),
                'icon' => 'backpack',
                'parent_id' => $bags->id,
                'type' => 'sub',
                'sort_order' => $index + 1,
                'is_active' => true,
            ]);
        }

        // ============================================================
        // 1️⃣2️⃣ الإكسسوارات والمجوهرات
        // ============================================================
        $accessories = Category::firstOrCreate([
            'name' => 'الإكسسوارات والمجوهرات',
            'slug' => 'accessories-jewelry',
            'icon' => 'diamond',
            'type' => 'main',
            'sort_order' => 12,
            'is_active' => true,
        ]);

        $accessoriesSubs = [
            'عقود وسلاسل',
            'أساور وخواتم',
            'أقراط',
            'ساعات نسائية',
            'نظارات شمسية',
            'إكسسوارات شعر',
            'أحزمة',
            'أقنعة وقبعات',
        ];

        foreach ($accessoriesSubs as $index => $name) {
            Category::firstOrCreate([
                'name' => $name,
                'slug' => Str::slug($name),
                'icon' => 'diamond',
                'parent_id' => $accessories->id,
                'type' => 'sub',
                'sort_order' => $index + 1,
                'is_active' => true,
            ]);
        }

        // ============================================================
        // 1️⃣3️⃣ الملابس الداخلية والنوم
        // ============================================================
        $lingerie = Category::firstOrCreate([
            'name' => 'الملابس الداخلية والنوم',
            'slug' => 'lingerie-sleepwear',
            'icon' => 'checkroom',
            'type' => 'main',
            'sort_order' => 13,
            'is_active' => true,
        ]);

        $lingerieSubs = [
            'ملابس داخلية نسائية',
            'أطقم لانجري',
            'بيجامات نسائية',
            'قمصان نوم',
            'روب استحمام',
            'فساتين بيت (جلابيات بيتية)',
        ];

        foreach ($lingerieSubs as $index => $name) {
            Category::firstOrCreate([
                'name' => $name,
                'slug' => Str::slug($name),
                'icon' => 'checkroom',
                'parent_id' => $lingerie->id,
                'type' => 'sub',
                'sort_order' => $index + 1,
                'is_active' => true,
            ]);
        }

        // ============================================================
        // 1️⃣4️⃣ ملابس المناسبات الخاصة
        // ============================================================
        $occasions = Category::firstOrCreate([
            'name' => 'ملابس المناسبات الخاصة',
            'slug' => 'special-occasions',
            'icon' => 'celebration',
            'type' => 'main',
            'sort_order' => 14,
            'is_active' => true,
        ]);

        $occasionsSubs = [
            'فساتين خطوبة',
            'فساتين تخرج',
            'ملابس رمضان والعيد',
            'فساتين حنة',
        ];

        foreach ($occasionsSubs as $index => $name) {
            Category::firstOrCreate([
                'name' => $name,
                'slug' => Str::slug($name),
                'icon' => 'celebration',
                'parent_id' => $occasions->id,
                'type' => 'sub',
                'sort_order' => $index + 1,
                'is_active' => true,
            ]);
        }

        // ============================================================
        // 1️⃣5️⃣ الأقسام التسويقية
        // ============================================================
        $marketingSections = [
            ['name' => 'عروض اليوم', 'badge' => '🔥', 'icon' => 'local_fire_department'],
            ['name' => 'وصل حديثًا', 'badge' => '✨', 'icon' => 'new_releases'],
            ['name' => 'الأكثر مبيعًا', 'badge' => '⭐', 'icon' => 'trending_up'],
            ['name' => 'تشكيلة فاخرة', 'badge' => '💎', 'icon' => 'diamond'],
            ['name' => 'لوك كامل (Outfit)', 'badge' => '👗', 'icon' => 'checkroom'],
            ['name' => 'أقل من 50 ريال', 'badge' => '💰', 'icon' => 'savings'],
            ['name' => 'تصفية نهاية الموسم', 'badge' => '🏷️', 'icon' => 'sell'],
            ['name' => 'قسم الحوامل', 'badge' => '🤰', 'icon' => 'pregnant_woman'],
        ];

        foreach ($marketingSections as $index => $section) {
            Category::firstOrCreate([
                'name' => $section['name'],
                'slug' => Str::slug($section['name']),
                'icon' => $section['icon'],
                'badge' => $section['badge'],
                'type' => 'marketing',
                'sort_order' => $index + 1,
                'is_active' => true,
            ]);
        }
    }
}