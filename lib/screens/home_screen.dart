// ============================================
// الشاشة الرئيسية وتفاصيل المنتج
// Home Screen & Product Details Screen
// ============================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_colors.dart';
import '../providers/app_providers.dart';
import '../widgets/common_widgets.dart';

// ============================================
// الشاشة الرئيسية (Home Screen)
// ============================================
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsState = ref.watch(productsProvider);
    final notifier = ref.read(productsProvider.notifier);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => Future.wait([
          notifier.loadData(),
          ref.read(bannersProvider.notifier).refresh(),
        ]),
        child: CustomScrollView(
          slivers: [
            // شريط الرأس الأنيق: الترحيب والإشعارات وشريط البحث
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primaryAccent.withOpacity(0.9),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // الترحيب والإشعارات
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'مرحباً 👋',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white70,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'اكتشف أفضل المنتجات',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            Consumer(
                              builder: (context, ref, child) {
                                final notificationsState =
                                    ref.watch(notificationsProvider);
                                final unread =
                                    notificationsState.unreadCount;

                                return Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.notifications_outlined,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          context.push('/notifications');
                                        },
                                      ),
                                    ),
                                    if (unread > 0)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          padding:
                                              const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFEF4444),
                                            shape: BoxShape.circle,
                                          ),
                                          constraints:
                                              const BoxConstraints(
                                            minWidth: 18,
                                            minHeight: 18,
                                          ),
                                          child: Text(
                                            unread > 99
                                                ? '99+'
                                                : '$unread',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // شريط البحث
                        TextField(
                          onChanged: notifier.search,
                          decoration: InputDecoration(
                            hintText: 'ابحث عن فساتين، عبايات، أزياء...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF6B7280),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // بانر العروض بنمط شي ان (SHEIN-style Banner) متصل بلوحة التحكم
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: BannerSlider(),
              ),
            ),
            // باقي المحتويات أسفل البانر
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الأقسام التسويقية
                    if (productsState.marketingSections.isNotEmpty) ...[
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'تسوّق حسب القسم',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 64,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: productsState.marketingSections.length,
                          itemBuilder: (context, index) {
                            final section =
                                productsState.marketingSections[index];
                            return MarketingSectionChip(
                              section: section,
                              onTap: () {
                                // TODO: التنقل لصفحة القسم التسويقي
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // التصنيفات
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'التصنيفات',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        TextButton(
                          onPressed: () => notifier.selectCategory(null),
                          child: const Text('عرض الكل'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // قائمة التصنيفات الرئيسية الأفقية
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: productsState.mainCategories.length,
                        itemBuilder: (context, index) {
                          final category = productsState.mainCategories[index];
                          return CategoryChip(
                            category: category,
                            isSelected:
                                productsState.selectedCategoryId == category.id,
                            onTap: () {
                              if (productsState.selectedCategoryId ==
                                  category.id) {
                                notifier.selectCategory(null);
                              } else {
                                notifier.selectCategory(category.id);
                              }
                            },
                          );
                        },
                      ),
                    ),
                    // الأقسام الفرعية للتصنيف المحدد
                    if (notifier.selectedSubcategories.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: notifier.selectedSubcategories.length,
                          itemBuilder: (context, index) {
                            final subcategory =
                                notifier.selectedSubcategories[index];
                            final isSelected =
                                productsState.selectedSubcategoryId ==
                                    subcategory.id;
                            return GestureDetector(
                              onTap: () {
                                if (isSelected) {
                                  notifier.selectSubcategory(null);
                                } else {
                                  notifier.selectSubcategory(subcategory.id);
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.cardLight,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.borderLight,
                                  ),
                                ),
                                child: Text(
                                  subcategory.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // الأفضل مبيعاً
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الأفضل مبيعاً',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('عرض الكل'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // شبكة المنتجات
            if (productsState.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (notifier.filteredProducts.isEmpty)
              const SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.search_off,
                  title: 'لا توجد منتجات',
                  subtitle: 'جرب البحث بكلمات مختلفة',
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = notifier.filteredProducts[index];
                      return ProductCard(
                        product: product,
                        onTap: () => context.push('/product/${product.id}'),
                      );
                    },
                    childCount: notifier.filteredProducts.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// شاشة الفئات (Categories Screen) - هرمية
// ============================================
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  String? _expandedCategoryId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final notifier = ref.read(productsProvider.notifier);
    var mainCategories = productsState.mainCategories;

    // فلترة الفئات حسب البحث
    if (_searchQuery.isNotEmpty) {
      mainCategories = mainCategories.where((category) {
        // البحث في اسم التصنيف الرئيسي
        if (category.name.contains(_searchQuery)) return true;

        // البحث في الأقسام الفرعية
        return category.children.any((sub) => sub.name.contains(_searchQuery));
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('الفئات'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // حقل البحث
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value.trim());
              },
              decoration: InputDecoration(
                hintText: 'ابحث عن فئة...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.cardLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          // قائمة الفئات
          Expanded(
            child: mainCategories.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    title: 'لا توجد نتائج',
                    subtitle: 'لم نتمكن من العثور على فئة مطابقة لبحثك',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: mainCategories.length,
                    itemBuilder: (context, index) {
                      final category = mainCategories[index];
                      final isExpanded = _expandedCategoryId == category.id;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.cardLight,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // التصنيف الرئيسي
                            ListTile(
                              onTap: () {
                                setState(() {
                                  _expandedCategoryId =
                                      isExpanded ? null : category.id;
                                });
                              },
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: category.image != null &&
                                        category.image!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: CachedNetworkImage(
                                          imageUrl: category.image!,
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                          memCacheWidth: 300,
                                          placeholder: (context, url) => Icon(
                                            _getCategoryIcon(category.icon),
                                            color: AppColors.primary,
                                            size: 24,
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Icon(
                                            _getCategoryIcon(category.icon),
                                            color: AppColors.primary,
                                            size: 24,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        _getCategoryIcon(category.icon),
                                        color: AppColors.primary,
                                        size: 24,
                                      ),
                              ),
                              title: Text(
                                category.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                              subtitle: Text(
                                '${category.children.length} قسم فرعي',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                              trailing: Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: AppColors.primary,
                              ),
                            ),
                            // الأقسام الفرعية
                            if (isExpanded && category.hasChildren)
                              Container(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children:
                                      category.children.map((subcategory) {
                                    return GestureDetector(
                                      onTap: () {
                                        notifier.selectCategory(category.id);
                                        notifier
                                            .selectSubcategory(subcategory.id);
                                        context.go('/home');
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withOpacity(0.05),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: AppColors.primary
                                                .withOpacity(0.2),
                                          ),
                                        ),
                                        child: Text(
                                          subcategory.name,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'checkroom':
        return Icons.checkroom;
      case 'spa':
        return Icons.spa;
      case 'sports':
        return Icons.sports;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'backpack':
        return Icons.backpack;
      case 'diamond':
        return Icons.diamond;
      case 'celebration':
        return Icons.celebration;
      case 'watch':
        return Icons.watch;
      default:
        return Icons.category;
    }
  }
}

// ============================================
// شاشة المفضلة (Wishlist Screen)
// ============================================
class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المفضلة'),
        centerTitle: true,
      ),
      body: wishlist.items.isEmpty
          ? EmptyState(
              icon: Icons.favorite_border,
              title: 'المفضلة فارغة',
              subtitle: 'أضف منتجات إلى المفضلة لعرضها هنا',
              buttonText: 'تصفح المنتجات',
              onButtonPressed: () => context.go('/home'),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: wishlist.items.length,
              itemBuilder: (context, index) {
                final product = wishlist.items[index];
                return ProductCard(
                  product: product,
                  onTap: () => context.push('/product/${product.id}'),
                );
              },
            ),
    );
  }
}

// ============================================
// شاشة تفاصيل المنتج (Product Details Screen)
// ============================================
class ProductDetailsScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  int _quantity = 1;
  String _selectedColor = '';
  String _selectedSize = '';

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider).products;
    final product = products.firstWhere(
      (p) => p.id == widget.productId,
      orElse: () => products.first,
    );
    final isFavorite =
        ref.watch(wishlistProvider).productIds.contains(product.id);

    // تعيين القيم الافتراضية
    if (_selectedColor.isEmpty && product.colors.isNotEmpty) {
      _selectedColor = product.colors.first;
    }
    if (_selectedSize.isEmpty && product.sizes.isNotEmpty) {
      _selectedSize = product.sizes.first;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // صور المنتج
                    Stack(
                      children: [
                        SizedBox(
                          height: 350,
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() => _currentImageIndex = index);
                            },
                            itemCount: product.images.isNotEmpty
                                ? product.images.length
                                : 1,
                            itemBuilder: (context, index) {
                              final image = product.images.isNotEmpty
                                  ? product.images[index]
                                  : product.image;
                              return CachedNetworkImage(
                                imageUrl: image,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              );
                            },
                          ),
                        ),
                        // أزرار الرجوع والمشاركة
                        Positioned(
                          top: 16,
                          right: 16,
                          left: 16,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildIconButton(
                                icon: Icons.arrow_back,
                                onPressed: () => context.pop(),
                              ),
                              Row(
                                children: [
                                  _buildIconButton(
                                    icon: isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isFavorite ? Colors.red : null,
                                    onPressed: () {
                                      ref
                                          .read(wishlistProvider.notifier)
                                          .toggleFavorite(product);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _buildIconButton(
                                    icon: Icons.share,
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // مؤشر الصور
                        if (product.images.length > 1)
                          Positioned(
                            bottom: 16,
                            right: 0,
                            left: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                product.images.length,
                                (index) => Container(
                                  width: _currentImageIndex == index ? 24 : 8,
                                  height: 8,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: _currentImageIndex == index
                                        ? AppColors.primary
                                        : Colors.white.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    // تفاصيل المنتج
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // اسم المنتج
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // التقييم
                          Row(
                            children: [
                              RatingStars(rating: product.rating),
                              const SizedBox(width: 8),
                              Text(
                                '(${product.reviewsCount} تقييم)',
                                style: const TextStyle(
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // السعر
                          Row(
                            children: [
                              Text(
                                '${product.price.toStringAsFixed(0)} ${product.currencySymbol}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              if (product.oldPrice != null) ...[
                                const SizedBox(width: 12),
                                Text(
                                  '${product.oldPrice!.toStringAsFixed(0)} ${product.currencySymbol}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[400],
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'شامل ضريبة القيمة المضافة',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // الوصف
                          Text(
                            product.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondaryLight,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // اختيار اللون
                          if (product.colors.isNotEmpty) ...[
                            const Text(
                              'اللون',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              children: product.colors.map((color) {
                                final isSelected = _selectedColor == color;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedColor = color),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: _getColorFromName(color),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 20,
                                            )
                                          : null,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                          ],
                          // اختيار المقاس
                          if (product.sizes.isNotEmpty) ...[
                            const Text(
                              'المقاس',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              children: product.sizes.map((size) {
                                final isSelected = _selectedSize == size;
                                return ChoiceChip(
                                  label: Text(size),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() => _selectedSize = size);
                                  },
                                  selectedColor:
                                      AppColors.primary.withOpacity(0.2),
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimaryLight,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                          ],
                          // الكمية
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'الكمية',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              QuantitySelector(
                                quantity: _quantity,
                                maxQuantity: product.stock,
                                onChanged: (value) {
                                  setState(() => _quantity = value);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'المتوفر: ${product.stock} قطعة',
                            style: TextStyle(
                              fontSize: 12,
                              color: product.stock > 5
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // زر الإضافة للسلة
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'الإجمالي',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        Text(
                          '${(product.price * _quantity).toStringAsFixed(0)} ${product.currencySymbol}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: 'إضافة إلى السلة 🛒',
                      onPressed: () {
                        final isAuthenticated =
                            ref.read(authProvider).isAuthenticated;
                        if (!isAuthenticated) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'الرجاء تسجيل الدخول لإضافة المنتجات إلى السلة'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          context.push('/login');
                          return;
                        }
                        ref.read(cartProvider.notifier).addItem(
                              product,
                              quantity: _quantity,
                              color: _selectedColor,
                              size: _selectedSize,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تمت الإضافة إلى السلة'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
      ),
    );
  }

  Color _getColorFromName(String name) {
    switch (name) {
      case 'أبيض':
        return Colors.white;
      case 'أسود':
        return Colors.black;
      case 'رمادي':
        return Colors.grey;
      case 'بني':
        return Colors.brown;
      case 'أزرق':
        return Colors.blue;
      case 'فضي':
        return Colors.grey[300]!;
      default:
        return Colors.grey;
    }
  }
}

// ============================================
// سلايدر البانرات العصري بنمط شي ان (SHEIN-style Banner)
// متصل بلوحة التحكم (Filament Dashboard) ويعرض عروض الموسم وتخفيضات 70%
// ============================================
class BannerSlider extends ConsumerStatefulWidget {
  const BannerSlider({super.key});

  @override
  ConsumerState<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends ConsumerState<BannerSlider> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      final banners = ref.read(bannersProvider).banners;
      final count = banners.isEmpty ? 1 : banners.length;
      if (count < 2 || !_pageController.hasClients) return;

      final next = (_currentIndex + 1) % count;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = ref.watch(bannersProvider).banners;
    final bannerCount = banners.isEmpty ? 1 : banners.length;

    return SizedBox(
      height: 215,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.09),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: bannerCount,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  final banner = banners.isNotEmpty ? banners[index] : null;
                  final bannerTitle = banner?.title ?? 'عروض شي ان: خصم حتى 70%';
                  final bannerLink = banner?.link ?? '/products?featured=1';
                  final bannerImageUrl = banner?.image ?? '';

                  return GestureDetector(
                    onTap: () {
                      if (bannerLink.isEmpty) return;
                      try {
                        context.push(bannerLink);
                      } catch (_) {}
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // خلفية متدرجة أنيقة للأزياء
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF1E1B4B),
                                Color(0xFF4338CA),
                                Color(0xFF831843),
                              ],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                          ),
                        ),

                        // صورة البانر (من لوحة التحكم مع Fallback للبانر المحلي المميز)
                        if (bannerImageUrl.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: bannerImageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Image.asset(
                              'assets/images/shein_sale_banner.jpg',
                              fit: BoxFit.cover,
                            ),
                            errorWidget: (_, __, ___) => Image.asset(
                              'assets/images/shein_sale_banner.jpg',
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Image.asset(
                            'assets/images/shein_sale_banner.jpg',
                            fit: BoxFit.cover,
                          ),

                        // طبقة تدرج لوني لتوضيح النصوص والبطاقات
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.65),
                                Colors.black.withOpacity(0.25),
                                Colors.transparent,
                                Colors.black.withOpacity(0.70),
                              ],
                              stops: const [0.0, 0.35, 0.6, 1.0],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                          ),
                        ),

                        // شارات التخفيضات العصرية بنمط SHEIN (أعلى اليمين)
                        Positioned(
                          top: 14,
                          right: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // وسم التخفيض القوي 70%
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFE11D48),
                                      Color(0xFFF43F5E),
                                      Color(0xFFFF0055),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFE11D48).withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.local_fire_department_rounded,
                                      color: Colors.amberAccent,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'خصم حتى 70%',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              // شارة تنزيلات حصرية
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Text(
                                  'تنزيلات حصرية • SHEIN Style',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // مؤشر العد التنازلي / فترة محدودة (أعلى اليسار)
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A).withOpacity(0.75),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.amberAccent.withOpacity(0.5),
                                width: 0.8,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.flash_on_rounded,
                                  color: Colors.amberAccent,
                                  size: 14,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'لفترة محدودة',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // محتوى أسفل البانر: العنوان وزر تسوق الآن
                        Positioned(
                          bottom: 14,
                          left: 14,
                          right: 14,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // عنوان البانر
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      bannerTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black54,
                                            offset: Offset(0, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'أحدث صيحات الموضة والأزياء بأسعار استثنائية',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              // زر تسوق الآن المميز
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'تسوق الآن',
                                      style: TextStyle(
                                        color: Color(0xFF111827),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 11,
                                      color: Color(0xFF111827),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // مؤشر النقاط الدائري والأفقي أسفل البانر
              if (bannerCount > 1)
                Positioned(
                  bottom: 6,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      bannerCount,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _currentIndex == index ? 22 : 6,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
