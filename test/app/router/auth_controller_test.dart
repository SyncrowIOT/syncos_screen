import 'package:flutter_test/flutter_test.dart';
import 'package:syncos_screen/app/router/auth_controller.dart';

AuthController _makeSut({
  required Future<bool> Function() ensureAuthenticated,
}) {
  final sut = AuthController(ensureAuthenticated: ensureAuthenticated);
  addTearDown(sut.dispose);
  return sut;
}

void main() {
  test('starts in loading state', () {
    final sut = _makeSut(
      ensureAuthenticated: () => Future<bool>.delayed(
        const Duration(seconds: 1),
        () => true,
      ),
    );

    expect(sut.status, AuthStatus.loading);
  });

  test(
    'transitions to authenticated when ensureAuthenticated succeeds',
    () async {
      final sut = _makeSut(ensureAuthenticated: () async => true);

      final statuses = <AuthStatus>[];
      sut.addListener(() => statuses.add(sut.status));

      await Future<void>.delayed(Duration.zero);

      expect(sut.status, AuthStatus.authenticated);
      expect(statuses, contains(AuthStatus.authenticated));
    },
  );

  test('transitions to error when ensureAuthenticated fails', () async {
    final sut = _makeSut(ensureAuthenticated: () async => false);

    await Future<void>.delayed(Duration.zero);

    expect(sut.status, AuthStatus.error);
  });

  test('transitions to error when ensureAuthenticated throws', () async {
    final sut = _makeSut(
      ensureAuthenticated: () async => throw Exception('boom'),
    );

    await Future<void>.delayed(Duration.zero);

    expect(sut.status, AuthStatus.error);
  });

  test(
    'retry re-runs ensureAuthenticated and can recover from error',
    () async {
      var attempt = 0;
      final sut = _makeSut(
        ensureAuthenticated: () async {
          attempt++;
          return attempt > 1;
        },
      );

      await Future<void>.delayed(Duration.zero);
      expect(sut.status, AuthStatus.error);

      sut.retry();
      expect(sut.status, AuthStatus.loading);

      await Future<void>.delayed(Duration.zero);
      expect(sut.status, AuthStatus.authenticated);
    },
  );

  test(
    'retry ignores calls while a run is already in flight',
    () async {
      var callCount = 0;
      final sut =
          _makeSut(
              ensureAuthenticated: () async {
                callCount++;
                await Future<void>.delayed(const Duration(milliseconds: 10));
                return true;
              },
            )
            ..retry()
            ..retry();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(callCount, 1);
      expect(sut.status, AuthStatus.authenticated);
    },
  );

  test(
    'retrySilently never transitions through loading and stays '
    'authenticated on success',
    () async {
      final sut = _makeSut(ensureAuthenticated: () async => true);
      await Future<void>.delayed(Duration.zero);
      expect(sut.status, AuthStatus.authenticated);

      final statuses = <AuthStatus>[];
      sut
        ..addListener(() => statuses.add(sut.status))
        ..retrySilently();
      expect(sut.status, AuthStatus.authenticated);

      await Future<void>.delayed(Duration.zero);

      expect(statuses, isNot(contains(AuthStatus.loading)));
      expect(sut.status, AuthStatus.authenticated);
    },
  );

  test(
    'retrySilently goes straight to error on failure without ever '
    'showing loading',
    () async {
      var shouldSucceed = true;
      final sut = _makeSut(ensureAuthenticated: () async => shouldSucceed);
      await Future<void>.delayed(Duration.zero);
      expect(sut.status, AuthStatus.authenticated);

      shouldSucceed = false;
      final statuses = <AuthStatus>[];
      sut
        ..addListener(() => statuses.add(sut.status))
        ..retrySilently();
      expect(sut.status, AuthStatus.authenticated);

      await Future<void>.delayed(Duration.zero);

      expect(statuses, isNot(contains(AuthStatus.loading)));
      expect(sut.status, AuthStatus.error);
    },
  );

  test(
    'awaitRecovery resolves immediately with the current status when '
    'no recovery is in flight',
    () async {
      final sut = _makeSut(ensureAuthenticated: () async => true);
      await Future<void>.delayed(Duration.zero);
      expect(sut.status, AuthStatus.authenticated);

      expect(await sut.awaitRecovery(), isTrue);
    },
  );

  test(
    'awaitRecovery waits for an in-flight recovery and reports its outcome',
    () async {
      final sut = _makeSut(
        ensureAuthenticated: () => Future<bool>.delayed(
          const Duration(milliseconds: 10),
          () => false,
        ),
      );

      expect(sut.status, AuthStatus.loading);
      expect(await sut.awaitRecovery(), isFalse);
      expect(sut.status, AuthStatus.error);
    },
  );
}
