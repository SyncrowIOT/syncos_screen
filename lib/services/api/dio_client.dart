import 'package:dio/dio.dart';
import 'package:network_logger/network_logger.dart';
import 'package:networking/networking.dart';
import 'package:syncos_screen/services/api/api_links_endpoints.dart';
import 'package:syncos_screen/services/api/http_interceptor.dart';
import 'package:syncos_screen/services/api/secure_token_store.dart';

void Function()? onTokenRefreshFailed;

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
  /// HTTP 401-retry interceptor, exposed so other startup flows (e.g. a
  /// session bootstrapper) share its in-flight-refresh dedup lock.
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
