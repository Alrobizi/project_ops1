// ============================================
// نقطة البداية الرئيسية للتطبيق
// Main Entry Point
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_providers.dart';
import 'services/api_service.dart';
import 'services/firebase_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ربط ApiClient بخدمة الإشعارات لإرسال توكن FCM للسيرفر
  setFcmApiClient(ApiClient());

  // تهيئة Firebase والإشعارات
  await FirebaseNotificationService.initialize();

  runApp(
    // ProviderScope مطلوب لـ Riverpod
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeColorProvider);

    return MaterialApp.router(
      title: 'بركة عدن',
      debugShowCheckedModeBanner: false,

      // الثيم الديناميكي حسب لون المستخدم المفضل
      theme: AppTheme.lightTheme(themeState.primaryColor),
      darkTheme: AppTheme.darkTheme(themeState.primaryColor),

      // دعم RTL واللغة العربية
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // التنقل
      routerConfig: AppRouter.router,

      // فرض اتجاه RTL على مستوى التطبيق
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );
  }
}