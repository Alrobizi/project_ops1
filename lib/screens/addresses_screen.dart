// ============================================
// شاشة إدارة العناوين (Addresses Screen)
// عرض / إضافة / حذف / تعيين العنوان الافتراضي
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/location/app_locations.dart';
import '../core/theme/app_colors.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import '../services/location_service.dart';
import '../widgets/common_widgets.dart';

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  List<Address> _addresses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await ref.read(apiClientProvider).getAddresses();
      if (mounted) {
        setState(() {
          _addresses = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'تعذر تحميل العناوين، تأكد من تسجيل الدخول والاتصال بالإنترنت';
        });
      }
    }
  }

  Future<void> _deleteAddress(Address address) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف العنوان'),
        content: const Text('هل أنت متأكد من حذف هذا العنوان؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(apiClientProvider).deleteAddress(address.id);
      await _loadAddresses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف العنوان بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر حذف العنوان'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _setDefault(Address address) async {
    try {
      await ref.read(apiClientProvider).setDefaultAddress(address.id);
      await _loadAddresses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تعيين العنوان كافتراضي'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (_) {}
  }

  void _openAddAddressSheet() {
    String selectedGov = AppLocationDefaults.defaultGovernorate;
    final cityCtrl = TextEditingController(text: AppLocationDefaults.defaultCity);
    final districtCtrl = TextEditingController();
    final streetCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(
      text: ref.read(authProvider).user?.phone ?? '',
    );
    bool isDefault = _addresses.isEmpty;
    bool isSaving = false;
    bool isDetectingGps = false;
    double? lat;
    double? lng;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إضافة عنوان توصيل جديد',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: isDetectingGps
                      ? null
                      : () async {
                          setSheetState(() => isDetectingGps = true);
                          try {
                            final gps = await LocationService.getCurrentPosition();
                            if (gps.success && gps.position != null) {
                              lat = gps.position!.latitude;
                              lng = gps.position!.longitude;
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم تحديد موقعك عبر GPS بنجاح'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            }
                          } catch (_) {}
                          setSheetState(() => isDetectingGps = false);
                        },
                  icon: isDetectingGps
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(
                    lat != null
                        ? 'تم حفظ إحداثيات GPS ✓'
                        : 'تحديد موقعي الحالي (GPS)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedGov,
                  decoration: InputDecoration(
                    labelText: 'المحافظة',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: yemenGovernorates
                      .map((g) => DropdownMenuItem(value: g.name, child: Text(g.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setSheetState(() => selectedGov = v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cityCtrl,
                  decoration: InputDecoration(
                    labelText: 'المدينة / المديرية',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: districtCtrl,
                  decoration: InputDecoration(
                    labelText: 'الحي / المنطقة',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: streetCtrl,
                  decoration: InputDecoration(
                    labelText: 'الشارع / أقرب معلم',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'رقم الجوال للتواصل',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isDefault,
                  title: const Text('تعيين كعنوان افتراضي'),
                  onChanged: (v) => setSheetState(() => isDefault = v ?? false),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (cityCtrl.text.trim().isEmpty ||
                                districtCtrl.text.trim().isEmpty ||
                                streetCtrl.text.trim().isEmpty ||
                                phoneCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('الرجاء تعبئة كافة الحقول المطلوبة'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }
                            setSheetState(() => isSaving = true);
                            try {
                              await ref.read(apiClientProvider).createAddress(
                                    Address(
                                      id: '',
                                      governorate: selectedGov,
                                      city: cityCtrl.text.trim(),
                                      district: districtCtrl.text.trim(),
                                      street: streetCtrl.text.trim(),
                                      phone: phoneCtrl.text.trim(),
                                      isDefault: isDefault,
                                      latitude: lat,
                                      longitude: lng,
                                      isGpsLocation: lat != null,
                                    ),
                                  );
                              if (ctx.mounted) Navigator.pop(ctx);
                              await _loadAddresses();
                            } catch (_) {
                              setSheetState(() => isSaving = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('تعذر حفظ العنوان، حاول مجدداً'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'حفظ العنوان',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('عناويني'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddAddressSheet,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('إضافة عنوان'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAddresses,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? EmptyState(
                    icon: Icons.location_off_outlined,
                    title: 'تعذر التحميل',
                    subtitle: _error!,
                    buttonText: 'إعادة المحاولة',
                    onButtonPressed: _loadAddresses,
                  )
                : _addresses.isEmpty
                    ? EmptyState(
                        icon: Icons.location_on_outlined,
                        title: 'لا توجد عناوين محفوظة',
                        subtitle: 'أضف عنوان التوصيل الخاص بك لتسريع الطلبات',
                        buttonText: 'إضافة عنوان جديد',
                        onButtonPressed: _openAddAddressSheet,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                        itemCount: _addresses.length,
                        itemBuilder: (context, index) {
                          final addr = _addresses[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: addr.isDefault
                                    ? primary
                                    : AppColors.borderLight,
                                width: addr.isDefault ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      addr.isGpsLocation
                                          ? Icons.gps_fixed
                                          : Icons.location_on,
                                      color: primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${addr.governorate} — ${addr.city}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    if (addr.isDefault)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: primary.withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'افتراضي',
                                          style: TextStyle(
                                            color: primary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${addr.district}، ${addr.street}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondaryLight,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'الجوال: ${addr.phone}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondaryLight,
                                    fontSize: 12,
                                  ),
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (!addr.isDefault)
                                      TextButton.icon(
                                        onPressed: () => _setDefault(addr),
                                        icon: const Icon(
                                          Icons.check_circle_outline,
                                          size: 18,
                                        ),
                                        label: const Text('تعيين كافتراضي'),
                                      ),
                                    TextButton.icon(
                                      onPressed: () => _deleteAddress(addr),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: AppColors.error,
                                      ),
                                      label: const Text(
                                        'حذف',
                                        style:
                                            TextStyle(color: AppColors.error),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
