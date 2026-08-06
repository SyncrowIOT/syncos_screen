# Re-login on Refresh-Token Failure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When a mid-session refresh-token API call fails, the app automatically logs back in with its default credentials and reflects the recovery in the existing splash/auth-error router UI, instead of silently leaving the session broken until restart.

**Architecture:** `RemoteTokenRefreshService` and `TokenRefreshInterceptor` (shared `networking` package) already accept an `onRefreshFailed` callback that fires when a refresh is unrecoverable. `DioClient` will wire both to a settable indirection callback, and `app.dart` will point that callback at the existing `AuthController.retry()`, which re-runs `SessionBootstrapper.ensureAuthenticated()` (silent refresh → login-with-retries with default credentials) — the same flow already used at startup. `AuthController` gets a reentrancy guard so overlapping failures can't stack duplicate login cycles.

**Tech Stack:** Flutter/Dart, Dio, `flutter_bloc`-adjacent app (no Bloc here — plain `ChangeNotifier`), `go_router`, `flutter_test`.

## Global Constraints

- No changes to the `frontend-microservices` package (separate repo/dependency) — only `syncos-screen` files change.
- The original request that triggered the 401 is not retried automatically after recovery; only the session itself is recovered.
- Reuse `SessionBootstrapper`'s existing default-credentials and retry/backoff logic unchanged — do not duplicate or reimplement it.

---

## Design spec

See `docs/superpowers/specs/2026-07-15-relogin-on-refresh-failure-design.md` for full background and rationale.

## File Structure

- Modify: `lib/app/router/auth_controller.dart` — add in-flight reentrancy guard around `_run()`.
- Modify: `test/app/router/auth_controller_test.dart` — add a test for the reentrancy guard.
- Modify: `lib/services/api/dio_client.dart` — add a settable session-expired handler slot, wire it into both `RemoteTokenRefreshService` and `TokenRefreshInterceptor` construction, and add a `@visibleForTesting` hook to trigger it directly in tests.
- Modify: `test/services/api/dio_client_test.dart` — add a test for the new handler wiring.
- Modify: `lib/app/app.dart` — after building `AuthController`, wire `DioClient.configureSessionExpiredHandler(_authController.retry)`.

---

### Task 1: Add a reentrancy guard to `AuthController`

**Files:**
- Modify: `lib/app/router/auth_controller.dart`
- Test: `test/app/router/auth_controller_test.dart`

**Interfaces:**
- Consumes: nothing new.
- Produces: `AuthController.retry()` (unchanged public signature, `void Function()`) becomes safe to call concurrently — a second call while a run is already in flight joins the existing run instead of starting a new `_ensureAuthenticated()` invocation. Later tasks rely on `retry` still being assignable to a `void Function()` handler.

- [ ] **Step 1: Write the failing test**

Add to `test/app/router/auth_controller_test.dart` (inside the existing `main()`, after the last test):

