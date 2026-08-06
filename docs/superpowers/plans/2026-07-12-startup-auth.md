# Startup Auth (Silent Refresh + Auto-Login) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Get the app to authenticate itself at startup (silent refresh, then fallback login with stored default credentials) so the already-working `TokenRefreshInterceptor`/websocket-refresh machinery has real tokens to work with, replacing the temporary hardcoded-JWT hack.

**Architecture:** A pure-Dart `SessionBootstrapper` (fully unit-testable, no Flutter/UI dependency) tries silent refresh via the existing shared `RemoteTokenRefreshService`, then falls back to `RemoteLoginService` (from the `auth` package) with retries/backoff. A thin `AuthGate` widget in `lib/app/` calls it once at startup and gates `PowerClampPage` behind loading/success/retry states.

**Tech Stack:** Flutter/Dart, `dio`, `flutter_secure_storage`, `flutter_dotenv`, the git-dependency packages `networking`/`socketio_client`/`auth` (pinned to `SyncrowIOT/frontend-microservices` commit `21541d1c1106f9b241ecb883b1cd45b186b734b8`), `mocktail`/`flutter_test` for tests (already dev dependencies).

## Global Constraints

- Do not modify or reimplement `TokenRefreshInterceptor`, `RemoteTokenRefreshService`, or `TokenRefreshSocketioClientServiceDecorator` — they already work; this plan only feeds them real tokens.
- `.env.staging` (tracked in git) must not gain any new keys; all new credentials go in a new gitignored `.env.local`.
- No plaintext password may ever be written to `flutter_secure_storage`/`AuthSessionMemory` — it is read from `.env.local` at call time only.
- No new login UI/screens — the only new UI is a single loading state and a single "Unable to sign in" + Retry button state.
- Follow existing lint config (`very_good_analysis`) — run `flutter analyze` clean before each commit.

---

## File Structure

| File | Responsibility |
|---|---|
| `.env.local` (new, gitignored, not committed by git) | Holds `DEFAULT_EMAIL`/`DEFAULT_PASSWORD` for POC auto-login |
| `.gitignore` (modify) | Ignore `.env.local` |
| `pubspec.yaml` (modify) | Add `.env.local` to `flutter.assets`; commit the already-uncommitted `auth` package dependency |
| `lib/services/auth/env_config.dart` (new) | Typed accessors for `DEFAULT_EMAIL`/`DEFAULT_PASSWORD` from dotenv |
| `lib/bootstrap.dart` (modify) | Load `.env.local` merged on top of `.env.staging` |
| `lib/services/api/http_interceptor.dart` (modify) | Remove hardcoded-JWT debug line |
| `lib/services/api/dio_client.dart` (modify) | Expose the shared `RemoteTokenRefreshService` instance via a static getter |
| `lib/services/auth/session_bootstrapper.dart` (new) | Pure-Dart silent-refresh → login-with-retries orchestration |
| `lib/app/auth_gate.dart` (new) | Startup gating widget: loading → child → retry-on-failure |
| `lib/app/app.dart` (modify) | Wrap `PowerClampPage` with `AuthGate` |
| `test/services/auth/env_config_test.dart` (new) | Verifies dotenv reads |
| `test/services/auth/session_bootstrapper_test.dart` (new) | Core TDD coverage for the orchestration logic |
| `test/app/auth_gate_test.dart` (new) | Widget test for loading/success/retry states |

---

### Task 1: `.env.local` + `EnvConfig` + git/pubspec wiring

**Files:**
- Create: `.env.local`
- Modify: `.gitignore`
- Modify: `pubspec.yaml`
- Create: `lib/services/auth/env_config.dart`
- Test: `test/services/auth/env_config_test.dart`

**Interfaces:**
- Produces: `EnvConfig.defaultEmail` (`String`), `EnvConfig.defaultPassword` (`String`) — read live from `dotenv.env`, used by Task 5.

- [ ] **Step 1: Create `.env.local` at repo root**

```
DEFAULT_EMAIL=superadmin@syncrow.com
DEFAULT_PASSWORD=changeme
```

