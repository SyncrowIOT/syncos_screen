import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:networking/networking.dart';
import 'package:syncos_screen/services/api/api_links_endpoints.dart';
import 'package:syncos_screen/services/api/http_interceptor.dart';
import 'package:syncos_screen/services/api/local_secure_token_store.dart';
import 'package:syncos_screen/services/api/session_recovery_interceptor.dart';

typedef _DioClientState = ({
  Dio dio,
  RemoteTokenRefreshService tokenRefreshService,
});

abstract final class DioClient {
  static _DioClientState? _state;
  static String? _projectUuid;
  static void Function()? _onSessionExpired;
  static Future<bool> Function()? _awaitSessionRecovery;

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

  /// Registers the function `SessionRecoveryInterceptor` awaits after a
  /// request's 401 survives `TokenRefreshInterceptor`'s own refresh
  /// attempt: it resolves once the session-expired recovery settles,
  /// reporting whether the session ended up authenticated. Typically wired
  /// to `AuthController.awaitRecovery`.
  static void configureSessionRecoveryWaiter(Future<bool> Function() waiter) {
    _awaitSessionRecovery = waiter;
  }

  /// Test-only escape hatch to invoke the configured session-recovery
  /// waiter without going through a real request/interceptor chain.
  @visibleForTesting
  static Future<bool> debugAwaitSessionRecovery() =>
      _awaitSessionRecovery?.call() ?? Future.value(false);

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
        // Backstop only: with validateStatus above, a refresh-endpoint
        // rejection never throws, so this fires only on transport failures,
        // which the interceptor itself filters out before calling back.
        onRefreshFailed: () => _onSessionExpired?.call(),
      ),
      // Dio runs onError in the SAME (FIFO) order interceptors were added,
      // not reversed -- this must come after TokenRefreshInterceptor so it
      // only sees a 401 once TokenRefreshInterceptor has already tried and
      // failed to refresh. Added earlier, it would see the raw 401 first
      // and retry with the still-stale token before any recovery started.
      SessionRecoveryInterceptor(
        dio: dio,
        tokenStore: _tokenStore,
        awaitRecovery: () =>
            _awaitSessionRecovery?.call() ?? Future.value(false),
      ),
    ]);
    return (dio: dio, tokenRefreshService: tokenRefreshService);
  }
}
