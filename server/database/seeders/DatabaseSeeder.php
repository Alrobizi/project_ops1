<?php

namespace Database\Seeders;

use App\Models\Address;
use App\Models\Banner;
use App\Models\Category;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

/**
 * [إصلاح] بذرة قاعدة البيانات أصبحت متوافقة مع التشغيل المتكرر (Idempotent):
 * - استخدام firstOrCreate بدلاً من create المباشر حتى لا يتوقف الـ Seeder
 *   بخطأ UNIQUE constraint عند وجود بيانات مسبقة في قاعدة البيانات.
 * - لا يتم حذف أو تعديل أي بيانات موجودة، فقط إضافة ما هو مفقود.
 * - الموقع الافتراضي للبيانات التجريبية: اليمن - عدن - كريتر (بدون مدن سعودية).
 */
class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        // ============================================================
        // المستخدمون (البحث بالبريد الإلكتروني الفريد - إنشاء فقط عند عدم الوجود)
        // ============================================================
        $admin = User::firstOrCreate(
            ['email' => 'admin@store.test'],
            [
                'name' => 'مدير المتجر',
                'phone' => '700000001',
                'role' => 'admin',
                // الأدمن الرئيسي يُمنح كل الأقسام صراحةً (الافتراضي بدون صلاحيات)
                'admin_permissions' => User::ADMIN_PERMISSIONS,
                'password' => Hash::make('password'),
            ]
        );

        // أدمن بصلاحية "المنتجات" فقط — يرى لوحة التحكم في التطبيق ويدير المنتجات والتصنيفات
        User::firstOrCreate(
            ['email' => 'manager@store.test'],
            [
                'name' => 'مسؤول المنتجات',
                'phone' => '700000010',
                'role' => 'admin',
                'admin_permissions' => ['products'],
                'password' => Hash::make('password'),
            ]
        );

        $customer = User::firstOrCreate(
            ['email' => 'test@test.com'],
            [
                'name' => 'أحمد محمد',
                'phone' => '700000002',
                'role' => 'customer',
                'password' => Hash::make('123456'),
            ]
        );

        User::firstOrCreate(
            ['email' => 'sara@test.com'],
            [
                'name' => 'سارة القحطاني',
                'phone' => '700000003',
                'role' => 'customer',
                'password' => Hash::make('123456'),
            ]
        );

        // إنشاء التصنيفات النسائية
        $this->call(WomenCategoriesSeeder::class);

        // إنشاء تصنيفات الأولاد (تحت قسم الاطفال)
        $this->call(BoysCategoriesSeeder::class);

        // جلب التصنيفات الفرعية لربط المنتجات بها
        $dressesEvening = Category::where('name', 'فساتين سهرة')->first();
        $abayaClassic = Category::where('name', 'عبايات سوداء كلاسيك')->first();
        $hijabChiffon = Category::where('name', 'حجابات شيفون')->first();
        $dressMaxi = Category::where('name', 'فساتين ماكسي طويلة')->first();
        $blouseChiffon = Category::where('name', 'بلوزات شيفون')->first();
        $handbag = Category::where('name', 'حقائب يد')->first();
        $heels = Category::where('name', 'كعب عالي')->first();
        $necklace = Category::where('name', 'عقود وسلاسل')->first();
        $sportsSet = Category::where('name', 'أطقم رياضية نسائية')->first();
        $pajama = Category::where('name', 'بيجامات نسائية')->first();
        $jeans = Category::where('name', 'جينز (سكيني، وايد ليق، موم فيت)')->first();
        $jacket = Category::where('name', 'جاكيتات جلد')->first();

        $products = [
            [$dressesEvening, 'فستان سهرة مطرز فاخر', 'فستان سهرة أنيق بتطريز يدوي راقي. قماش عالي الجودة يمنحك إطلالة ملكية في المناسبات الخاصة.', 449, 599, 'https://images.unsplash.com/photo-1566174049881-81001826583c?w=500', 15, 4.8, 128, ['أسود', 'ذهبي', 'أحمر'], ['S', 'M', 'L', 'XL'], true],
            [$abayaClassic, 'عباية مطرزة كلاسيكية', 'عباية سوداء كلاسيكية بتطريز أنيق على الأكمام. مثالية للإطلالات اليومية والمناسبات.', 299, 399, 'https://images.unsplash.com/photo-1583391733956-375ef4cefee3?w=500', 8, 4.9, 89, ['أسود'], ['54', '56', '58', '60'], true],
            [$hijabChiffon, 'حجاب شيفون فاخر', 'حجاب شيفون ناعم بخامة عالية الجودة. متوفر بألوان متعددة. خفيف ومريح للاستخدام اليومي.', 49, 79, 'https://images.unsplash.com/photo-1611042553365-9b101c1c0e3a?w=500', 50, 4.7, 256, ['أسود', 'بيج', 'وردي', 'كحلي', 'زيتي'], ['قياس واحد'], true],
            [$dressMaxi, 'فستان ماكسي محتشم', 'فستان ماكسي طويل بأكمام طويلة. تصميم محتشم أنيق مناسب للسهرات والمناسبات.', 359, null, 'https://images.unsplash.com/photo-1595778742750-9b8e3e3e3e3e?w=500', 20, 4.5, 64, ['أسود', 'كحلي', 'زيتي'], ['S', 'M', 'L', 'XL'], false],
            [$blouseChiffon, 'بلوزة شيفون أنيقة', 'بلوزة شيفون ناعمة بتصميم عصري. مريحة للإطلالات اليومية والعملية.', 89, 129, 'https://images.unsplash.com/photo-1551803021-0ab9b8b3b3b3?w=500', 30, 4.3, 45, ['أبيض', 'أسود', 'وردي', 'أزرق'], ['S', 'M', 'L', 'XL'], false],
            [$handbag, 'حقيبة يد جلدية فاخرة', 'حقيبة يد أنيقة من الجلد الطبيعي. تصميم عصري يناسب جميع الإطلالات.', 349, null, 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=500', 10, 4.6, 78, ['بني', 'أسود', 'بيج'], ['قياس واحد'], false],
            [$heels, 'حذاء كعب عالي أنيق', 'حذاء كعب عالي بتصميم أنيق وراقي. مريح للمناسبات والسهرات.', 259, 329, 'https://images.unsplash.com/photo-1543163529-1cf46c453b94?w=500', 12, 4.5, 92, ['أسود', 'أحمر', 'بيج'], ['36', '37', '38', '39', '40'], true],
            [$necklace, 'عقد لؤلؤ فاخر', 'عقد لؤلؤ طبيعي بتصميم كلاسيكي راقي. مثالي للمناسبات والإطلالات الأنيقة.', 199, 259, 'https://images.unsplash.com/photo-1611652022233-7e7358d9c1c1?w=500', 15, 4.8, 67, ['ذهبي', 'فضي'], ['قياس واحد'], false],
            [$sportsSet, 'طقم رياضي نسائي', 'طقم رياضي نسائي عالي الجودة. مريح للتمارين واليوجا. خامة تمتص العرق.', 179, 229, 'https://images.unsplash.com/photo-1570285964451-4e0e2b7b3b3b?w=500', 25, 4.6, 143, ['أسود', 'رمادي', 'كحلي'], ['S', 'M', 'L', 'XL'], false],
            [$pajama, 'بيجاما قطنية ناعمة', 'بيجاما قطنية ناعمة بتصميم أنيق. مريحة للنوم والاسترخاء في المنزل.', 99, 129, 'https://images.unsplash.com/photo-1571513800374-4e6b3a6e3e3e?w=500', 40, 4.4, 88, ['وردي', 'أزرق', 'أبيض'], ['S', 'M', 'L', 'XL'], false],
            [$jeans, 'جينز سكيني نسائي', 'جينز سكيني عالي الخصر بقصة عصرية. خامة مرنة ومريحة. مثالي للإطلالات اليومية.', 189, 249, 'https://images.unsplash.com/photo-1541099649255-6b3e8e0d5e1e?w=500', 18, 4.7, 112, ['أزرق فاتح', 'أزرق غامق', 'أسود'], ['26', '28', '30', '32', '34'], true],
            [$jacket, 'جاكيت جلد نسائي', 'جاكيت جلد طبيعي بتصميم عصري أنيق. مثالي للإطلالات الكاجوال والرسمية.', 449, 549, 'https://images.unsplash.com/photo-1551232864-3e3e3e3e3e3e?w=500', 7, 4.8, 54, ['بني', 'أسود'], ['S', 'M', 'L', 'XL'], false],
        ];

        // ============================================================
        // المنتجات (البحث بالتصنيف + الاسم - إنشاء فقط عند عدم الوجود)
        // ============================================================
        $createdProducts = [];
        foreach ($products as [$category, $name, $desc, $price, $oldPrice, $image, $stock, $rating, $reviews, $colors, $sizes, $featured]) {
            if (! $category) {
                continue; // التصنيف غير موجود - تخطي المنتج بأمان
            }

            $createdProducts[] = Product::firstOrCreate(
                ['category_id' => $category->id, 'name' => $name],
                [
                    'description' => $desc,
                    'price' => $price,
                    'old_price' => $oldPrice,
                    'image' => $image,
                    'stock' => $stock,
                    'rating' => $rating,
                    'reviews_count' => $reviews,
                    'colors' => $colors,
                    'sizes' => $sizes,
                    'is_featured' => $featured,
                    'is_active' => true,
                ]
            );
        }

        // ============================================================
        // البانرات (البحث بالعنوان - إنشاء فقط عند عدم الوجود)
        // ============================================================
        Banner::firstOrCreate(['title' => 'عروض نهاية الموسم'], ['image' => 'https://images.unsplash.com/photo-1607083206869-4c7672e72a8a?w=1200', 'link' => '/products?featured=1', 'sort_order' => 1]);
        Banner::firstOrCreate(['title' => 'تشكيلة الفساتين الجديدة'], ['image' => 'https://images.unsplash.com/photo-1566174049881-81001826583c?w=1200', 'link' => '/products?category_id=1', 'sort_order' => 2]);
        Banner::firstOrCreate(['title' => 'عبايات و جلابيات'], ['image' => 'https://images.unsplash.com/photo-1583391733956-375ef4cefee3?w=1200', 'link' => '/products?category_id=2', 'sort_order' => 3]);

        // ============================================================
        // العنوان التجريبي (الموقع الافتراضي: اليمن - عدن - كريتر)
        // ============================================================
        $address = Address::firstOrCreate(
            ['user_id' => $customer->id, 'street' => 'شارع القاسم، مبنى 12'],
            [
                'governorate' => 'عدن',
                'city' => 'كريتر',
                'district' => 'حي الجمهورية',
                'phone' => '700000002',
                'is_default' => true,
                'latitude' => 12.7917,
                'longitude' => 45.0067,
            ]
        );

        // ============================================================
        // الطلبات التجريبية (تُنشأ مرة واحدة فقط لكل عميل عند عدم وجود طلبات)
        // ============================================================
        if ($customer->orders()->doesntExist() && count($createdProducts) >= 4) {
            $statuses = ['delivered', 'shipped', 'processing', 'pending'];
            foreach ($statuses as $index => $status) {
                $orderProducts = array_slice($createdProducts, $index, 2);
                $subtotal = collect($orderProducts)->sum(fn ($p) => $p->price * 2);
                $shipping = $subtotal >= 200 ? 0 : 25;

                $order = Order::create([
                    'order_number' => Order::generateOrderNumber(),
                    'user_id' => $customer->id,
                    'address_id' => $address->id,
                    'subtotal' => $subtotal,
                    'shipping' => $shipping,
                    'total' => $subtotal + $shipping,
                    'status' => $status,
                    'payment_method' => 'cod',
                    'created_at' => now()->subDays(3 - $index),
                ]);

                foreach ($orderProducts as $product) {
                    OrderItem::create([
                        'order_id' => $order->id,
                        'product_id' => $product->id,
                        'product_name' => $product->name,
                        'price' => $product->price,
                        'quantity' => 2,
                        'color' => $product->colors[0] ?? null,
                        'size' => $product->sizes[0] ?? null,
                    ]);
                }
            }
        }
    }
}
