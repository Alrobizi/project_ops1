// ============================================
// شاشة الدعم والأسئلة الشائعة وسياسة الخصوصية
// Support, FAQs & Privacy Policy Screen
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../providers/app_providers.dart';

class SupportPagesScreen extends ConsumerStatefulWidget {
  final int initialTab; // 0 = FAQs, 1 = Privacy/Pages

  const SupportPagesScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<SupportPagesScreen> createState() => _SupportPagesScreenState();
}

class _SupportPagesScreenState extends ConsumerState<SupportPagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _faqs = [];
  List<Map<String, dynamic>> _pages = [];
  bool _isLoading = true;

  static const List<Map<String, String>> _defaultFaqs = [
    {
      'question': 'كم تستغرق مدة توصيل الطلب؟',
      'answer':
          'يتم توصيل الطلبات داخل عدن خلال 24 ساعة، وللمحافظات الأخرى خلال 2 إلى 4 أيام عمل.',
    },
    {
      'question': 'هل يمكنني إلغاء الطلب بعد إرساله؟',
      'answer':
          'نعم، يمكنك إلغاء الطلب مباشرة من صفحة "طلباتي" طالما كان الطلب في حالة "قيد المراجعة".',
    },
    {
      'question': 'ما هي طرق الدفع المتوفرة؟',
      'answer':
          'نوفر الدفع عند الاستلام، والتحويل المصرفي المباشر، وقريباً المحافظ الإلكترونية (الكريمي والقطيبي).',
    },
    {
      'question': 'هل يمكنني استبدال أو إرجاع المنتج؟',
      'answer':
          'نعم، يمكنك طلب الاستبدال أو الإرجاع خلال 3 أيام من استلام الطلب بشرط أن يكون المنتج بحالته الأصلية.',
    },
  ];

  static const String _defaultPrivacy =
      'نحترم خصوصيتك ونلتزم بحماية بياناتك الشخصية.\n\n'
      '• نستخدم بيانات العنوان ورقم الهاتف فقط لتوصيل طلباتك والتواصل معك بشأنها.\n'
      '• لا نقوم بمشاركة بياناتك مع أي طرف ثالث غير مرتبط بعملية التوصيل.\n'
      '• يمكنك تعديل بيانات حسابك أو عناوينك في أي وقت من صفحة "حسابي".';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _loadContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    try {
      final api = ref.read(apiClientProvider);
      final results = await Future.wait([
        api.getPublicFaqs().catchError((_) => <Map<String, dynamic>>[]),
        api.getPublicPages().catchError((_) => <Map<String, dynamic>>[]),
      ]);
      if (mounted) {
        setState(() {
          _faqs = results[0];
          _pages = results[1];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _contactWhatsApp() async {
    final uri = Uri.parse(
      'https://wa.me/967772055335?text=${Uri.encodeComponent('مرحباً، أحتاج مساعدة بخصوص التطبيق')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final faqsToShow = _faqs.isNotEmpty ? _faqs : _defaultFaqs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مركز المساعدة والسياسات'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: primary,
          indicatorColor: primary,
          tabs: const [
            Tab(text: 'الأسئلة الشائعة'),
            Tab(text: 'السياسات والخصوصية'),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _contactWhatsApp,
            icon: const Icon(Icons.chat_rounded),
            label: const Text(
              'تواصل مع خدمة العملاء عبر واتساب',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: faqsToShow.length,
                  itemBuilder: (context, index) {
                    final item = faqsToShow[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          item['question']?.toString() ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        childrenPadding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        children: [
                          Text(
                            item['answer']?.toString() ?? '',
                            style: const TextStyle(
                              color: AppColors.textSecondaryLight,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: _pages.isNotEmpty
                      ? _pages
                          .map((p) => Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p['title']?.toString() ?? '',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        p['content']?.toString() ?? '',
                                        style: const TextStyle(
                                          color: AppColors.textSecondaryLight,
                                          height: 1.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ))
                          .toList()
                      : [
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'سياسة الخصوصية والاستخدام',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    _defaultPrivacy,
                                    style: TextStyle(
                                      color: AppColors.textSecondaryLight,
                                      height: 1.7,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                ),
              ],
            ),
    );
  }
}
