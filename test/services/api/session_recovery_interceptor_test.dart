import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networking/networking.dart';
import 'package:syncos_screen/services/api/session_recovery_interceptor.dart';

void main() {
  test(
    'retries the original request with the new access token once '
    'recovery succeeds',
    () async {
      final tokenStore = _SpyTokenStore(accessToken: 'new-access');
      final adapter = _SequenceAdapter([
        _FixedResponse(status: 401),
        _FixedResponse(status: 200, body: 'chart-data'),
      ]);
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example'))
        ..httpClientAdapter = adapter;
      dio.interceptors.add(
        SessionRecoveryInterceptor(
          dio: dio,
          tokenStore: tokenStore,
          awaitRecovery: () async => true,
        ),
      );

      final response = await dio.get<String>('/power-clamp/chart');

      expect(response.data, 'chart-data');
      expect(adapter.sentHeaders.last['Authorization'], 'Bearer new-access');
    },
  );

  test(
    'forwards the original error when recovery fails',
    () async {
      final tokenStore = _SpyTokenStore(accessToken: null);
      final adapter = _SequenceAdapter([_FixedResponse(status: 401)]);
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example'))
        ..httpClientAdapter = adapter;
      dio.interceptors.add(
        SessionRecoveryInterceptor(
          dio: dio,
          tokenStore: tokenStore,
          awaitRecovery: () async => false,
        ),
      );

      await expectLater(
        dio.get<String>('/power-clamp/chart'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requestCount, 1);
    },
  );

  test(
    'ignores non-401 errors',
    () async {
      final tokenStore = _SpyTokenStore(accessToken: 'new-access');
      final adapter = _SequenceAdapter([_FixedResponse(status: 500)]);
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example'))
        ..httpClientAdapter = adapter;
      var awaitRecoveryCalls = 0;
      dio.interceptors.add(
        SessionRecoveryInterceptor(
          dio: dio,
          tokenStore: tokenStore,
          awaitRecovery: () async {
            awaitRecoveryCalls++;
            return true;
          },
        ),
      );

      await expectLater(
        dio.get<String>('/power-clamp/chart'),
        throwsA(isA<DioException>()),
      );
      expect(awaitRecoveryCalls, 0);
    },
  );

  test(
    'does not retry a request already marked as retried by this interceptor',
    () async {
      final tokenStore = _SpyTokenStore(accessToken: 'new-access');
      final adapter = _SequenceAdapter([_FixedResponse(status: 401)]);
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example'))
        ..httpClientAdapter = adapter;
      var awaitRecoveryCalls = 0;
      dio.interceptors.add(
        SessionRecoveryInterceptor(
          dio: dio,
          tokenStore: tokenStore,
          awaitRecovery: () async {
            awaitRecoveryCalls++;
            return true;
          },
        ),
      );

      await expectLater(
        dio.get<String>(
          '/power-clamp/chart',
          options: Options(
            extra: {skipSessionRecoveryExtraKey: true},
          ),
        ),
        throwsA(isA<DioException>()),
      );
      expect(awaitRecoveryCalls, 0);
    },
  );
}

class _SpyTokenStore implements TokenStore {
  _SpyTokenStore({required this._accessToken});

  String? _accessToken;

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
  }

  @override
  Future<void> clearTokens() async => _accessToken = null;
}

class _FixedResponse {
  _FixedResponse({int? status, this.body = ''}) : status = status ?? 200;

  final int status;
  final String body;
}

class _SequenceAdapter implements HttpClientAdapter {
  _SequenceAdapter(this._queue);

  final List<_FixedResponse> _queue;
  final List<Map<String, dynamic>> sentHeaders = [];
  int requestCount = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    sentHeaders.add(options.headers);
    requestCount++;
    final index = requestCount - 1;
    if (index >= _queue.length) {
      return ResponseBody.fromString('null', 500);
    }
    final item = _queue[index];
    return ResponseBody.fromString(
      item.body,
      item.status,
      headers: {
        Headers.contentTypeHeader: ['text/plain'],
      },
    );
  }
}
