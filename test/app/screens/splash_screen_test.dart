import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncos_screen/app/screens/splash_screen.dart';

import '../../helpers/helpers.dart';

void main() {
  testWidgets('SplashScreen shows a loading indicator', (tester) async {
    await tester.pumpApp(const SplashScreen());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
