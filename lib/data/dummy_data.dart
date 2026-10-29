// ============================================
// البيانات التجريبية (Dummy Data)
// تحاكي ردود Laravel API
// ============================================

import '../models/models.dart';

/// بيانات تجريبية للمنتجات
class DummyData {
  // ============================================================
  // التصنيفات الرئيسية مع الأقسام الفرعية
  // ============================================================
  static final List<Category> categories = [
    // 1️⃣ الفساتين
    Category(
      id: '1',
      name: 'الفساتين',
      slug: 'dresses',
      icon: 'checkroom',
      type: 'main',
      sortOrder: 1,
      children: [
        Category(id: '1-1', name: 'فساتين سهرة', icon: 'checkroom', parentId: '1', type: 'sub', sortOrder: 1),
        Category(id: '1-2', name: 'فساتين زفاف', icon: 'checkroom', parentId: '1', type: 'sub', sortOrder: 2),
        Category(id: '1-3', name: 'فساتين كاجوال يومية', icon: 'checkroom', parentId: '1', type: 'sub', sortOrder: 3),
        Category(id: '1-4', name: 'فساتين ماكسي طويلة', icon: 'checkroom', parentId: '1', type: 'sub', sortOrder: 4),
        Category(id: '1-5', name: 'فساتين قصيرة', icon: 'checkroom', parentId: '1', type: 'sub', sortOrder: 5),
        Category(id: '1-6', name: 'فساتين ميدي', icon: 'checkroom', parentId: '1', type: 'sub', sortOrder: 6),
        Category(id: '1-7', name: 'فساتين صيفية (فلورال)', icon: 'checkroom', parentId: '1', type: 'sub', sortOrder: 7),
        Category(id: '1-8', name: 'فساتين محتشمة بأكمام طويلة', icon: 'checkroom', parentId: '1', type: 'sub', sortOrder: 8),
        Category(id: '1-9', name: 'فساتين حمل ورضاعة', icon: 'checkroom', parentId: '1', type: 'sub', sortOrder: 9),
      ],
    ),
    // 2️⃣ العبايات والجلابيات
    Category(
      id: '2',
      name: 'العبايات والجلابيات',
      slug: 'abayas-jalabiyas',
      icon: 'checkroom',
      type: 'main',
      sortOrder: 2,
      children: [
        Category(id: '2-1', name: 'عبايات سوداء كلاسيك', icon: 'checkroom', parentId: '2', type: 'sub', sortOrder: 1),
        Category(id: '2-2', name: 'عبايات ملونة', icon: 'checkroom', parentId: '2', type: 'sub', sortOrder: 2),
        Category(id: '2-3', name: 'عبايات مطرزة', icon: 'checkroom', parentId: '2', type: 'sub', sortOrder: 3),
        Category(id: '2-4', name: 'عبايات كاجوال يومية', icon: 'checkroom', parentId: '2', type: 'sub', sortOrder: 4),
        Category(id: '2-5', name: 'عبايات مناسبات', icon: 'checkroom', parentId: '2', type: 'sub', sortOrder: 5),
        Category(id: '2-6', name: 'جلابيات خليجية', icon: 'checkroom', parentId: '2', type: 'sub', sortOrder: 6),
        Category(id: '2-7', name: 'جلابيات مغربية', icon: 'checkroom', parentId: '2', type: 'sub', sortOrder: 7),
        Category(id: '2-8', name: 'عبايات سفر', icon: 'checkroom', parentId: '2', type: 'sub', sortOrder: 8),
        Category(id: '2-9', name: 'خمار ونقاب', icon: 'checkroom', parentId: '2', type: 'sub', sortOrder: 9),
      ],
    ),
    // 3️⃣ البلوزات والتوبات
    Category(
      id: '3',
      name: 'البلوزات والتوبات',
      slug: 'blouses-tops',
      icon: 'checkroom',
      type: 'main',
      sortOrder: 3,
      children: [
        Category(id: '3-1', name: 'بلوزات قماش', icon: 'checkroom', parentId: '3', type: 'sub', sortOrder: 1),
        Category(id: '3-2', name: 'بلوزات شيفون', icon: 'checkroom', parentId: '3', type: 'sub', sortOrder: 2),
        Category(id: '3-3', name: 'بلوزات حرير', icon: 'checkroom', parentId: '3', type: 'sub', sortOrder: 3),
        Category(id: '3-4', name: 'توبات أساسية', icon: 'checkroom', parentId: '3', type: 'sub', sortOrder: 4),
        Category(id: '3-5', name: 'كروب توب', icon: 'checkroom', parentId: '3', type: 'sub', sortOrder: 5),
        Category(id: '3-6', name: 'بلوزات بأكمام واسعة', icon: 'checkroom', parentId: '3', type: 'sub', sortOrder: 6),
        Category(id: '3-7', name: 'قمصان نسائية', icon: 'checkroom', parentId: '3', type: 'sub', sortOrder: 7),
        Category(id: '3-8', name: 'تونيكات طويلة', icon: 'checkroom', parentId: '3', type: 'sub', sortOrder: 8),
      ],
    ),
    // 4️⃣ التنانير
    Category(
      id: '4',
      name: 'التنانير',
      slug: 'skirts',
      icon: 'checkroom',
      type: 'main',
      sortOrder: 4,
      children: [
        Category(id: '4-1', name: 'تنانير طويلة (ماكسي)', icon: 'checkroom', parentId: '4', type: 'sub', sortOrder: 1),
        Category(id: '4-2', name: 'تنانير قصيرة', icon: 'checkroom', parentId: '4', type: 'sub', sortOrder: 2),
        Category(id: '4-3', name: 'تنانير ميدي', icon: 'checkroom', parentId: '4', type: 'sub', sortOrder: 3),
        Category(id: '4-4', name: 'تنانير جينز', icon: 'checkroom', parentId: '4', type: 'sub', sortOrder: 4),
        Category(id: '4-5', name: 'تنانير بليسيه', icon: 'checkroom', parentId: '4', type: 'sub', sortOrder: 5),
        Category(id: '4-6', name: 'تنانير رسمية', icon: 'checkroom', parentId: '4', type: 'sub', sortOrder: 6),
      ],
    ),
    // 5️⃣ البناطيل
    Category(
      id: '5',
      name: 'البناطيل',
      slug: 'pants',
      icon: 'checkroom',
      type: 'main',
      sortOrder: 5,
      children: [
        Category(id: '5-1', name: 'جينز (سكيني، وايد ليق، موم فيت)', icon: 'checkroom', parentId: '5', type: 'sub', sortOrder: 1),
        Category(id: '5-2', name: 'بناطيل قماش', icon: 'checkroom', parentId: '5', type: 'sub', sortOrder: 2),
        Category(id: '5-3', name: 'بناطيل رسمية', icon: 'checkroom', parentId: '5', type: 'sub', sortOrder: 3),
        Category(id: '5-4', name: 'ليقنز', icon: 'checkroom', parentId: '5', type: 'sub', sortOrder: 4),
        Category(id: '5-5', name: 'بناطيل كارجو', icon: 'checkroom', parentId: '5', type: 'sub', sortOrder: 5),
        Category(id: '5-6', name: 'شورتات', icon: 'checkroom', parentId: '5', type: 'sub', sortOrder: 6),
      ],
    ),
    // 6️⃣ البدلات والأطقم
    Category(
      id: '6',
      name: 'البدلات والأطقم',
      slug: 'suits-sets',
      icon: 'checkroom',
      type: 'main',
      sortOrder: 6,
      children: [
        Category(id: '6-1', name: 'بدلات رسمية نسائية', icon: 'checkroom', parentId: '6', type: 'sub', sortOrder: 1),
        Category(id: '6-2', name: 'أطقم كاجوال (تو بيس)', icon: 'checkroom', parentId: '6', type: 'sub', sortOrder: 2),
        Category(id: '6-3', name: 'بليزرات نسائية', icon: 'checkroom', parentId: '6', type: 'sub', sortOrder: 3),
        Category(id: '6-4', name: 'أطقم تنورة وبلوزة', icon: 'checkroom', parentId: '6', type: 'sub', sortOrder: 4),
        Category(id: '6-5', name: 'أطقم رياضية', icon: 'checkroom', parentId: '6', type: 'sub', sortOrder: 5),
        Category(id: '6-6', name: 'جمبسوت', icon: 'checkroom', parentId: '6', type: 'sub', sortOrder: 6),
      ],
    ),
    // 7️⃣ الملابس الخارجية
    Category(
      id: '7',
      name: 'الملابس الخارجية',
      slug: 'outerwear',
      icon: 'checkroom',
      type: 'main',
      sortOrder: 7,
      children: [
        Category(id: '7-1', name: 'جاكيتات جلد', icon: 'checkroom', parentId: '7', type: 'sub', sortOrder: 1),
        Category(id: '7-2', name: 'جاكيتات جينز', icon: 'checkroom', parentId: '7', type: 'sub', sortOrder: 2),
        Category(id: '7-3', name: 'معاطف شتوية', icon: 'checkroom', parentId: '7', type: 'sub', sortOrder: 3),
        Category(id: '7-4', name: 'معاطف ترنش', icon: 'checkroom', parentId: '7', type: 'sub', sortOrder: 4),
        Category(id: '7-5', name: 'كارديغان', icon: 'checkroom', parentId: '7', type: 'sub', sortOrder: 5),
        Category(id: '7-6', name: 'كاب وبونشو', icon: 'checkroom', parentId: '7', type: 'sub', sortOrder: 6),
        Category(id: '7-7', name: 'فيستات', icon: 'checkroom', parentId: '7', type: 'sub', sortOrder: 7),
      ],
    ),
    // 8️⃣ الحجاب والأوشحة
    Category(
      id: '8',
      name: 'الحجاب والأوشحة',
      slug: 'hijab-scarves',
      icon: 'spa',
      type: 'main',
      sortOrder: 8,
      children: [
        Category(id: '8-1', name: 'حجابات شيفون', icon: 'spa', parentId: '8', type: 'sub', sortOrder: 1),
        Category(id: '8-2', name: 'حجابات قطن وجيرسي', icon: 'spa', parentId: '8', type: 'sub', sortOrder: 2),
        Category(id: '8-3', name: 'حجابات حرير', icon: 'spa', parentId: '8', type: 'sub', sortOrder: 3),
        Category(id: '8-4', name: 'أوشحة مطبوعة', icon: 'spa', parentId: '8', type: 'sub', sortOrder: 4),
        Category(id: '8-5', name: 'شالات', icon: 'spa', parentId: '8', type: 'sub', sortOrder: 5),
        Category(id: '8-6', name: 'باندات وبونيهات تحت الحجاب', icon: 'spa', parentId: '8', type: 'sub', sortOrder: 6),
        Category(id: '8-7', name: 'دبابيس وإكسسوارات حجاب', icon: 'spa', parentId: '8', type: 'sub', sortOrder: 7),
      ],
    ),
    // 9️⃣ الملابس الرياضية
    Category(
      id: '9',
      name: 'الملابس الرياضية',
      slug: 'sportswear',
      icon: 'sports',
      type: 'main',
      sortOrder: 9,
      children: [
        Category(id: '9-1', name: 'أطقم رياضية نسائية', icon: 'sports', parentId: '9', type: 'sub', sortOrder: 1),
        Category(id: '9-2', name: 'ليقنز رياضي', icon: 'sports', parentId: '9', type: 'sub', sortOrder: 2),
        Category(id: '9-3', name: 'توبات رياضية', icon: 'sports', parentId: '9', type: 'sub', sortOrder: 3),
        Category(id: '9-4', name: 'حجاب رياضي', icon: 'sports', parentId: '9', type: 'sub', sortOrder: 4),
        Category(id: '9-5', name: 'ملابس يوجا', icon: 'sports', parentId: '9', type: 'sub', sortOrder: 5),
        Category(id: '9-6', name: 'ملابس سباحة محتشمة (بوركيني)', icon: 'sports', parentId: '9', type: 'sub', sortOrder: 6),
      ],
    ),
    // 🔟 الأحذية
    Category(
      id: '10',
      name: 'الأحذية',
      slug: 'shoes',
      icon: 'shopping_bag',
      type: 'main',
      sortOrder: 10,
      children: [
        Category(id: '10-1', name: 'كعب عالي', icon: 'shopping_bag', parentId: '10', type: 'sub', sortOrder: 1),
        Category(id: '10-2', name: 'فلات وباليرينا', icon: 'shopping_bag', parentId: '10', type: 'sub', sortOrder: 2),
        Category(id: '10-3', name: 'سنيكرز', icon: 'shopping_bag', parentId: '10', type: 'sub', sortOrder: 3),
        Category(id: '10-4', name: 'صنادل', icon: 'shopping_bag', parentId: '10', type: 'sub', sortOrder: 4),
        Category(id: '10-5', name: 'بوتس', icon: 'shopping_bag', parentId: '10', type: 'sub', sortOrder: 5),
        Category(id: '10-6', name: 'شباشب', icon: 'shopping_bag', parentId: '10', type: 'sub', sortOrder: 6),
        Category(id: '10-7', name: 'أحذية رياضية', icon: 'shopping_bag', parentId: '10', type: 'sub', sortOrder: 7),
      ],
    ),
    // 1️⃣1️⃣ الحقائب
    Category(
      id: '11',
      name: 'الحقائب',
      slug: 'bags',
      icon: 'backpack',
      type: 'main',
      sortOrder: 11,
      children: [
        Category(id: '11-1', name: 'حقائب يد', icon: 'backpack', parentId: '11', type: 'sub', sortOrder: 1),
        Category(id: '11-2', name: 'حقائب كتف', icon: 'backpack', parentId: '11', type: 'sub', sortOrder: 2),
        Category(id: '11-3', name: 'حقائب كروس', icon: 'backpack', parentId: '11', type: 'sub', sortOrder: 3),
        Category(id: '11-4', name: 'حقائب ظهر', icon: 'backpack', parentId: '11', type: 'sub', sortOrder: 4),
        Category(id: '11-5', name: 'كلتش سهرة', icon: 'backpack', parentId: '11', type: 'sub', sortOrder: 5),
        Category(id: '11-6', name: 'حقائب تسوق (توت)', icon: 'backpack', parentId: '11', type: 'sub', sortOrder: 6),
        Category(id: '11-7', name: 'محافظ نسائية', icon: 'backpack', parentId: '11', type: 'sub', sortOrder: 7),
      ],
    ),
    // 1️⃣2️⃣ الإكسسوارات والمجوهرات
    Category(
      id: '12',
      name: 'الإكسسوارات والمجوهرات',
      slug: 'accessories-jewelry',
      icon: 'diamond',
      type: 'main',
      sortOrder: 12,
      children: [
        Category(id: '12-1', name: 'عقود وسلاسل', icon: 'diamond', parentId: '12', type: 'sub', sortOrder: 1),
        Category(id: '12-2', name: 'أساور وخواتم', icon: 'diamond', parentId: '12', type: 'sub', sortOrder: 2),
        Category(id: '12-3', name: 'أقراط', icon: 'diamond', parentId: '12', type: 'sub', sortOrder: 3),
        Category(id: '12-4', name: 'ساعات نسائية', icon: 'watch', parentId: '12', type: 'sub', sortOrder: 4),
        Category(id: '12-5', name: 'نظارات شمسية', icon: 'diamond', parentId: '12', type: 'sub', sortOrder: 5),
        Category(id: '12-6', name: 'إكسسوارات شعر', icon: 'diamond', parentId: '12', type: 'sub', sortOrder: 6),
        Category(id: '12-7', name: 'أحزمة', icon: 'diamond', parentId: '12', type: 'sub', sortOrder: 7),
        Category(id: '12-8', name: 'أقنعة وقبعات', icon: 'diamond', parentId: '12', type: 'sub', sortOrder: 8),
      ],
    ),
    // 1️⃣3️⃣ الملابس الداخلية والنوم
    Category(
      id: '13',
      name: 'الملابس الداخلية والنوم',
      slug: 'lingerie-sleepwear',
      icon: 'checkroom',
      type: 'main',
      sortOrder: 13,
      children: [
        Category(id: '13-1', name: 'ملابس داخلية نسائية', icon: 'checkroom', parentId: '13', type: 'sub', sortOrder: 1),
        Category(id: '13-2', name: 'أطقم لانجري', icon: 'checkroom', parentId: '13', type: 'sub', sortOrder: 2),
        Category(id: '13-3', name: 'بيجامات نسائية', icon: 'checkroom', parentId: '13', type: 'sub', sortOrder: 3),
        Category(id: '13-4', name: 'قمصان نوم', icon: 'checkroom', parentId: '13', type: 'sub', sortOrder: 4),
        Category(id: '13-5', name: 'روب استحمام', icon: 'checkroom', parentId: '13', type: 'sub', sortOrder: 5),
        Category(id: '13-6', name: 'فساتين بيت (جلابيات بيتية)', icon: 'checkroom', parentId: '13', type: 'sub', sortOrder: 6),
      ],
    ),
    // 1️⃣4️⃣ ملابس المناسبات الخاصة
    Category(
      id: '14',
      name: 'ملابس المناسبات الخاصة',
      slug: 'special-occasions',
      icon: 'celebration',
      type: 'main',
      sortOrder: 14,
      children: [
        Category(id: '14-1', name: 'فساتين خطوبة', icon: 'celebration', parentId: '14', type: 'sub', sortOrder: 1),
        Category(id: '14-2', name: 'فساتين تخرج', icon: 'celebration', parentId: '14', type: 'sub', sortOrder: 2),
        Category(id: '14-3', name: 'ملابس رمضان والعيد', icon: 'celebration', parentId: '14', type: 'sub', sortOrder: 3),
        Category(id: '14-4', name: 'فساتين حنة', icon: 'celebration', parentId: '14', type: 'sub', sortOrder: 4),
      ],
    ),
    // 1️⃣5️⃣ الاطفال — أقسام الأولاد (بنفس بنية القسم النسائي)
    Category(
      id: '15',
      name: 'الاطفال',
      slug: 'children',
      icon: 'checkroom',
      type: 'main',
      sortOrder: 15,
      children: [
        Category(id: '15-1', name: 'قمصان أولاد', icon: 'checkroom', parentId: '15', type: 'sub', sortOrder: 1),
        Category(id: '15-2', name: 'شميز وفانلات', icon: 'checkroom', parentId: '15', type: 'sub', sortOrder: 2),
        Category(id: '15-3', name: 'تيشيرتات وبولو', icon: 'checkroom', parentId: '15', type: 'sub', sortOrder: 3),
        Category(id: '15-4', name: 'سراويل أولاد', icon: 'checkroom', parentId: '15', type: 'sub', sortOrder: 4),
        Category(id: '15-5', name: 'شورتات أولاد', icon: 'checkroom', parentId: '15', type: 'sub', sortOrder: 5),
        Category(id: '15-6', name: 'بدلات وأطقم أولاد', icon: 'checkroom', parentId: '15', type: 'sub', sortOrder: 6),
        Category(id: '15-7', name: 'جاكيتات وهوديز أولاد', icon: 'checkroom', parentId: '15', type: 'sub', sortOrder: 7),
        Category(id: '15-8', name: 'ملابس رياضية أولاد', icon: 'sports', parentId: '15', type: 'sub', sortOrder: 8),
        Category(id: '15-9', name: 'أحذية أولاد', icon: 'shopping_bag', parentId: '15', type: 'sub', sortOrder: 9),
        Category(id: '15-10', name: 'جرم (جوارب)', icon: 'checkroom', parentId: '15', type: 'sub', sortOrder: 10),
        Category(id: '15-11', name: 'ملابس داخلية أولاد', icon: 'checkroom', parentId: '15', type: 'sub', sortOrder: 11),
        Category(id: '15-12', name: 'بيجامات وملابس نوم أولاد', icon: 'checkroom', parentId: '15', type: 'sub', sortOrder: 12),
        Category(id: '15-13', name: 'حقائب مدرسية وظهر', icon: 'backpack', parentId: '15', type: 'sub', sortOrder: 13),
        Category(id: '15-14', name: 'إكسسوارات أولاد', icon: 'diamond', parentId: '15', type: 'sub', sortOrder: 14),
        Category(id: '15-15', name: 'ملابس مناسبات وأعياد أولاد', icon: 'celebration', parentId: '15', type: 'sub', sortOrder: 15),
      ],
    ),
  ];

