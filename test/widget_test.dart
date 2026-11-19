import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace_app/screens/splash_screen.dart';

void main() {
  testWidgets('App renders SplashScreen on launch', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen(autoNavigate: false)),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
