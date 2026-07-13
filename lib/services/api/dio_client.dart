import 'package:dio/dio.dart';
import 'package:network_logger/network_logger.dart';
import 'package:networking/networking.dart';
import 'package:syncos_screen/services/api/api_links_endpoints.dart';
import 'package:syncos_screen/services/api/http_interceptor.dart';
import 'package:syncos_screen/services/api/secure_token_store.dart';

abstract final class DioClient {
  static Dio? _dio;
  static String? _projectUuid;
  static late RemoteTokenRefreshService? _tokenRefreshService;

  static final _tokenStore = SecureTokenStore();

  static Dio get instance {
    final existing = _dio;
    if (existing != null) {
      return existing;
    }
    return _makeDio();
  }

  static RemoteTokenRefreshService get tokenRefreshService {
    instance;
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
      HTTPInterceptor(tokenStore: _tokenStore),
      TokenRefreshInterceptor(
        dio: dio,
        tokenStore: _tokenStore,
        refreshPath: ApiEndpoints.refreshToken,
        tokenRefreshService: tokenRefreshService,
      ),
    ]);
    return dio;
  }
}