(Replace with the real POC test-account credentials before running the app — this file is gitignored so it's safe to edit locally with real values.)

- [ ] **Step 2: Add `.env.local` to `.gitignore`**

Add near the top of `/Users/farisarmoush/Documents/Github/syncos-screen/.gitignore`:

```
# Local env (not committed) — POC auto-login credentials
.env.local
```

- [ ] **Step 3: Add `.env.local` to `pubspec.yaml` assets**

In `pubspec.yaml`, change:

```yaml
  assets:
    - assets/icons/
    - .env.staging
```

to:

```yaml
  assets:
    - assets/icons/
    - .env.staging
    - .env.local
```

- [ ] **Step 4: Write the failing test for `EnvConfig`**

Create `test/services/auth/env_config_test.dart`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncos_screen/services/auth/env_config.dart';

void main() {
  group('EnvConfig', () {
    setUp(() {
      dotenv.testLoad(
        fileInput: 'DEFAULT_EMAIL=test@example.com\nDEFAULT_PASSWORD=secret123',
      );
    });

    test('defaultEmail reads DEFAULT_EMAIL from dotenv', () {
      expect(EnvConfig.defaultEmail, 'test@example.com');
    });

    test('defaultPassword reads DEFAULT_PASSWORD from dotenv', () {
      expect(EnvConfig.defaultPassword, 'secret123');
    });

    test('falls back to empty string when keys are absent', () {
      dotenv.testLoad(fileInput: '');
      expect(EnvConfig.defaultEmail, '');
      expect(EnvConfig.defaultPassword, '');
    });
  });
}
```

- [ ] **Step 5: Run test to verify it fails**

Run: `flutter test test/services/auth/env_config_test.dart`
Expected: FAIL — `Error: Not found: 'package:syncos_screen/services/auth/env_config.dart'`

- [ ] **Step 6: Implement `EnvConfig`**

Create `lib/services/auth/env_config.dart`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads default POC login credentials from the gitignored `.env.local`
/// file (loaded in `bootstrap.dart` on top of `.env.staging`).
abstract final class EnvConfig {
  static String get defaultEmail => dotenv.env['DEFAULT_EMAIL'] ?? '';
  static String get defaultPassword => dotenv.env['DEFAULT_PASSWORD'] ?? '';
}
```

- [ ] **Step 7: Run test to verify it passes**

Run: `flutter test test/services/auth/env_config_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 8: Commit**

```bash
git add .env.local .gitignore pubspec.yaml lib/services/auth/env_config.dart test/services/auth/env_config_test.dart
git commit -m "feat: add .env.local for POC default login credentials"
```

Note: confirm `.env.local` is actually excluded — run `git status` after `git add .env.local` and verify git refuses/ignores it (since it's now in `.gitignore`, `git add .env.local` should say "The following paths are ignored..." — if so, drop it from the `git add`/commit; only the `.gitignore`, `pubspec.yaml`, and new Dart files should be committed).

---

### Task 2: Load `.env.local` in `bootstrap.dart`

**Files:**
- Modify: `lib/bootstrap.dart`

**Interfaces:**
- Consumes: nothing new (uses `flutter_dotenv`'s existing `dotenv.load`).
- Produces: `dotenv.env['DEFAULT_EMAIL']`/`['DEFAULT_PASSWORD']` populated at runtime for `EnvConfig` (Task 1) to read.

- [ ] **Step 1: Edit `lib/bootstrap.dart`**

Current (lines 8-17):

```dart
Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env.staging');
  RealtimeServiceFactory.registerLifecycleDisposal(widgetsBinding);

  runApp(await builder());
}
```

Change the `dotenv.load` line to also merge in `.env.local`, tolerating it being absent (e.g. a CI machine with no local secrets):

```dart
Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env.staging');
  try {
    await dotenv.load(fileName: '.env.local', mergeWith: dotenv.env);
  } on Object catch (error, stackTrace) {
    log('No .env.local found, skipping default credentials.',
        error: error, stackTrace: stackTrace);
  }
  RealtimeServiceFactory.registerLifecycleDisposal(widgetsBinding);

  runApp(await builder());
}
```

- [ ] **Step 2: Manually verify**

Run: `flutter run -t lib/main_staging.dart` (or your usual staging entrypoint), and add a temporary `print(EnvConfig.defaultEmail)` right after `bootstrap`'s dotenv calls (or check via a debugger) to confirm the value from `.env.local` loads. Remove the temporary print once confirmed.

There is no automated test for this step — `dotenv.load` reads real files from the `assets` bundle, which isn't meaningfully testable in a widget/unit test without extra fixtures; this is a one-line wiring change validated manually. Task 5's tests inject `EnvConfig`-independent fakes, so correctness of the bootstrapper logic doesn't depend on this step being tested here.

- [ ] **Step 3: Commit**

```bash
git add lib/bootstrap.dart
git commit -m "feat: load .env.local for default login credentials at startup"
```

---

### Task 3: Remove the hardcoded-JWT debug hack

**Files:**
- Modify: `lib/services/api/http_interceptor.dart:76-85`

**Interfaces:**
- Consumes: nothing new.
- Produces: `HTTPInterceptor._readAccessToken()` correctly falls through to `flutterSecureStorage`/`AuthSessionMemory` — this is what Task 5/6's real tokens will flow through.

- [ ] **Step 1: Edit `_readAccessToken`**

Current (lines 76-85):

```dart
  Future<String> _readAccessToken() async {
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'; // hardcoded debug JWT
    final storedToken = await flutterSecureStorage.read(
      key: 'access_token',
    );
    if (storedToken != null && storedToken.isNotEmpty) {
      return storedToken;
    }
    return AuthSessionMemory.accessToken;
  }
