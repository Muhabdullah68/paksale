import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  ProductModel buildProduct({
    String sellerId = 'seller-1',
    String sellerPhone = '+92 300 1234567',
  }) => ProductModel(
    id: 'test-product',
    title: 'Compact card test listing',
    price: 100000,
    category: 'Vehicles',
    condition: 'Used',
    sellerType: 'Personal',
    sellerId: sellerId,
    sellerPhone: sellerPhone,
    createdAt: DateTime.now(),
  );

  void mockClipboard() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') return null;
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
  }

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

  test('shared listing links use the stable live website on web and app', () {
    expect(
      ShareService.productUrl('listing-123'),
      'https://paksale.net/listing/listing-123',
    );
    expect(ShareService.siteBase, 'https://paksale.net');
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

    // Circles use rgb(74,10,30) = #4A0A1E, with white glyphs for contrast.
    final circles = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .where((c) => c.decoration is BoxDecoration)
        .toList();
    expect(circles.length, 6);
    for (final circle in circles) {
      expect((circle.decoration as BoxDecoration).color, AppColors.primaryDark);
    }
    // The surrounding card uses the same plum instead of white.
    final card =
        find
                .byWidgetPredicate(
                  (w) =>
                      w is Container &&
                      w.decoration is BoxDecoration &&
                      (w.decoration as BoxDecoration).color ==
                          AppColors.primaryDark,
                )
                .evaluate()
                .first
                .widget
            as Container;
    expect(card.decoration, isA<BoxDecoration>());
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

    // Chips live in the image Stack, above the title and under the heart.
    expect(
      tester.getCenter(find.text('Call')).dy,
      lessThan(tester.getCenter(find.text(product.title)).dy),
    );

    await tester.tap(find.text('Compare'));
    await tester.pumpAndSettle();
    expect(compareProvider.isInCompare(product.id), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('list product card chips sit under the heart at the right edge', (
    tester,
  ) async {
    setViewport(tester, const Size(360, 720));

    final compareProvider = CompareProvider();
    final product = buildProduct();

    await tester.pumpWidget(
      testApp(
        Center(
          child: SizedBox(width: 360, child: ProductCard(product: product)),
        ),
        compareProvider: compareProvider,
      ),
    );
    await tester.pumpAndSettle();

    expect(actionLabels(tester), ['Call', 'Chat', 'Share', 'Compare']);

    final heart = find.byIcon(Icons.favorite_border);
    expect(heart, findsOneWidget);
    // Chips are directly below the heart ...
    expect(
      tester.getCenter(find.text('Call')).dy,
      greaterThan(tester.getCenter(heart).dy),
    );
    // ... at the right edge, right of the title.
    expect(
      tester.getCenter(find.text('Call')).dx,
      greaterThan(tester.getCenter(find.text(product.title)).dx),
    );

    await tester.tap(find.text('Compare'));
    await tester.pumpAndSettle();
    expect(compareProvider.isInCompare(product.id), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping chip padding runs the action without opening the card', (
    tester,
  ) async {
    setViewport(tester, const Size(360, 720));

    final product = buildProduct();
    var navigations = 0;
    var shares = 0;

    await tester.pumpWidget(
      testApp(
        Center(
          child: SizedBox(
            width: 360,
            child: ProductCard(
              product: product,
              onTap: () => navigations++,
              onShare: () => shares++,
            ),
          ),
        ),
        compareProvider: CompareProvider(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the chip's padding near its corner - the region that used to fall
    // through to the card's onTap because of deferToChild hit testing.
    final shareChip = find
        .ancestor(
          of: find.text('Share'),
          matching: find.byType(GestureDetector),
        )
        .first;
    final rect = tester.getRect(shareChip);
    await tester.tapAt(rect.topLeft + const Offset(2, 2));
    await tester.pumpAndSettle();

    expect(shares, 1);
    expect(navigations, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('web product card actions fit and keep their order', (
    tester,
  ) async {
    setViewport(tester, const Size(320, 720));

    final product = buildProduct();
    final compareProvider = CompareProvider();

    await tester.pumpWidget(
      testApp(
        Center(
          child: SizedBox(
            width: 180,
            height: 320,
            child: WebProductCard(product: product),
          ),
        ),
        compareProvider: compareProvider,
      ),
    );
    await tester.pumpAndSettle();

    expect(actionLabels(tester), ['Call', 'Chat', 'Share', 'Compare']);

    // Chips sit in a vertical rail at the bottom-right of the details area:
    // below the heart and to the right of the title.
    final heart = find.byIcon(Icons.favorite_border);
    expect(heart, findsOneWidget);
    expect(
      tester.getCenter(find.text('Call')).dy,
      greaterThan(tester.getCenter(heart).dy),
    );
    expect(
      tester.getCenter(find.text('Call')).dx,
      greaterThan(tester.getCenter(find.text(product.title)).dx),
    );

    await tester.tap(find.text('Compare'));
    await tester.pumpAndSettle();
    expect(compareProvider.isInCompare(product.id), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping web chip padding runs the action without navigation', (
    tester,
  ) async {
    setViewport(tester, const Size(320, 720));

    final product = buildProduct();
    var navigations = 0;
    var shares = 0;

    await tester.pumpWidget(
      testApp(
        Center(
          child: SizedBox(
            width: 180,
            height: 320,
            child: WebProductCard(
              product: product,
              onTap: () => navigations++,
              onShare: () => shares++,
            ),
          ),
        ),
        compareProvider: CompareProvider(),
      ),
    );
    await tester.pumpAndSettle();

    final shareChip = find
        .ancestor(
          of: find.text('Share'),
          matching: find.byType(GestureDetector),
        )
        .first;
    final rect = tester.getRect(shareChip);
    await tester.tapAt(rect.topLeft + const Offset(2, 2));
    await tester.pumpAndSettle();

    expect(shares, 1);
    expect(navigations, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Call opens the number sheet without waiting on Firestore', (
    tester,
  ) async {
    setViewport(tester, const Size(360, 720));
    mockClipboard();
    final product = buildProduct(sellerId: '');

    await tester.pumpWidget(
      testApp(
        Center(
          child: SizedBox(width: 360, child: ProductCard(product: product)),
        ),
        compareProvider: CompareProvider(),
      ),
    );
    await tester.pumpAndSettle();

    // One frame after the tap is enough — no async privacy check involved.
    await tester.tap(find.text('Call'));
    await tester.pump();

    expect(find.text('Call ${product.sellerName}'), findsOneWidget);
    expect(find.text('+923001234567'), findsOneWidget);
    expect(find.text('Copy number'), findsOneWidget);
    expect(find.text('Dial'), findsOneWidget);

    await tester.tap(find.text('Copy number'));
    await tester.pumpAndSettle();
    expect(find.text('Number copied to clipboard'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Call opens the number sheet on Web Home cards too', (
    tester,
  ) async {
    setViewport(tester, const Size(320, 720));
    mockClipboard();
    final product = buildProduct(sellerId: '');

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

    await tester.tap(find.text('Call'));
    await tester.pump();

    expect(find.text('Call ${product.sellerName}'), findsOneWidget);
    expect(find.text('+923001234567'), findsOneWidget);
    expect(find.text('Copy number'), findsOneWidget);
    expect(find.text('Dial'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact action chips use a readable font size', (tester) async {
    setViewport(tester, const Size(320, 720));

    await tester.pumpWidget(
      testApp(
        Center(
          child: SizedBox(
            width: 143,
            height: 260,
            child: ProductCard(product: buildProduct(), isGridView: true),
          ),
        ),
        compareProvider: CompareProvider(),
      ),
    );
    await tester.pumpAndSettle();

    const labels = {'Call', 'Chat', 'Share', 'Compare'};
    final chipTexts = tester
        .widgetList<Text>(find.byType(Text))
        .where((text) => labels.contains(text.data));
    expect(chipTexts.length, 4);
    for (final text in chipTexts) {
      expect(text.style?.fontSize, greaterThanOrEqualTo(9));
    }
    expect(tester.takeException(), isNull);
  });
}
