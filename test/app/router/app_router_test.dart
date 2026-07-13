import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syncos_screen/app/router/app_router.dart';
import 'package:syncos_screen/app/router/auth_controller.dart';
import 'package:syncos_screen/l10n/l10n.dart';

GoRouter _buildTestRouter(AuthController authController) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authController,
    redirect: (context, state) => authGateRedirect(authController, state),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: '/auth-error',
        builder: (context, state) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: authController.retry,
              child: const Text('Retry'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const Text('home'),
      ),
    ],
  );
}

Future<void> _pumpRouter(WidgetTester tester, GoRouter router) {
  return tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  group('authGateRedirect', () {
    testWidgets('shows splash while authenticating, then home on success',
        (tester) async {
      final authController = AuthController(
        ensureAuthenticated: () => Future<bool>.delayed(
          const Duration(seconds: 1),
          () => true,
        ),
      );
      addTearDown(authController.dispose);

      await _pumpRouter(tester, _buildTestRouter(authController));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('home'), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
    });

    testWidgets(
        'shows auth-error with retry when authentication fails, '
        'and returns home once retry succeeds', (tester) async {
      var attempt = 0;
      final authController = AuthController(
        ensureAuthenticated: () async {
          attempt++;
          return attempt > 1;
        },
      );
      addTearDown(authController.dispose);

      await _pumpRouter(tester, _buildTestRouter(authController));
      await tester.pumpAndSettle();

      expect(find.text('home'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
    });
  });
}