```

Change to:

```dart
  Future<String> _readAccessToken() async {
    final storedToken = await flutterSecureStorage.read(
      key: 'access_token',
    );
    if (storedToken != null && storedToken.isNotEmpty) {
      return storedToken;
    }
    return AuthSessionMemory.accessToken;
  }
```

- [ ] **Step 2: Run existing test suite to confirm nothing broke**

Run: `flutter test`
Expected: PASS (this file had no dedicated unit tests before; confirm no regressions elsewhere)

- [ ] **Step 3: Commit**

```bash
git add lib/services/api/http_interceptor.dart
git commit -m "fix: remove hardcoded debug JWT from HTTPInterceptor"
```

---

### Task 4: Expose the shared `RemoteTokenRefreshService` from `DioClient`

**Files:**
- Modify: `lib/services/api/dio_client.dart`
- Test: `test/services/api/dio_client_test.dart` (new)

**Interfaces:**
- Produces: `DioClient.tokenRefreshService` (`RemoteTokenRefreshService`) — a stable, memoized instance, same one used internally by `TokenRefreshInterceptor`. Consumed by `SessionBootstrapper` (Task 5).

- [ ] **Step 1: Write the failing test**

Create `test/services/api/dio_client_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:networking/networking.dart';
import 'package:syncos_screen/services/api/dio_client.dart';

