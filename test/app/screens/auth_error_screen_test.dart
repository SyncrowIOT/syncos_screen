import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncos_screen/app/screens/auth_error_screen.dart';

import '../../helpers/helpers.dart';

void main() {
  testWidgets(
      'AuthErrorScreen shows the error message and calls onRetry when tapped',
      (tester) async {
    var retried = false;
    await tester.pumpApp(
      AuthErrorScreen(onRetry: () => retried = true),
    );

    expect(find.text('Unable to sign in'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Retry'));
    await tester.pump();

    expect(retried, isTrue);
  });
}
