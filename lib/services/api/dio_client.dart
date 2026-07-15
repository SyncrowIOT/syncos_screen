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