void main() {
  test('tokenRefreshService returns the same instance on repeated access', () {
    // Force _dio construction first (mirrors real startup order).
    DioClient.instance;
    final first = DioClient.tokenRefreshService;
    final second = DioClient.tokenRefreshService;
    expect(identical(first, second), isTrue);
    expect(first, isA<RemoteTokenRefreshService>());
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/api/dio_client_test.dart`
Expected: FAIL — `The getter 'tokenRefreshService' isn't defined for the class 'DioClient'`

- [ ] **Step 3: Implement the exposed getter**

Current `dio_client.dart` (relevant section, lines 16-62):

```dart
final class DioClient {
  factory DioClient() => _instance;
  const DioClient._internal();

  static const DioClient _instance = DioClient._internal();

  static Dio? _dio;
  static String? _projectUuid;

  static final _tokenStore = SecureTokenStore();

  static Dio get instance {
    final existing = _dio;
    if (existing != null) {
      return existing;
    }
    return _makeDio();
  }

  static Dio _makeDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        receiveDataWhenStatusError: true,
        followRedirects: false,
        connectTimeout: const Duration(seconds: 45),
        sendTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
        validateStatus: (status) => true,
      ),
    );
    _dio = dio;
    dio.interceptors.addAll([
      DioNetworkLogger(),
      ProjectUuidInterceptor(
        tokenStore: _tokenStore,
        projectUuidProvider: () async => _projectUuid,
      ),
      HTTPInterceptor(),
      TokenRefreshInterceptor(
        dio: dio,
        tokenStore: _tokenStore,
        refreshPath: ApiEndpoints.refreshToken,
        onRefreshFailed: () => onTokenRefreshFailed?.call(),
        tokenRefreshService: RemoteTokenRefreshService(
          dio: dio,
          tokenStore: _tokenStore,
          refreshPath: ApiEndpoints.refreshToken,
        ),
      ),
    ]);
    return dio;
  }
}
```

Replace with:

```dart
final class DioClient {
  factory DioClient() => _instance;
  const DioClient._internal();

  static const DioClient _instance = DioClient._internal();

  static Dio? _dio;
  static String? _projectUuid;
  static RemoteTokenRefreshService? _tokenRefreshService;

  static final _tokenStore = SecureTokenStore();

  static Dio get instance {
    final existing = _dio;
    if (existing != null) {
      return existing;
    }
    return _makeDio();
  }

  /// The same [RemoteTokenRefreshService] instance used internally by the
  /// HTTP 401-retry interceptor, exposed so other startup flows (e.g.
  /// [SessionBootstrapper]) share its in-flight-refresh dedup lock.
  static RemoteTokenRefreshService get tokenRefreshService {
    instance; // ensures _makeDio() has run and set _tokenRefreshService
    return _tokenRefreshService!;
  }

  static Dio _makeDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        receiveDataWhenStatusError: true,
        followRedirects: false,
        connectTimeout: const Duration(seconds: 45),
        sendTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
        validateStatus: (status) => true,
      ),
    );
    _dio = dio;
    final tokenRefreshService = RemoteTokenRefreshService(
      dio: dio,
      tokenStore: _tokenStore,
      refreshPath: ApiEndpoints.refreshToken,
    );
    _tokenRefreshService = tokenRefreshService;
    dio.interceptors.addAll([
      DioNetworkLogger(),
      ProjectUuidInterceptor(
        tokenStore: _tokenStore,
        projectUuidProvider: () async => _projectUuid,
      ),
      HTTPInterceptor(),
      TokenRefreshInterceptor(
        dio: dio,
        tokenStore: _tokenStore,
        refreshPath: ApiEndpoints.refreshToken,
        onRefreshFailed: () => onTokenRefreshFailed?.call(),
        tokenRefreshService: tokenRefreshService,
      ),
    ]);
    return dio;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/api/dio_client_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/services/api/dio_client.dart test/services/api/dio_client_test.dart
git commit -m "feat: expose shared RemoteTokenRefreshService from DioClient"
```

---

### Task 5: `SessionBootstrapper` — silent refresh + login-with-retries

**Files:**
- Create: `lib/services/auth/session_bootstrapper.dart`
- Test: `test/services/auth/session_bootstrapper_test.dart`

**Interfaces:**
- Consumes: `TokenStore` (`readRefreshToken()`/`readAccessToken()`, from `package:networking/networking.dart`, implemented by `SecureTokenStore`), `RemoteTokenRefreshService` (`Future<String> call()`, from `package:networking/networking.dart`, via `DioClient.tokenRefreshService` from Task 4), `LoginService` (`Future<LoginModel> login(LoginParam param)`, from `package:auth/auth.dart`, implemented by `RemoteLoginService`).
- Produces: `SessionBootstrapper.ensureAuthenticated()` → `Future<bool>` (`true` = authenticated, real tokens now in the injected `TokenStore`; `false` = all attempts exhausted). Consumed by `AuthGate` (Task 6).

- [ ] **Step 1: Write failing tests for the silent-refresh path**

Create `test/services/auth/session_bootstrapper_test.dart`:

```dart
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
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/services/auth/session_bootstrapper_test.dart`
Expected: FAIL — `Error: Not found: 'package:syncos_screen/services/auth/session_bootstrapper.dart'`

- [ ] **Step 3: Implement `SessionBootstrapper` (silent refresh + single login attempt, no retries yet)**

Create `lib/services/auth/session_bootstrapper.dart`:

```dart
import 'package:auth/auth.dart';
import 'package:networking/networking.dart';
import 'package:syncos_screen/services/auth/env_config.dart';

/// Orchestrates getting a real session at app startup: try a silent
/// refresh using a stored refresh token first, then fall back to a full
/// login with default POC credentials (with retries/backoff).
///
/// Does not reimplement token refresh or persistence — both
/// [RemoteTokenRefreshService] and [LoginService] already write tokens into
/// the shared [TokenStore] as a side effect of succeeding.
class SessionBootstrapper {
  SessionBootstrapper({
    required TokenStore tokenStore,
    required RemoteTokenRefreshService tokenRefreshService,
    required LoginService loginService,
    LoginParam Function()? credentialsBuilder,
    Future<void> Function(Duration duration)? delay,
    this.maxLoginAttempts = 3,
    this.backoff = const [Duration(seconds: 2), Duration(seconds: 4)],
  })  : _tokenStore = tokenStore,
        _tokenRefreshService = tokenRefreshService,
        _loginService = loginService,
        _credentialsBuilder = credentialsBuilder ?? _defaultCredentials,
        _delay = delay ?? Future.delayed;

  final TokenStore _tokenStore;
  final RemoteTokenRefreshService _tokenRefreshService;
  final LoginService _loginService;
  final LoginParam Function() _credentialsBuilder;
  final Future<void> Function(Duration duration) _delay;

  /// Maximum number of full-login attempts (only used when silent refresh
  /// is unavailable/fails).
  final int maxLoginAttempts;

  /// Delay before each retry, indexed by attempt number (0-based). If there
  /// are more attempts than entries, the last entry is reused.
  final List<Duration> backoff;

  static LoginParam _defaultCredentials() => LoginParam(
        email: EnvConfig.defaultEmail,
        password: EnvConfig.defaultPassword,
        isMobilePlatform: true,
      );

  /// Returns true once a real access token is confirmed to be in the
  /// [TokenStore], false if every attempt (silent refresh + all login
  /// retries) failed.
  Future<bool> ensureAuthenticated() async {
    if (await _trySilentRefresh()) return true;
    return _loginWithRetries();
  }

  Future<bool> _trySilentRefresh() async {
    final refresh = await _tokenStore.readRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    try {
      await _tokenRefreshService.call();
      return true;
    } on Object {
      return false;
    }
  }

  Future<bool> _loginWithRetries() async {
    for (var attempt = 0; attempt < maxLoginAttempts; attempt++) {
      if (await _attemptLogin()) return true;
      final isLastAttempt = attempt == maxLoginAttempts - 1;
      if (!isLastAttempt) {
        final delayIndex = attempt < backoff.length
            ? attempt
            : backoff.length - 1;
        await _delay(backoff[delayIndex]);
      }
    }
    return false;
  }

  Future<bool> _attemptLogin() async {
    try {
      await _loginService.login(_credentialsBuilder());
    } on Object {
      return false;
    }
    // Don't trust LoginModel alone: the login response's token shape may
    // not match what HTTPInterceptor._extractTokens persists (a known
    // snake_case-vs-camelCase risk flagged during planning) — verify the
    // token store actually received a token.
    final access = await _tokenStore.readAccessToken();
    return access != null && access.isNotEmpty;
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/services/auth/session_bootstrapper_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: Write failing tests for the login-retry path**

Add to `test/services/auth/session_bootstrapper_test.dart` (inside `main()`, after the `silent refresh` group):

```dart
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
      expect(recordedDelays, [const Duration(seconds: 2), const Duration(seconds: 4)]);
    });

    test('gives up after maxLoginAttempts and returns false', () async {
      when(() => loginService.login(any()))
          .thenThrow(Exception('login failed'));

      final result = await buildBootstrapper().ensureAuthenticated();

      expect(result, isFalse);
      verify(() => loginService.login(any())).called(3);
      expect(recordedDelays, [const Duration(seconds: 2), const Duration(seconds: 4)]);
    });

    test('treats a login that reports success but persists no token as a failure',
        () async {
      when(() => loginService.login(any()))
          .thenAnswer((_) async => LoginModel(token: 'access-token'));
      when(() => tokenStore.readAccessToken()).thenAnswer((_) async => null);

      final result = await buildBootstrapper().ensureAuthenticated();

      expect(result, isFalse);
      verify(() => loginService.login(any())).called(3);
    });
  });
