import 'package:auth/auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:networking/networking.dart';
import 'package:syncos_screen/services/auth/session_bootstrapper.dart';

class _MockTokenStore extends Mock implements TokenStore {}

class _MockTokenRefreshService extends Mock
    implements RemoteTokenRefreshService {}

class _MockLoginService extends Mock implements LoginService {}

class _FakeLoginParam extends Fake implements LoginParam {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeLoginParam());
  });

  late _MockTokenStore tokenStore;
  late _MockTokenRefreshService tokenRefreshService;
  late _MockLoginService loginService;
  late List<Duration> recordedDelays;

  SessionBootstrapper buildBootstrapper({
    LoginParam Function()? credentialsBuilder,
  }) {
    return SessionBootstrapper(
      tokenStore: tokenStore,
      tokenRefreshService: tokenRefreshService,
      loginService: loginService,
      credentialsBuilder: credentialsBuilder ??
          () => LoginParam(
                email: 'test@example.com',
                password: 'secret',
                isMobilePlatform: true,
              ),
      delay: (duration) async => recordedDelays.add(duration),
      backoff: const [Duration(seconds: 2), Duration(seconds: 4)],
    );
  }

  setUp(() {
    tokenStore = _MockTokenStore();
    tokenRefreshService = _MockTokenRefreshService();
    loginService = _MockLoginService();
    recordedDelays = [];
  });

  group('silent refresh', () {
    test('succeeds when a refresh token exists and refresh call succeeds',
        () async {
      when(() => tokenStore.readRefreshToken())
          .thenAnswer((_) async => 'stored-refresh-token');
      when(() => tokenRefreshService.call())
          .thenAnswer((_) async => 'new-access-token');

      final result = await buildBootstrapper().ensureAuthenticated();

      expect(result, isTrue);
      verifyNever(() => loginService.login(any()));
    });

    test('falls back to login when there is no stored refresh token',
        () async {
      when(() => tokenStore.readRefreshToken()).thenAnswer((_) async => null);
      when(() => loginService.login(any()))
          .thenAnswer((_) async => LoginModel(token: 'access-token'));
      when(() => tokenStore.readAccessToken())
          .thenAnswer((_) async => 'access-token');

      final result = await buildBootstrapper().ensureAuthenticated();

      expect(result, isTrue);
      verify(() => loginService.login(any())).called(1);
    });

    test('falls back to login when the refresh call throws', () async {
      when(() => tokenStore.readRefreshToken())
          .thenAnswer((_) async => 'stored-refresh-token');
      when(() => tokenRefreshService.call())
          .thenThrow(StateError('Invalid refresh response'));
      when(() => loginService.login(any()))
          .thenAnswer((_) async => LoginModel(token: 'access-token'));
      when(() => tokenStore.readAccessToken())
          .thenAnswer((_) async => 'access-token');

      final result = await buildBootstrapper().ensureAuthenticated();

      expect(result, isTrue);
      verify(() => loginService.login(any())).called(1);
    });
  });

  group('login retries', () {
    setUp(() {
      when(() => tokenStore.readRefreshToken()).thenAnswer((_) async => null);
    });

    test('retries with backoff and succeeds on the final attempt', () async {
      var callCount = 0;
      when(() => loginService.login(any())).thenAnswer((_) async {
        callCount++;
        if (callCount < 3) {
          throw Exception('login failed');
        }
        return LoginModel(token: 'access-token');
      });
      when(() => tokenStore.readAccessToken())
          .thenAnswer((_) async => 'access-token');

      final result = await buildBootstrapper().ensureAuthenticated();

      expect(result, isTrue);
      expect(callCount, 3);
      expect(
        recordedDelays,
        [const Duration(seconds: 2), const Duration(seconds: 4)],
      );
    });

    test('gives up after maxLoginAttempts and returns false', () async {
      when(() => loginService.login(any()))
          .thenThrow(Exception('login failed'));

      final result = await buildBootstrapper().ensureAuthenticated();

      expect(result, isFalse);
      verify(() => loginService.login(any())).called(3);
      expect(
        recordedDelays,
        [const Duration(seconds: 2), const Duration(seconds: 4)],
      );
    });

    test(
        'treats a login that reports success but persists no token as a '
        'failure', () async {
      when(() => loginService.login(any()))
          .thenAnswer((_) async => LoginModel(token: 'access-token'));
      when(() => tokenStore.readAccessToken()).thenAnswer((_) async => null);

      final result = await buildBootstrapper().ensureAuthenticated();

      expect(result, isFalse);
      verify(() => loginService.login(any())).called(3);
    });
  });
}
