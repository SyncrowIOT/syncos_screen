import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncos_screen/app/auth_gate.dart';

import '../helpers/helpers.dart';

void main() {
  group('AuthGate', () {
    testWidgets('shows a loading indicator while authenticating',
        (tester) async {
      await tester.pumpApp(
        AuthGate(
          ensureAuthenticated: () => Future<bool>.delayed(
            const Duration(seconds: 1),
            () => true,
          ),
          child: const Text('home'),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('home'), findsNothing);

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('shows the child once authentication succeeds',
        (tester) async {
      await tester.pumpApp(
        AuthGate(
          ensureAuthenticated: () async => true,
          child: const Text('home'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('shows a retry button when authentication fails, '
        'and retries on tap', (tester) async {
      var attempt = 0;
      await tester.pumpApp(
        AuthGate(
          ensureAuthenticated: () async {
            attempt++;
            return attempt > 1;
          },
          child: const Text('home'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('home'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
    });
  });
}
