import 'package:dio/dio.dart';
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

  static final _tokenStore = LocalSecureTokenStore();

  static Dio get instance => _ensureInitialized().dio;

  static RemoteTokenRefreshService get tokenRefreshService =>
      _ensureInitialized().tokenRefreshService;

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
      ),
    ]);
    return (dio: dio, tokenRefreshService: tokenRefreshService);
  }
}
