import 'package:flutter_test/flutter_test.dart';
import 'package:syncos_screen/app/router/auth_controller.dart';

void main() {
  group('AuthController', () {
    test('starts in loading state', () {
      final controller = AuthController(
        ensureAuthenticated: () => Future<bool>.delayed(
          const Duration(seconds: 1),
          () => true,
        ),
      );
      addTearDown(controller.dispose);

      expect(controller.status, AuthStatus.loading);
    });

    test('transitions to authenticated when ensureAuthenticated succeeds',
        () async {
      final controller = AuthController(
        ensureAuthenticated: () async => true,
      );
      addTearDown(controller.dispose);

      final statuses = <AuthStatus>[];
      controller.addListener(() => statuses.add(controller.status));

      await Future<void>.delayed(Duration.zero);

      expect(controller.status, AuthStatus.authenticated);
      expect(statuses, contains(AuthStatus.authenticated));
    });

    test('transitions to error when ensureAuthenticated fails', () async {
      final controller = AuthController(
        ensureAuthenticated: () async => false,
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(controller.status, AuthStatus.error);
    });

    test('retry re-runs ensureAuthenticated and can recover from error',
        () async {
      var attempt = 0;
      final controller = AuthController(
        ensureAuthenticated: () async {
          attempt++;
          return attempt > 1;
        },
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);
      expect(controller.status, AuthStatus.error);

      controller.retry();
      expect(controller.status, AuthStatus.loading);

      await Future<void>.delayed(Duration.zero);
      expect(controller.status, AuthStatus.authenticated);
    });
  });
}
