// ============================================
// نقطة البداية الرئيسية للتطبيق
// Main Entry Point
// ============================================

import 'dart:async';

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

  // تهيئة Firebase والإشعارات بأمان مع مهلة زمنية قصيرة (4 ثوانٍ)
  // تمنع أي شاشة بيضاء أو تعليق وتضمن تسجيل معالج الخلفية بعد تهيئة Firebase بنجاح
  try {
    await FirebaseNotificationService.initialize().timeout(
      const Duration(seconds: 4),
      onTimeout: () {
        debugPrint('⚠️ مهلة تهيئة Firebase — المتابعة لعرض الواجهة');
      },
    );
  } catch (e) {
    debugPrint('⚠️ خطأ في تهيئة Firebase: $e');
  }

  runApp(
    // ProviderScope مطلوب لـ Riverpod
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();

    // الخادم مستضاف على Render (الخطة المجانية تُنيم الخدمة بعد خمول)،
    // فنُطلق طلب إيقاظ خفيفاً الآن لتبدأ الخدمة بالإقلاع بالتوازي مع شاشة
    // الدخول بدل أن يدفع المستخدم ثمن الـ cold start عند أول طلب.
    ApiClient.warmUp();

    // إنشاء عميل الـ API المشترك أولاً: داخله يتم ربط ApiClient بخدمة
    // الإشعارات (setFcmApiClient)، فلا يبقى التوكن غائباً عن طلب حفظ توكن FCM.
    ref.read(apiClientProvider);

    // جسر الإشعارات: يستمع للرسائل الواردة/المنقورة، لعودة التطبيق
    // للواجهة، ولتغيّر حالة تسجيل الدخول — ويحدّث القائمة والعدّاد تبعاً لذلك.
    ref.read(notificationsBridgeProvider);

    // التهيئة لا تُنتظر: لا نُجمّد الإقلاع على شبكة Firebase أو إذن الإشعارات.
    unawaited(FirebaseNotificationService.initialize());
  }

  @override
  Widget build(BuildContext context) {
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
