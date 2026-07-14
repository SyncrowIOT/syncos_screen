import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networking/networking.dart';
import 'package:syncos_screen/services/api/api_links_endpoints.dart';
import 'package:syncos_screen/services/api/http_interceptor.dart';

class SpyTokenStore implements TokenStore {
  String? accessToken;
  String? refreshToken;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
  }
}

void main() {
  test(
    '''
persists tokens from the login response shape the API returns''',
    () async {
      final tokenStore = SpyTokenStore();
      final interceptor = HTTPInterceptor(tokenStore: tokenStore);
      final requestOptions = RequestOptions(path: ApiEndpoints.login);
      final response = Response<Object?>(
        requestOptions: requestOptions,
        statusCode: 201,
        data: {
          'statusCode': 201,
          'data': {
            'accessToken': 'access-123',
            'refreshToken': 'refresh-456',
          },
          'message': 'User Logged in Successfully',
        },
      );

      final handler = ResponseInterceptorHandler();
      await interceptor.onResponse(response, handler);

      expect(tokenStore.accessToken, 'access-123');
      expect(tokenStore.refreshToken, 'refresh-456');
    },
  );
}
