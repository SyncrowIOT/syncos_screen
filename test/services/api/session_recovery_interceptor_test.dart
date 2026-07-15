import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networking/networking.dart';
import 'package:syncos_screen/services/api/session_recovery_interceptor.dart';

void main() {
  test(
    'placed after TokenRefreshInterceptor, only retries once the '
    'refresh-then-relogin recovery actually finishes -- not with the '
    'stale token that was live when the request first failed',
    () async {
      final tokenStore = _OrderingTokenStore(
        access: 'old-access',
        refresh: 'old-refresh',
      );
      final recovery = Completer<bool>();

      final adapter = _OrderingAdapter(
        refreshPath: '/authentication/refresh-token',
        onRefreshRequested: () {
          // Simulates the app's real recovery: onRefreshFailed kicks off
          // AuthController.retrySilently -> SessionBootstrapper login,
          // asynchronously, writing fresh tokens only once it succeeds.
          Future<void>.delayed(const Duration(milliseconds: 10), () async {
            await tokenStore.writeTokens(
              accessToken: 'new-access',
              refreshToken: 'new-refresh',
            );
            recovery.complete(true);
          });
        },
      );

      final dio = Dio(BaseOptions(baseUrl: 'https://api.example'))
        ..httpClientAdapter = adapter;

      final refreshService = RemoteTokenRefreshService(
        dio: dio,
        tokenStore: tokenStore,
        refreshPath: '/authentication/refresh-token',
      );

      dio.interceptors.addAll([
        TokenRefreshInterceptor(
          dio: dio,
          tokenStore: tokenStore,
          refreshPath: '/authentication/refresh-token',
          tokenRefreshService: refreshService,
        ),
        SessionRecoveryInterceptor(
          dio: dio,
          tokenStore: tokenStore,
          awaitRecovery: () => recovery.future,
        ),
      ]);

      final response = await dio.get<String>('/power-clamp/chart');

      expect(response.data, 'chart-data');
      expect(adapter.paths, [
        '/power-clamp/chart',
        '/authentication/refresh-token',
        '/power-clamp/chart',
      ]);
      expect(
        adapter.sentHeaders.last[HttpHeaders.authorizationHeader],
        'Bearer new-access',
      );
    },
  );

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
      expect(
        adapter.sentHeaders.last[HttpHeaders.authorizationHeader],
        'Bearer new-access',
      );
    },
  );

  test(
    'replaces a stale lowercase authorization header rather than adding '
    'a second, differently-cased one',
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

      await dio.get<String>(
        '/power-clamp/chart',
        options: Options(
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer old-access',
          },
        ),
      );

      final retriedHeaders = adapter.sentHeaders.last;
      final authKeys = retriedHeaders.keys.where(
        (key) => key.toLowerCase() == HttpHeaders.authorizationHeader,
      );
      expect(authKeys, hasLength(1));
      expect(
        retriedHeaders[authKeys.first],
        'Bearer new-access',
      );
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

class _OrderingTokenStore implements TokenStore {
  _OrderingTokenStore({required this._access, required this._refresh});

  String? _access;
  String? _refresh;

  @override
  Future<String?> readAccessToken() async => _access;

  @override
  Future<String?> readRefreshToken() async => _refresh;

  @override
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _access = accessToken;
    _refresh = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    _access = null;
    _refresh = null;
  }
}

/// Serves 401 for [refreshPath]'s target path (the original request) until
/// the refresh call has been made once, then a rejected refresh body, then
/// a successful response on the next hit of the original path.
class _OrderingAdapter implements HttpClientAdapter {
  _OrderingAdapter({required this.refreshPath, required this.onRefreshRequested});

  final String refreshPath;
  final void Function() onRefreshRequested;
  final List<String> paths = [];
  final List<Map<String, dynamic>> sentHeaders = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.uri.path);
    sentHeaders.add(options.headers);

    if (options.uri.path == refreshPath) {
      onRefreshRequested();
      return ResponseBody.fromString(
        '{"success":false}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    final isRetry = paths.where((p) => p == options.uri.path).length > 1;
    if (isRetry) {
      return ResponseBody.fromString(
        'chart-data',
        200,
        headers: {
          Headers.contentTypeHeader: ['text/plain'],
        },
      );
    }
    return ResponseBody.fromString('null', 401);
  }
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
