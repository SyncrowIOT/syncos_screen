import 'package:dio/dio.dart';
import 'package:networking/networking.dart';

/// On HTTP **401** that survives `TokenRefreshInterceptor`'s own refresh
/// attempt (i.e. the refresh token itself was invalid, so the interceptor
/// gave up and forwarded the original error), waits for the app's
/// re-login recovery to settle and retries the original request with the
/// resulting access token.
///
/// Must be added to `Dio.interceptors` *before* `TokenRefreshInterceptor` --
/// Dio runs `onError` in reverse of interceptor-list order, so an earlier
/// position here means this interceptor only sees the error after
/// `TokenRefreshInterceptor` has already tried and failed to recover it.
class SessionRecoveryInterceptor extends InterceptorsWrapper {
  factory SessionRecoveryInterceptor({
    required Dio dio,
    required TokenStore tokenStore,
    required Future<bool> Function() awaitRecovery,
  }) {
    final logic = _SessionRecoveryLogic(
      dio: dio,
      tokenStore: tokenStore,
      awaitRecovery: awaitRecovery,
    );
    return SessionRecoveryInterceptor._(logic);
  }

  SessionRecoveryInterceptor._(_SessionRecoveryLogic logic)
    : super(onError: (err, handler) => logic.handleError(err, handler));
}

/// Add to [RequestOptions.extra] to skip this interceptor for a given
/// retried request, preventing it from retrying the same request twice.
const String skipSessionRecoveryExtraKey = 'skipSessionRecovery';

final class _SessionRecoveryLogic {
  _SessionRecoveryLogic({
    required this._dio,
    required this._tokenStore,
    required this._awaitRecovery,
  });

  final Dio _dio;
  final TokenStore _tokenStore;
  final Future<bool> Function() _awaitRecovery;

  Future<void> handleError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }
    if (err.requestOptions.extra[skipTokenRefreshExtraKey] == true ||
        err.requestOptions.extra[skipSessionRecoveryExtraKey] == true) {
      handler.next(err);
      return;
    }

    final recovered = await _awaitRecovery();
    if (!recovered) {
      handler.next(err);
      return;
    }

    final access = await _tokenStore.readAccessToken();
    if (access == null || access.isEmpty) {
      handler.next(err);
      return;
    }

    try {
      final headers = Map<String, dynamic>.from(err.requestOptions.headers);
      headers['Authorization'] = 'Bearer $access';
      final retryOptions = err.requestOptions.copyWith(
        headers: headers,
        extra: {
          ...err.requestOptions.extra,
          skipSessionRecoveryExtraKey: true,
        },
      );
      final response = await _dio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } on DioException catch (retryErr) {
      handler.next(retryErr);
    } on Object {
      handler.next(err);
    }
  }
}
