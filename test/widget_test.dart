import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:marketplace_app/main.dart';
import 'package:marketplace_app/providers/auth_provider.dart';
import 'package:marketplace_app/providers/product_provider.dart';
import 'package:marketplace_app/providers/compare_provider.dart';
import 'package:marketplace_app/providers/favorites_provider.dart';
import 'package:marketplace_app/services/language_provider.dart';
import 'package:marketplace_app/screens/splash_screen.dart';

void main() {
  testWidgets('App renders SplashScreen on launch', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => CompareProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider<FavoritesProvider?>.value(value: null),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