```dart
  test(
    'retry ignores calls while a run is already in flight',
    () async {
      var callCount = 0;
      final sut = _makeSut(
        ensureAuthenticated: () async {
          callCount++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return true;
        },
      );

      sut.retry();
      sut.retry();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(callCount, 1);
      expect(sut.status, AuthStatus.authenticated);
    },
  );
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/app/router/auth_controller_test.dart`
Expected: The new test FAILS with `callCount` equal to `3` (one from the constructor's initial run, one from each `retry()` call), not `1`.

- [ ] **Step 3: Write minimal implementation**

Replace the full contents of `lib/app/router/auth_controller.dart` with:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';

enum AuthStatus { loading, authenticated, error }

class AuthController extends ChangeNotifier {
  AuthController({required this._ensureAuthenticated}) {
    unawaited(_run());
  }

  final Future<bool> Function() _ensureAuthenticated;

  AuthStatus status = AuthStatus.loading;

  Future<void>? _inFlight;

  Future<void> _run() {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    final future = _runOnce();
    _inFlight = future;
    return future;
  }

  Future<void> _runOnce() async {
    status = AuthStatus.loading;
    notifyListeners();
    try {
      final ok = await _ensureAuthenticated();
      status = ok ? AuthStatus.authenticated : AuthStatus.error;
    } on Object {
      status = AuthStatus.error;
    }
    _inFlight = null;
    notifyListeners();
  }

  void retry() => unawaited(_run());
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/app/router/auth_controller_test.dart`
Expected: All tests in the file PASS, including the new one with `callCount` equal to `1`.

- [ ] **Step 5: Commit**

```bash
git add lib/app/router/auth_controller.dart test/app/router/auth_controller_test.dart
git commit -m "fix: guard AuthController against overlapping re-auth runs"
```

---

### Task 2: Wire a session-expired handler slot into `DioClient`

**Files:**
- Modify: `lib/services/api/dio_client.dart`
- Test: `test/services/api/dio_client_test.dart`

**Interfaces:**
- Consumes: `RemoteTokenRefreshService({..., void Function()? onRefreshFailed})` and `TokenRefreshInterceptor({..., void Function()? onRefreshFailed})` — both already exist in the `networking` package and already accept this parameter.
- Produces: `static void DioClient.configureSessionExpiredHandler(void Function() handler)` — later tasks (Task 3) call this from `app.dart`. Also `@visibleForTesting static void DioClient.debugInvokeSessionExpiredHandler()`, used only by this task's own test.

- [ ] **Step 1: Write the failing test**

Add to `test/services/api/dio_client_test.dart` (inside the existing `main()`, after the existing test):

```dart
  test(
    'configureSessionExpiredHandler wires a handler debugInvokeSessionExpiredHandler can trigger',
    () {
      var callCount = 0;
      DioClient.configureSessionExpiredHandler(() => callCount++);

      DioClient.debugInvokeSessionExpiredHandler();

      expect(callCount, 1);
    },
  );
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/api/dio_client_test.dart`
Expected: FAIL with a compile error — `configureSessionExpiredHandler` and `debugInvokeSessionExpiredHandler` are not defined on `DioClient`.

- [ ] **Step 3: Write minimal implementation**

Replace the full contents of `lib/services/api/dio_client.dart` with:

```dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:networking/networking.dart';
import 'package:syncos_screen/services/api/api_links_endpoints.dart';
import 'package:syncos_screen/services/api/http_interceptor.dart';
import 'package:syncos_screen/services/api/local_secure_token_store.dart';

typedef _DioClientState = ({
  Dio dio,
  RemoteTokenRefreshService tokenRefreshService,
});

abstract final class DioClient {
  static _DioClientState? _state;
  static String? _projectUuid;
  static void Function()? _onSessionExpired;

  static final _tokenStore = LocalSecureTokenStore();

  static Dio get instance => _ensureInitialized().dio;

  static RemoteTokenRefreshService get tokenRefreshService =>
      _ensureInitialized().tokenRefreshService;

  /// Registers the handler to run when a mid-session token refresh fails in
  /// an unrecoverable way (missing/invalid refresh token, or a deterministic
  /// rejection from the refresh endpoint). Typically wired to
  /// `AuthController.retry` so the app re-authenticates with its default
  /// credentials, reusing the same flow as app startup.
  static void configureSessionExpiredHandler(void Function() handler) {
    _onSessionExpired = handler;
  }

  /// Test-only escape hatch to invoke the configured session-expired
  /// handler without going through a real refresh-token failure.
  @visibleForTesting
  static void debugInvokeSessionExpiredHandler() => _onSessionExpired?.call();

  static _DioClientState _ensureInitialized() {
    return _state ??= _makeDio();
  }

  static _DioClientState _makeDio() {
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
    final tokenRefreshService = RemoteTokenRefreshService(
      dio: dio,
      tokenStore: _tokenStore,
      refreshPath: ApiEndpoints.refreshToken,
      onRefreshFailed: () => _onSessionExpired?.call(),
    );
    dio.interceptors.addAll([
      ProjectUuidInterceptor(
        tokenStore: _tokenStore,
        projectUuidProvider: () async => _projectUuid,
      ),
      HTTPInterceptor(tokenStore: _tokenStore),
      TokenRefreshInterceptor(
        dio: dio,
        tokenStore: _tokenStore,
        refreshPath: ApiEndpoints.refreshToken,
        tokenRefreshService: tokenRefreshService,
        onRefreshFailed: () => _onSessionExpired?.call(),
      ),
    ]);
    return (dio: dio, tokenRefreshService: tokenRefreshService);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/api/dio_client_test.dart`
Expected: All tests in the file PASS, including the new one.

- [ ] **Step 5: Commit**

```bash
git add lib/services/api/dio_client.dart test/services/api/dio_client_test.dart
git commit -m "feat: let DioClient dispatch a session-expired handler on refresh failure"
```

---

### Task 3: Wire `AuthController.retry` as the session-expired handler in `app.dart`

**Files:**
- Modify: `lib/app/app.dart`

**Interfaces:**
- Consumes: `DioClient.configureSessionExpiredHandler(void Function() handler)` (Task 2), `AuthController.retry` (Task 1, unchanged public signature).
- Produces: nothing consumed by later tasks — this is the final integration point.

- [ ] **Step 1: Wire the handler**

In `lib/app/app.dart`, inside `_AppState.initState()`, after the `_authController = AuthController(...)` assignment and before `_router = buildAppRouter(...)`, add:

```dart
    DioClient.configureSessionExpiredHandler(_authController.retry);
```

So `initState()` reads:

```dart
  @override
  void initState() {
    super.initState();
    _authController = AuthController(
      ensureAuthenticated: SessionBootstrapper(
        tokenStore: LocalSecureTokenStore(),
        tokenRefreshService: RemoteTokenRefreshServiceAdapter(
          tokenRefreshService: DioClient.tokenRefreshService,
        ),
        loginService: RemoteLoginService(
          networkingService: NetworkingServiceFactory.create(),
        ),
      ).ensureAuthenticated,
    );
    DioClient.configureSessionExpiredHandler(_authController.retry);
    _router = buildAppRouter(
      authController: _authController,
      initialDevice: _initialDevice,
    );
  }
```

- [ ] **Step 2: Static analysis check**

Run: `flutter analyze lib/app/app.dart`
Expected: No issues found.

- [ ] **Step 3: Run the full test suite**

Run: `flutter test`
Expected: All existing tests PASS (this change has no dedicated automated test — `App` isn't under widget-test coverage today, and standing one up is out of scope for this fix).

- [ ] **Step 4: Manual verification**

With the app running against a real or staging backend:
1. Let the app authenticate normally (splash → home).
2. Force a mid-session refresh failure — e.g. use the device's secure storage debug tools to overwrite the stored refresh token with an invalid value, then trigger any API call (or wait for the interceptor to hit a natural 401).
3. Confirm the app transitions to the splash screen and back to the home screen automatically (or to `/auth-error` if login also fails), without restarting the app.

- [ ] **Step 5: Commit**

```bash
git add lib/app/app.dart
git commit -m "feat: re-authenticate automatically when a mid-session refresh fails"
```