  // ============================================================
  // الأقسام التسويقية
  // ============================================================
  static final List<Category> marketingSections = [
    Category(id: 'm-1', name: 'عروض اليوم', icon: 'local_fire_department', badge: '🔥', type: 'marketing', sortOrder: 1),
    Category(id: 'm-2', name: 'وصل حديثًا', icon: 'new_releases', badge: '✨', type: 'marketing', sortOrder: 2),
    Category(id: 'm-3', name: 'الأكثر مبيعًا', icon: 'trending_up', badge: '⭐', type: 'marketing', sortOrder: 3),
    Category(id: 'm-4', name: 'تشكيلة فاخرة', icon: 'diamond', badge: '💎', type: 'marketing', sortOrder: 4),
    Category(id: 'm-5', name: 'لوك كامل (Outfit)', icon: 'checkroom', badge: '👗', type: 'marketing', sortOrder: 5),
    Category(id: 'm-6', name: 'أقل من 50 ريال', icon: 'savings', badge: '💰', type: 'marketing', sortOrder: 6),
    Category(id: 'm-7', name: 'تصفية نهاية الموسم', icon: 'sell', badge: '🏷️', type: 'marketing', sortOrder: 7),
    Category(id: 'm-8', name: 'قسم الحوامل', icon: 'pregnant_woman', badge: '🤰', type: 'marketing', sortOrder: 8),
  ];