```

- [ ] **Step 6: Run tests to verify they fail or pass as expected**

Run: `flutter test test/services/auth/session_bootstrapper_test.dart`
Expected: All 6 tests PASS — the implementation from Step 3 already covers retries/backoff/verification, since it was written as a whole in one pass. If any fail, fix `SessionBootstrapper` until green (do not weaken the tests).

- [ ] **Step 7: Commit**

```bash
git add lib/services/auth/session_bootstrapper.dart test/services/auth/session_bootstrapper_test.dart
git commit -m "feat: add SessionBootstrapper for silent-refresh/login-retry startup auth"
```

---

### Task 6: `AuthGate` widget + wire into `app.dart`

**Files:**
- Create: `lib/app/auth_gate.dart`
- Modify: `lib/app/app.dart`
- Test: `test/app/auth_gate_test.dart`

**Interfaces:**
- Consumes: `SessionBootstrapper.ensureAuthenticated()` (`Future<bool>`, from Task 5).
- Produces: `AuthGate({required Future<bool> Function() ensureAuthenticated, required Widget child})` — injectable for tests; production usage wires it to a real `SessionBootstrapper`.

- [ ] **Step 1: Write the failing widget tests**

Create `test/app/auth_gate_test.dart`:

```dart
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/app/auth_gate_test.dart`
Expected: FAIL — `Error: Not found: 'package:syncos_screen/app/auth_gate.dart'`

- [ ] **Step 3: Implement `AuthGate`**

Create `lib/app/auth_gate.dart`:

```dart
import 'package:flutter/material.dart';

