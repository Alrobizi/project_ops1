// ============================================
// شاشة إدارة المنتجات (Admin Products Screen)
// إضافة وتعديل وحذف المنتجات وأسعارها وتصنيفها
// تتطلب صلاحية "products" على لوحة التحكم
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(adminProductsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductForm(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'إضافة منتج',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // رأس الشاشة
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'إدارة المنتجات',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.category, color: Colors.white),
                        tooltip: 'إضافة تصنيف',
                        onPressed: () => _showAddCategoryDialog(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: () =>
                            ref.read(adminProductsProvider.notifier).refresh(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // حقل البحث
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => ref
                        .read(adminProductsProvider.notifier)
                        .setSearch(_searchController.text),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن منتج بالاسم...',
                      hintStyle: const TextStyle(color: Colors.white60),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.white70),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.white70),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(adminProductsProvider.notifier)
                                    .setSearch('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildFiltersAndBody(context, productsState),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersAndBody(
      BuildContext context, AdminProductsState state) {
    return Expanded(
      child: Column(
        children: [
          const SizedBox(height: 12),

          // فلتر التصنيفات
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CategoryChip(
                  label: 'الكل',
                  selected: state.selectedCategoryId == null,
                  onTap: () => ref
                      .read(adminProductsProvider.notifier)
                      .setCategoryFilter(null),
                ),
                ...state.categories.map(
                  (c) => _CategoryChip(
                    label: c['name'].toString(),
                    selected:
                        state.selectedCategoryId == c['id'].toString(),
                    onTap: () => ref
                        .read(adminProductsProvider.notifier)
                        .setCategoryFilter(c['id'].toString()),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // المحتوى (تحميل / خطأ / فارغ / قائمة)
          Expanded(child: _buildBody(context, state)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AdminProductsState state) {
    if (state.isLoading && state.products.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.error != null && state.products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(adminProductsProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: Colors.grey.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text(
              'لا توجد منتجات بعد',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'اضغط على "إضافة منتج" لإضافة أول منتج',
              style: TextStyle(color: AppColors.textSecondaryLight),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(adminProductsProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
        itemCount: state.products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _ProductCard(
          product: state.products[index],
          categoryName: state.categoryNameOf(state.products[index].categoryId),
          onEdit: (p) => _showProductForm(context, product: p),
          onDelete: (p) => _confirmDelete(context, p),
        ),
      ),
    );
  }

  // ============================================
  // نموذج إضافة / تعديل منتج (Bottom Sheet)
  // ============================================
  Future<void> _showProductForm(BuildContext context,
      {Product? product}) async {
    final notifier = ref.read(adminProductsProvider.notifier);
    final categories = List<Map<String, dynamic>>.from(
        ref.read(adminProductsProvider).categories);

    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('أضف تصنيفاً أولاً من أيقونة التصنيفات بالأعلى'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final nameController = TextEditingController(text: product?.name ?? '');
    final descController =
        TextEditingController(text: product?.description ?? '');
    final priceController = TextEditingController(
        text: product != null && product.price > 0
            ? product.price.toString()
            : '');
    final oldPriceController =
        TextEditingController(text: product?.oldPrice?.toString() ?? '');
    final stockController =
        TextEditingController(text: product?.stock.toString() ?? '0');
    final imageController = TextEditingController(text: product?.image ?? '');
    String? selectedCategoryId =
        product?.categoryId ?? categories.first['id'].toString();
    String selectedCurrency = product?.currency == 'SAR' ? 'SAR' : 'YER';
    bool isActive = true;
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    product == null ? 'إضافة منتج جديد' : 'تعديل المنتج',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FormTextField(
                    controller: nameController,
                    label: 'اسم المنتج *',
                    icon: Icons.inventory_2_outlined,
                  ),
                  _FormTextField(
                    controller: descController,
                    label: 'الوصف',
                    icon: Icons.description_outlined,
                    maxLines: 3,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _FormTextField(
                          controller: priceController,
                          label: 'السعر *',
                          icon: Icons.payments_outlined,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FormTextField(
                          controller: oldPriceController,
                          label: 'السعر قبل الخصم',
                          icon: Icons.sell_outlined,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedCurrency,
                          decoration: const InputDecoration(
                            labelText: 'العملة',
                            prefixIcon: Icon(Icons.currency_exchange),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'YER', child: Text('ريال يمني (ر.ي)')),
                            DropdownMenuItem(
                                value: 'SAR', child: Text('ريال سعودي (ر.س)')),
                          ],
                          onChanged: (v) =>
                              setSheetState(() => selectedCurrency = v ?? 'YER'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FormTextField(
                          controller: stockController,
                          label: 'المخزون',
                          icon: Icons.warehouse_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'التصنيف *',
                      prefixIcon: Icon(Icons.category_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: categories
                        .map((c) => DropdownMenuItem(
                              value: c['id'].toString(),
                              child: Text(c['name'].toString()),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setSheetState(() => selectedCategoryId = v),
                  ),
                  _FormTextField(
                    controller: imageController,
                    label: 'رابط صورة المنتج (اختياري)',
                    icon: Icons.image_outlined,
                  ),
                  SwitchListTile(
                    value: isActive,
                    activeThumbColor: AppColors.primary,
                    title: const Text('المنتج مفعّل ويظهر في المتجر'),
                    onChanged: (v) => setSheetState(() => isActive = v),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final name = nameController.text.trim();
                            final price =
                                double.tryParse(priceController.text.trim());
                            if (name.isEmpty || price == null) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('يرجى إدخال اسم المنتج والسعر'),
                                      backgroundColor: Colors.red));
                              return;
                            }
                            if (selectedCategoryId == null) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  const SnackBar(
                                      content: Text('يرجى اختيار التصنيف'),
                                      backgroundColor: Colors.red));
                              return;
                            }

                            setSheetState(() => isSaving = true);

                            final data = <String, dynamic>{
                              'name': name,
                              'price': price,
                              'category_id': selectedCategoryId,
                              'description': descController.text.trim(),
                              'currency': selectedCurrency,
                              'stock':
                                  int.tryParse(stockController.text.trim()) ??
                                      0,
                              'is_active': isActive,
                            };
                            final oldPrice = double.tryParse(
                                oldPriceController.text.trim());
                            if (oldPrice != null) {
                              data['old_price'] = oldPrice;
                            }
                            if (imageController.text.trim().isNotEmpty) {
                              data['image'] = imageController.text.trim();
                            }

                            String? error;
                            if (product == null) {
                              error = await notifier.createProduct(
                                name: name,
                                price: price,
                                categoryId: selectedCategoryId!,
                                description: descController.text.trim(),
                                oldPrice: oldPrice,
                                currency: selectedCurrency,
                                image: imageController.text.trim().isEmpty
                                    ? null
                                    : imageController.text.trim(),
                                stock: int.tryParse(
                                        stockController.text.trim()) ??
                                    0,
                                isActive: isActive,
                              );
                            } else {
                              error = await notifier.updateProduct(
                                  product.id, data);
                            }

                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                content: Text(error ??
                                    (product == null
                                        ? 'تم إضافة المنتج بنجاح'
                                        : 'تم تحديث المنتج بنجاح')),
                                backgroundColor:
                                    error == null ? Colors.green : Colors.red,
                              ));
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            product == null ? 'إضافة المنتج' : 'حفظ التعديلات',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // نافذة إضافة تصنيف جديد
  // ============================================
  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final nameController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تصنيف جديد'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'اسم التصنيف',
            prefixIcon: Icon(Icons.category_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('إضافة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    if (nameController.text.trim().isEmpty) return;

    final categoryName = nameController.text.trim();
    final error = await ref
        .read(adminProductsProvider.notifier)
        .createCategory(categoryName);
    if (mounted) {
      ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
        content: Text(error ?? 'تم إضافة التصنيف بنجاح'),
        backgroundColor: error == null ? Colors.green : Colors.red,
      ));
    }
  }

  // ============================================
  // تأكيد حذف منتج
  // ============================================
  Future<void> _confirmDelete(BuildContext context, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: Text('هل أنت متأكد من حذف "${product.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final error = await ref
        .read(adminProductsProvider.notifier)
        .deleteProduct(product.id);
    if (mounted) {
      ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
        content: Text(error ?? 'تم حذف المنتج بنجاح'),
        backgroundColor: error == null ? Colors.green : Colors.red,
      ));
    }
  }
}

// ============================================
// بطاقة منتج في القائمة
// ============================================
class _ProductCard extends StatelessWidget {
  final Product product;
  final String categoryName;
  final void Function(Product) onEdit;
  final void Function(Product) onDelete;

  const _ProductCard({
    required this.product,
    required this.categoryName,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // صورة المنتج
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: product.image.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: product.image,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 64,
                      height: 64,
                      color: AppColors.primary.withOpacity(0.1),
                      child: Icon(Icons.image_outlined,
                          color: AppColors.primary),
                    ),
                  )
                : Container(
                    width: 64,
                    height: 64,
                    color: AppColors.primary.withOpacity(0.1),
                    child: Icon(Icons.inventory_2_outlined,
                        color: AppColors.primary),
                  ),
          ),
          const SizedBox(width: 12),
          // معلومات المنتج
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  categoryName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${product.price.toStringAsFixed(0)} ${product.currencySymbol}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    if (product.oldPrice != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        product.oldPrice!.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // المخزون وأزرار التعديل والحذف
          Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: product.stock > 0
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  product.stock > 0
                      ? 'مخزون: ${product.stock}'
                      : 'نفذ المخزون',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: product.stock > 0 ? Colors.green : Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined,
                        color: AppColors.primary, size: 22),
                    tooltip: 'تعديل',
                    onPressed: () => onEdit(product),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 22),
                    tooltip: 'حذف',
                    onPressed: () => onDelete(product),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================
// شريحة تصنيف للفلترة
// ============================================
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? Colors.white : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================
// حقل إدخال موحد للنموذج
// ============================================
class _FormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;

  const _FormTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: maxLines == 1 ? Icon(icon) : null,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