  // المنتجات
  static final List<Product> products = [
    Product(
      id: '1',
      name: 'فستان سهرة مطرز فاخر',
      description: 'فستان سهرة أنيق بتطريز يدوي راقي. قماش عالي الجودة يمنحك إطلالة ملكية في المناسبات الخاصة.',
      price: 449,
      oldPrice: 599,
      image: 'https://images.unsplash.com/photo-1566174049881-81001826583c?w=500',
      images: [
        'https://images.unsplash.com/photo-1566174049881-81001826583c?w=500',
        'https://images.unsplash.com/photo-1595778742750-9b8e3e3e3e3e?w=500',
      ],
      categoryId: '1-1',
      rating: 4.8,
      reviewsCount: 128,
      stock: 15,
      colors: ['أسود', 'ذهبي', 'أحمر'],
      sizes: ['S', 'M', 'L', 'XL'],
      isBestSeller: true,
    ),
    Product(
      id: '2',
      name: 'عباية مطرزة كلاسيكية',
      description: 'عباية سوداء كلاسيكية بتطريز أنيق على الأكمام. مثالية للإطلالات اليومية والمناسبات.',
      price: 299,
      oldPrice: 399,
      image: 'https://images.unsplash.com/photo-1583391733956-375ef4cefee3?w=500',
      images: [
        'https://images.unsplash.com/photo-1583391733956-375ef4cefee3?w=500',
      ],
      categoryId: '2-1',
      rating: 4.9,
      reviewsCount: 89,
      stock: 8,
      colors: ['أسود'],
      sizes: ['54', '56', '58', '60'],
      isBestSeller: true,
    ),
    Product(
      id: '3',
      name: 'حجاب شيفون فاخر',
      description: 'حجاب شيفون ناعم بخامة عالية الجودة. متوفر بألوان متعددة. خفيف ومريح للاستخدام اليومي.',
      price: 49,
      oldPrice: 79,
      image: 'https://images.unsplash.com/photo-1611042553365-9b101c1c0e3a?w=500',
      images: [
        'https://images.unsplash.com/photo-1611042553365-9b101c1c0e3a?w=500',
      ],
      categoryId: '8-1',
      rating: 4.7,
      reviewsCount: 256,
      stock: 50,
      colors: ['أسود', 'بيج', 'وردي', 'كحلي', 'زيتي'],
      sizes: [],
      isBestSeller: true,
    ),
    Product(
      id: '4',
      name: 'فستان ماكسي محتشم',
      description: 'فستان ماكسي طويل بأكمام طويلة. تصميم محتعم أنيق مناسب للسهرات والمناسبات.',
      price: 359,
      image: 'https://images.unsplash.com/photo-1595778742750-9b8e3e3e3e3e?w=500',
      images: [
        'https://images.unsplash.com/photo-1595778742750-9b8e3e3e3e3e?w=500',
      ],
      categoryId: '1-4',
      rating: 4.5,
      reviewsCount: 64,
      stock: 20,
      colors: ['أسود', 'كحلي', 'زيتي'],
      sizes: ['S', 'M', 'L', 'XL'],
      isBestSeller: false,
    ),
    Product(
      id: '5',
      name: 'بلوزة شيفون أنيقة',
      description: 'بلوزة شيفون ناعمة بتصميم عصري. مريحة للإطلالات اليومية والعملية.',
      price: 89,
      oldPrice: 129,
      image: 'https://images.unsplash.com/photo-1551803021-0ab9b8b3b3b3?w=500',
      images: [
        'https://images.unsplash.com/photo-1551803021-0ab9b8b3b3b3?w=500',
      ],
      categoryId: '3-2',
      rating: 4.3,
      reviewsCount: 45,
      stock: 30,
      colors: ['أبيض', 'أسود', 'وردي', 'أزرق'],
      sizes: ['S', 'M', 'L', 'XL'],
      isBestSeller: false,
    ),
    Product(
      id: '6',
      name: 'حقيبة يد جلدية فاخرة',
      description: 'حقيبة يد أنيقة من الجلد الطبيعي. تصميم عصري يناسب جميع الإطلالات.',
      price: 349,
      image: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=500',
      images: [
        'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=500',
      ],
      categoryId: '11-1',
      rating: 4.6,
      reviewsCount: 78,
      stock: 10,
      colors: ['بني', 'أسود', 'بيج'],
      sizes: [],
      isBestSeller: false,
    ),
  ];