/// Gates [child] behind a startup authentication check. Shows a loading
/// indicator while [ensureAuthenticated] is pending, [child] once it
/// resolves true, or a minimal retry screen if it resolves false.
class AuthGate extends StatefulWidget {
  const AuthGate({
    required this.ensureAuthenticated,
    required this.child,
    super.key,
  });

  final Future<bool> Function() ensureAuthenticated;
  final Widget child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<bool> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.ensureAuthenticated();
  }

  void _retry() {
    setState(() {
      _future = widget.ensureAuthenticated();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == true) {
          return widget.child;
        }
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Unable to sign in'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _retry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/app/auth_gate_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: Wire `AuthGate` into `app.dart` with the real `SessionBootstrapper`**

Current `lib/app/app.dart` (relevant lines 1-44):

```dart
import 'package:design_system/design_system.dart';
import 'package:devices/devices.dart';
import 'package:flutter/material.dart';
import 'package:syncos_screen/features/devices/view/widgets/power_clamp/power_clamp_page.dart';
import 'package:syncos_screen/l10n/l10n.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final appTheme = AppTheme.light();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: appTheme.colors.text.brand,
        ),
        extensions: [appTheme],
        appBarTheme: AppBarTheme(
          backgroundColor: appTheme.colors.background.neutralPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const PowerClampPage(
        device: Device(
          uuid: '6b54c0d5-906e-4836-b63c-de96b515c640',
          name: 'Power Clamp',
          productType: ProductType.powerClamp,
          productUuid: '',
          productName: 'Power Clamp',
          subspaceName: '',
          subspaceUuid: '',
          online: true,
          icon: '',
          spaces: [],
        ),
      ),
    );
  }
}
```

Replace with:

```dart
import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:devices/devices.dart';
import 'package:flutter/material.dart';
import 'package:syncos_screen/app/auth_gate.dart';
import 'package:syncos_screen/features/devices/view/widgets/power_clamp/power_clamp_page.dart';
import 'package:syncos_screen/l10n/l10n.dart';
import 'package:syncos_screen/services/api/dio_client.dart';
import 'package:syncos_screen/services/api/networking_service_factory.dart';
import 'package:syncos_screen/services/api/secure_token_store.dart';
import 'package:syncos_screen/services/auth/session_bootstrapper.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final appTheme = AppTheme.light();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: appTheme.colors.text.brand,
        ),
        extensions: [appTheme],
        appBarTheme: AppBarTheme(
          backgroundColor: appTheme.colors.background.neutralPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AuthGate(
        ensureAuthenticated: SessionBootstrapper(
          tokenStore: SecureTokenStore(),
          tokenRefreshService: DioClient.tokenRefreshService,
          loginService: RemoteLoginService(
            networkingService: NetworkingServiceFactory.create(),
          ),
        ).ensureAuthenticated,
        child: const PowerClampPage(
          device: Device(
            uuid: '6b54c0d5-906e-4836-b63c-de96b515c640',
            name: 'Power Clamp',
            productType: ProductType.powerClamp,
            productUuid: '',
            productName: 'Power Clamp',
            subspaceName: '',
            subspaceUuid: '',
            online: true,
            icon: '',
            spaces: [],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Run the full test suite**

Run: `flutter test`
Expected: PASS (all tests, including pre-existing ones)

- [ ] **Step 7: Commit**

```bash
git add lib/app/auth_gate.dart lib/app/app.dart test/app/auth_gate_test.dart
git commit -m "feat: gate PowerClampPage behind startup auth via AuthGate"
```

---

### Task 7: Final cleanup and end-to-end verification

**Files:**
- Modify: `pubspec.yaml` / `pubspec.lock` (commit the already-uncommitted `auth` dependency addition, resolved)

**Interfaces:**
- Consumes: nothing new — this task only finalizes dependency state and runs full verification.

- [ ] **Step 1: Resolve dependencies**

Run: `flutter pub get`
Expected: Succeeds and updates `pubspec.lock` to include a resolved `auth` package entry (currently missing per `pubspec.lock`, since `pub get` hasn't been run since the dependency was added).

- [ ] **Step 2: Run static analysis**

Run: `flutter analyze`
Expected: No new errors/warnings introduced by this feature's files.

- [ ] **Step 3: Run the full test suite**

Run: `flutter test`
Expected: PASS

- [ ] **Step 4: Manual end-to-end check (see plan verification section below)**

Run: `flutter run -t lib/main_staging.dart` on a simulator/device with real `.env.local` credentials pointing at the staging backend.
Expected: App shows a brief loading state, then `PowerClampPage` with live data — confirming the whole chain (login → token persisted → `HTTPInterceptor`/`TokenRefreshInterceptor`/websocket decorator all pick it up) works against the real backend. **This is also when to verify the snake_case/camelCase token-shape risk flagged in Task 5** — if login "succeeds" per the network log but `PowerClampPage` never loads (stuck on loading, or bounces to the Retry screen), inspect the real `/authentication/user/login` response body's key casing and, if it's camelCase, extend `HTTPInterceptor._extractTokens` in `lib/services/api/http_interceptor.dart` to also accept `accessToken`/`refreshToken` alongside the existing snake_case keys.

- [ ] **Step 5: Commit the resolved dependency state**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: commit auth package dependency and resolved pubspec.lock"
```

---

## Verification (end-to-end, post-implementation)

1. Fresh install / cleared secure storage → launch → app silently logs in via `.env.local` credentials and lands on `PowerClampPage` with realtime data flowing.
2. Seed a valid `refresh_token` in secure storage, clear `access_token` → relaunch → confirm silent refresh is used (no `/authentication/user/login` network call) and the app still lands on `PowerClampPage`.
3. Set `.env.local` to wrong credentials → relaunch → confirm 3 silent login attempts (2s/4s apart) happen, then the Retry screen appears; fix credentials, tap Retry → succeeds.
4. Regression check: force a 401 mid-session (or wait out a short-lived token) and confirm `TokenRefreshInterceptor`/the websocket `TOKEN_EXPIRED` decorator still transparently refresh, unaffected by this change.
