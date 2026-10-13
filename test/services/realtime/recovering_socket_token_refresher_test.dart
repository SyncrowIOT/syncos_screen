import 'package:flutter_test/flutter_test.dart';
import 'package:syncos_screen/services/auth/token_refresh_service.dart';
import 'package:syncos_screen/services/realtime/recovering_socket_token_refresher.dart';

import '../../helpers/token_store_spy.dart';

class TokenRefreshServiceSpy implements TokenRefreshService {
  int callCount = 0;
  String tokenToReturn = 'refreshed-token';
  Exception? _error;

  void completeWithError(Exception error) => _error = error;

  @override
  Future<String> call() async {
    callCount++;
    final error = _error;
    if (error != null) throw error;
    return tokenToReturn;
  }
}

class RecoveryWaiterSpy {
  int callCount = 0;
  bool recovered = true;
  void Function()? onRecover;

  Future<bool> call() async {
    callCount++;
    onRecover?.call();
    return recovered;
  }
}

({
  RecoveringSocketTokenRefresher sut,
  TokenRefreshServiceSpy tokenRefreshService,
  TokenStoreSpy tokenStore,
  RecoveryWaiterSpy recoveryWaiter,
})
_makeSut({String? accessToken = 'stale-token'}) {
  final tokenRefreshService = TokenRefreshServiceSpy();
  final tokenStore = TokenStoreSpy(accessToken: accessToken);
  final recoveryWaiter = RecoveryWaiterSpy();
  return (
    sut: RecoveringSocketTokenRefresher(
      tokenRefreshService: tokenRefreshService,
      tokenStore: tokenStore,
      awaitRecovery: recoveryWaiter.call,
    ),
    tokenRefreshService: tokenRefreshService,
    tokenStore: tokenStore,
    recoveryWaiter: recoveryWaiter,
  );
}

void main() {
  test('returns the refreshed token without waiting for recovery', () async {
    final (:sut, :tokenRefreshService, tokenStore: _, :recoveryWaiter) =
        _makeSut();

    expect(await sut(), 'refreshed-token');
    expect(tokenRefreshService.callCount, 1);
    expect(recoveryWaiter.callCount, 0);
  });

  test(
    'returns the re-login token when refresh fails and recovery succeeds',
    () async {
      final (:sut, :tokenRefreshService, :tokenStore, :recoveryWaiter) =
          _makeSut();
      tokenRefreshService.completeWithError(Exception('invalid refresh'));
      recoveryWaiter.onRecover = () => tokenStore.accessToken = 'login-token';

      expect(await sut(), 'login-token');
      expect(recoveryWaiter.callCount, 1);
    },
  );

  test(
    'throws a StateError when refresh fails and recovery fails',
    () async {
      final (:sut, :tokenRefreshService, tokenStore: _, :recoveryWaiter) =
          _makeSut();
      tokenRefreshService.completeWithError(Exception('invalid refresh'));
      recoveryWaiter.recovered = false;

      await expectLater(sut(), throwsStateError);
    },
  );

  test(
    'rethrows the refresh error when recovery leaves the token unchanged',
    () async {
      final (:sut, :tokenRefreshService, tokenStore: _, recoveryWaiter: _) =
          _makeSut();
      final error = Exception('network down');
      tokenRefreshService.completeWithError(error);

      await expectLater(sut(), throwsA(same(error)));
    },
  );

  test(
    'rethrows the refresh error when no token is stored after recovery',
    () async {
      final (:sut, :tokenRefreshService, :tokenStore, :recoveryWaiter) =
          _makeSut();
      final error = Exception('network down');
      tokenRefreshService.completeWithError(error);
      recoveryWaiter.onRecover = () => tokenStore.accessToken = null;

      await expectLater(sut(), throwsA(same(error)));
    },
  );

  test(
    'rethrows the refresh error when an empty token is stored after recovery',
    () async {
      final (:sut, :tokenRefreshService, :tokenStore, :recoveryWaiter) =
          _makeSut();
      final error = Exception('network down');
      tokenRefreshService.completeWithError(error);
      recoveryWaiter.onRecover = () => tokenStore.accessToken = '';

      await expectLater(sut(), throwsA(same(error)));
    },
  );
}