  // العناوين (الموقع الافتراضي: اليمن - عدن - تم استبدال المدن السعودية)
  static final List<Address> addresses = [
    Address(
      id: '1',
      governorate: 'عدن',
      city: 'كريتر',
      district: 'حي الجمهورية',
      street: 'شارع القاسم، مبنى 12',
      phone: '712345678',
      isDefault: true,
      latitude: 12.7917,
      longitude: 45.0067,
    ),
    Address(
      id: '2',
      governorate: 'عدن',
      city: 'المنصورة',
      district: 'حي الروضة',
      street: 'شارع المطار، قرب دوار 40',
      phone: '798765432',
      isDefault: false,
      latitude: 12.7853,
      longitude: 45.0631,
    ),
  ];

  // الطلبات
  static List<Order> get orders => [
        Order(
          id: '1',
          orderNumber: 'ORD-2024-001',
          date: DateTime.now().subtract(const Duration(days: 5)),
          items: [
            CartItem(
              id: '1',
              product: products[0],
              quantity: 1,
              selectedColor: 'أسود',
              selectedSize: 'M',
            ),
          ],
          subtotal: 449,
          shipping: 0,
          total: 449,
          status: OrderStatus.delivered,
          address: addresses[0],
          paymentMethod: 'الدفع عند الاستلام',
        ),
        Order(
          id: '2',
          orderNumber: 'ORD-2024-002',
          date: DateTime.now().subtract(const Duration(days: 2)),
          items: [
            CartItem(
              id: '2',
              product: products[1],
              quantity: 1,
              selectedColor: 'أسود',
              selectedSize: '56',
            ),
            CartItem(
              id: '3',
              product: products[2],
              quantity: 2,
              selectedColor: 'بيج',
              selectedSize: '',
            ),
          ],
          subtotal: 397,
          shipping: 0,
          total: 397,
          status: OrderStatus.shipped,
          address: addresses[0],
          paymentMethod: 'بطاقة ائتمانية',
        ),
        Order(
          id: '3',
          orderNumber: 'ORD-2024-003',
          date: DateTime.now(),
          items: [
            CartItem(
              id: '4',
              product: products[3],
              quantity: 1,
              selectedColor: 'كحلي',
              selectedSize: 'L',
            ),
          ],
          subtotal: 359,
          shipping: 25,
          total: 384,
          status: OrderStatus.pending,
          address: addresses[1],
          paymentMethod: 'محفظة إلكترونية',
        ),
      ];

  // المستخدم الحالي
  static User get currentUser => User(
        id: '1',
        name: 'سارة محمد',
        email: 'sara@example.com',
        phone: '712345678',
        avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
      );
}