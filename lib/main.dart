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
        // FavoritesProvider needs uid, so we use ProxyProvider
        ChangeNotifierProxyProvider<AuthProvider, FavoritesProvider?>(
          create: (_) => null,
          update: (_, auth, previous) {
            if (auth.isAuthenticated && auth.firebaseUser != null) {
              return FavoritesProvider(uid: auth.firebaseUser!.uid);
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
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final langProvider = context.watch<LanguageProvider>();
    
    return MaterialApp(
      title: 'Pak Sale',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      themeAnimationDuration: const Duration(milliseconds: 100), // Faster transition
      builder: (context, child) {
        final cmsProvider = context.watch<CMSProvider>();
        if (cmsProvider.maintenanceMode) {
          return Directionality(
            textDirection: langProvider.isRTL ? TextDirection.rtl : TextDirection.ltr,
            child: const MaintenanceScreen(),
          );
        }
        return Directionality(
          textDirection: langProvider.isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}
