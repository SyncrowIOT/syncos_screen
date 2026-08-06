import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:networking/networking.dart';
import 'package:syncos_screen/services/api/api_links_endpoints.dart';

class HTTPInterceptor extends InterceptorsWrapper {
  HTTPInterceptor({required this._tokenStore});

  final TokenStore _tokenStore;

  static const _nonAuthenticatedEndpoints = <String>{
    ApiEndpoints.login,
    ApiEndpoints.refreshToken,
  };
  @override
  Future<void> onResponse(
    Response<Object?> response,
    ResponseInterceptorHandler handler,
  ) async {
    if (await validateResponse(response)) {
      await _persistLoginTokens(response);
      super.onResponse(response, handler);
    } else {
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        ),
        true,
      );
    }
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStore.readAccessToken() ?? '';
    if (checkHeaderExclusionListOfAddedParameters(options.path)) {
      options.headers.putIfAbsent(
        HttpHeaders.authorizationHeader,
        () => 'Bearer $token',
      );
    }

    super.onRequest(options, handler);
  }

  Future<bool> validateResponse(Response<Object?> response) async {
    if (response.statusCode != null) {
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  bool checkHeaderExclusionListOfAddedParameters(String path) {
    var shouldAddHeader = true;

    for (final urlConstant in _nonAuthenticatedEndpoints) {
      if (path.contains(urlConstant)) {
        shouldAddHeader = false;
      }
    }
    return shouldAddHeader;
  }

  Future<void> _persistLoginTokens(Response<Object?> response) async {
    if (!response.requestOptions.path.contains(ApiEndpoints.login)) {
      return;
    }

    final tokens = _extractTokens(response.data);
    if (tokens == null) {
      return;
    }

    await _tokenStore.writeTokens(
      accessToken: tokens.$1,
      refreshToken: tokens.$2,
    );
  }

  (String, String)? _extractTokens(Object? data) {
    var value = data;
    if (value is String) {
      try {
        value = jsonDecode(value);
      } on Object {
        return null;
      }
    }

    if (value is! Map) {
      return null;
    }

    final root = Map<String, dynamic>.from(value);
    final rawData = root['data'];
    final tokenData = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : root;
    final accessToken = tokenData['accessToken'];
    final refreshToken = tokenData['refreshToken'];

    if (accessToken is! String ||
        refreshToken is! String ||
        accessToken.isEmpty ||
        refreshToken.isEmpty) {
      return null;
    }

    return (accessToken, refreshToken);
  }
}
