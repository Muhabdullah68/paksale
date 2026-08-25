import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/maintenance_screen.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/compare_provider.dart';
import 'services/language_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/report_provider.dart';
import 'providers/cms_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/order_provider.dart';
import 'services/theme_provider.dart';
import 'services/currency_provider.dart';
import 'web/app_router.dart';
import 'web/web_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (wrapped in try-catch to allow app to run even if options are placeholders)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CompareProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider(create: (_) => CMSProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProxyProvider<AuthProvider, FavoritesProvider?>(
          create: (_) => null,
          update: (_, auth, previous) {
            if (auth.isAuthenticated && auth.firebaseUser != null) {
              final newUid = auth.firebaseUser!.uid;
              if (previous != null && previous.uid == newUid) {
                return previous;
              }
              return FavoritesProvider(uid: newUid);
            }
            return null;
          },
        ),
        // NotificationProvider streams per-user notifications from Firestore
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (_) => NotificationProvider(),
          lazy: false,
          update: (_, auth, previous) {
            final provider = previous ?? NotificationProvider();
            if (auth.isAuthenticated && auth.firebaseUser != null) {
              provider.init(auth.firebaseUser!.uid);
            } else {
              provider.clear();
            }
            return provider;
          },
        ),
        // Web navigation state (only meaningful on web builds)
        ChangeNotifierProvider.value(value: WebNav.instance),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();

    final darkTheme = AppTheme.darkTheme.copyWith(
      scrollbarTheme: _webScrollbarTheme(Brightness.dark),
    );

    if (kIsWeb) {
      return MaterialApp.router(
        title: 'Pak Sale',
        debugShowCheckedModeBanner: false,
        theme: darkTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.dark,
        themeAnimationDuration: const Duration(milliseconds: 100),
        scrollBehavior: _WebScrollBehavior(),
        builder: (context, child) => _wrapApp(context, child, langProvider),
        routerConfig: appRouter,
      );
    }

    return MaterialApp(
      title: 'Pak Sale',
      debugShowCheckedModeBanner: false,
      theme: darkTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark,
      themeAnimationDuration: const Duration(milliseconds: 100),
      builder: (context, child) => _wrapApp(context, child, langProvider),
      home: const SplashScreen(),
    );
  }

  Widget _wrapApp(
      BuildContext context, Widget? child, LanguageProvider langProvider) {
    final cmsProvider = context.watch<CMSProvider>();
    final direction = Directionality(
      textDirection:
          langProvider.isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: cmsProvider.maintenanceMode ? const MaintenanceScreen() : child!,
    );
    if (!kIsWeb) return direction;
    return ScrollConfiguration(
      behavior: _WebScrollBehavior(),
      child: direction,
    );
  }

  ScrollbarThemeData _webScrollbarTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ScrollbarThemeData(
      thickness: WidgetStateProperty.all(kIsWeb ? 8.0 : 4.0),
      radius: const Radius.circular(10),
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return AppColors.gold;
        }
        if (states.contains(WidgetState.dragged)) {
          return AppColors.goldLight;
        }
        return isDark
            ? Colors.white.withValues(alpha: 0.25)
            : Colors.black.withValues(alpha: 0.2);
      }),
      trackColor: WidgetStateProperty.all(Colors.transparent),
      crossAxisMargin: 2,
      mainAxisMargin: 6,
      interactive: kIsWeb,
    );
  }
}

class _WebScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.trackpad,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}
