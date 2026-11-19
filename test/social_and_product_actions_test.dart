import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marketplace_app/models/product_model.dart';
import 'package:marketplace_app/providers/compare_provider.dart';
import 'package:marketplace_app/providers/favorites_provider.dart';
import 'package:marketplace_app/services/currency_provider.dart';
import 'package:marketplace_app/services/language_provider.dart';
import 'package:marketplace_app/services/share_service.dart';
import 'package:marketplace_app/theme/app_theme.dart';
import 'package:marketplace_app/web/web_product_card.dart';
import 'package:marketplace_app/widgets/common_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget testApp(Widget child, {required CompareProvider compareProvider}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider<CompareProvider?>.value(value: compareProvider),
        ChangeNotifierProvider<FavoritesProvider?>.value(value: null),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  void setViewport(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  List<String> actionLabels(WidgetTester tester) {
    const labels = {'Call', 'Chat', 'Share', 'Compare'};
    return tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data ?? '')
        .where(labels.contains)
        .toList();
  }

  ProductModel buildProduct() => ProductModel(
        id: 'test-product',
        title: 'Compact card test listing',
        price: 100000,
        category: 'Vehicles',
        condition: 'Used',
        sellerType: 'Personal',
        sellerId: 'seller-1',
        createdAt: DateTime.now(),
      );

  test('normalizes local and international phone numbers', () {
    expect(normalizePhoneNumber('0300 1234567'), '+923001234567');
    expect(normalizePhoneNumber('+92 300-1234567'), '+923001234567');
    expect(normalizePhoneNumber('0092 300 1234567'), '+923001234567');
    expect(normalizePhoneNumber(''), '');
  });

  test('call privacy allows missing flags and blocks only explicit false', () {
    expect(allowCallsFromFlag(null), isTrue);
    expect(allowCallsFromFlag(true), isTrue);
    expect(allowCallsFromFlag(false), isFalse);
  });

  test('shared listing links use a stable path URL', () {
    expect(
      ShareService.productUrl('listing-123'),
      'https://paksale.app/listing/listing-123',
    );
  });

  testWidgets('social panel wraps all six links on a narrow viewport', (
    tester,
  ) async {
    setViewport(tester, const Size(320, 720));

    await tester.pumpWidget(
      testApp(
        const Center(child: SizedBox(width: 320, child: SocialMediaFooter())),
        compareProvider: CompareProvider(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('TikTok'), findsOneWidget);
    expect(find.byTooltip('Instagram'), findsOneWidget);
    expect(find.byTooltip('Snapchat'), findsOneWidget);
    expect(find.byTooltip('YouTube'), findsOneWidget);
    expect(find.byTooltip('X'), findsOneWidget);
    expect(find.byTooltip('Facebook'), findsOneWidget);

    // Icons sit on the app-wide plum, with white glyphs for contrast.
    final circles = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .where((c) => c.decoration is BoxDecoration)
        .toList();
    expect(circles.length, 6);
    for (final circle in circles) {
      expect((circle.decoration as BoxDecoration).color, AppColors.primary);
    }
    final icons = tester.widgetList<FaIcon>(find.byType(FaIcon));
    expect(icons.length, 6);
    for (final icon in icons) {
      expect(icon.color, Colors.white);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('grid product actions fit a compact mobile card', (tester) async {
    setViewport(tester, const Size(320, 720));

    final compareProvider = CompareProvider();
    final product = buildProduct();

    await tester.pumpWidget(
      testApp(
        Center(
          child: SizedBox(
            width: 143,
            height: 260,
            child: ProductCard(product: product, isGridView: true),
          ),
        ),
        compareProvider: compareProvider,
      ),
    );
    await tester.pumpAndSettle();

    expect(actionLabels(tester), ['Call', 'Chat', 'Share', 'Compare']);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Compare'));
    await tester.pumpAndSettle();
    expect(compareProvider.isInCompare(product.id), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('web product card actions fit and keep their order', (tester) async {
    setViewport(tester, const Size(320, 720));

    final product = buildProduct();

    await tester.pumpWidget(
      testApp(
        Center(
          child: SizedBox(
            width: 180,
            height: 320,
            child: WebProductCard(product: product),
          ),
        ),
        compareProvider: CompareProvider(),
      ),
    );
    await tester.pumpAndSettle();

    expect(actionLabels(tester), ['Call', 'Chat', 'Share', 'Compare']);
    expect(tester.takeException(), isNull);
  });
}
