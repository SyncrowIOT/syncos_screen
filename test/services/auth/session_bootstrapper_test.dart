import 'package:auth/auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networking/networking.dart';
import 'package:syncos_screen/services/auth/session_bootstrapper.dart';
import 'package:syncos_screen/services/auth/token_refresh_service.dart';

class SpyTokenStore implements TokenStore {
  String? refreshTokenToReturn;
  String? accessTokenToReturn;
  final List<({String accessToken, String refreshToken})> writtenTokens = [];

  @override
  Future<String?> readRefreshToken() async => refreshTokenToReturn;

  @override
  Future<String?> readAccessToken() async => accessTokenToReturn;

  @override
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    writtenTokens.add((accessToken: accessToken, refreshToken: refreshToken));
  }

  @override
  Future<void> clearTokens() async {
    accessTokenToReturn = null;
    refreshTokenToReturn = null;
  }
}

class SpyTokenRefreshService implements TokenRefreshService {
  String accessTokenToReturn = 'new-access-token';
  Object? _errorToThrow;

  void completeWithError(Object error) {
    _errorToThrow = error;
  }

  @override
  Future<String> call() async {
    final error = _errorToThrow;
    if (error != null) throw Exception(error);
    return accessTokenToReturn;
  }
}

class SpyLoginService implements LoginService {
  final List<LoginParam> receivedParams = [];
  LoginModel modelToReturn = LoginModel(token: 'access-token');

  Object? _errorToThrow;
  int _failForAttempts = 0;

  void completeWithError(Object error, {int failForAttempts = 1 << 30}) {
    _errorToThrow = error;
    _failForAttempts = failForAttempts;
  }

  @override
  Future<LoginModel> login(LoginParam param) async {
    receivedParams.add(param);
    final error = _errorToThrow;
    if (error != null && receivedParams.length <= _failForAttempts) {
      throw Exception(error);
    }
    return modelToReturn;
  }
}

({
  SessionBootstrapper sut,
  SpyTokenStore tokenStore,
  SpyTokenRefreshService tokenRefreshService,
  SpyLoginService loginService,
  List<Duration> recordedDelays,
})
_makeSut({LoginParam Function()? credentialsBuilder}) {
  final tokenStore = SpyTokenStore();
  final tokenRefreshService = SpyTokenRefreshService();
  final loginService = SpyLoginService();
  final recordedDelays = <Duration>[];

  final sut = SessionBootstrapper(
    tokenStore: tokenStore,
    tokenRefreshService: tokenRefreshService,
    loginService: loginService,
    credentialsBuilder:
        credentialsBuilder ??
        () => LoginParam(
          email: 'test@example.com',
          password: 'secret',
          isMobilePlatform: true,
        ),
    delay: (duration) async => recordedDelays.add(duration),
  );

  return (
    sut: sut,
    tokenStore: tokenStore,
    tokenRefreshService: tokenRefreshService,
    loginService: loginService,
    recordedDelays: recordedDelays,
  );
}

void main() {
  group('silent refresh', () {
    test(
      'succeeds when a refresh token exists and refresh call succeeds',
      () async {
        final sut = _makeSut();
        sut.tokenStore.refreshTokenToReturn = 'stored-refresh-token';

        final result = await sut.sut.ensureAuthenticated();

        expect(result, isTrue);
        expect(sut.loginService.receivedParams, isEmpty);
      },
    );

    test('falls back to login when there is no stored refresh token', () async {
      final sut = _makeSut();
      sut.tokenStore.accessTokenToReturn = 'access-token';

      final result = await sut.sut.ensureAuthenticated();

      expect(result, isTrue);
      expect(sut.loginService.receivedParams, hasLength(1));
    });

    test('falls back to login when the refresh call throws', () async {
      final sut = _makeSut();
      sut.tokenStore.refreshTokenToReturn = 'stored-refresh-token';
      sut.tokenRefreshService.completeWithError(
        StateError('Invalid refresh response'),
      );
      sut.tokenStore.accessTokenToReturn = 'access-token';

      final result = await sut.sut.ensureAuthenticated();

      expect(result, isTrue);
      expect(sut.loginService.receivedParams, hasLength(1));
    });
  });

  group('login retries', () {
    test('retries with backoff and succeeds on the final attempt', () async {
      final sut = _makeSut();
      sut.loginService.completeWithError(
        Exception('login failed'),
        failForAttempts: 2,
      );
      sut.tokenStore.accessTokenToReturn = 'access-token';

      final result = await sut.sut.ensureAuthenticated();

      expect(result, isTrue);
      expect(sut.loginService.receivedParams, hasLength(3));
      expect(
        sut.recordedDelays,
        [const Duration(seconds: 2), const Duration(seconds: 4)],
      );
    });

    test('gives up after maxLoginAttempts and returns false', () async {
      final sut = _makeSut();
      sut.loginService.completeWithError(Exception('login failed'));

      final result = await sut.sut.ensureAuthenticated();

      expect(result, isFalse);
      expect(sut.loginService.receivedParams, hasLength(3));
      expect(
        sut.recordedDelays,
        [const Duration(seconds: 2), const Duration(seconds: 4)],
      );
    });

    test('treats a login that reports success but persists no token as a '
        'failure', () async {
      final sut = _makeSut();

      final result = await sut.sut.ensureAuthenticated();

      expect(result, isFalse);
      expect(sut.loginService.receivedParams, hasLength(3));
    });
  });
}
