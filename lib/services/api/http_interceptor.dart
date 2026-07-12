import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:syncos_screen/services/api/api_links_endpoints.dart';
import 'package:syncos_screen/services/api/auth_session_memory.dart';
import 'package:syncos_screen/utils/keychain_retry_helper.dart';
import 'package:syncos_screen/utils/secure_storage.dart';

class HTTPInterceptor extends InterceptorsWrapper {
  List<String> headerExclusionList = [];

  List<String> headerExclusionListOfAddedParameters = [
    ApiEndpoints.login,
    ApiEndpoints.refreshToken,
  ];
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
    final token = await _readAccessToken();
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

    for (final urlConstant in headerExclusionListOfAddedParameters) {
      if (path.contains(urlConstant)) {
        shouldAddHeader = false;
      }
    }
    return shouldAddHeader;
  }

  Future<String> _readAccessToken() async {
    final storedToken = await flutterSecureStorage.read(
      key: 'access_token',
    );
    if (storedToken != null && storedToken.isNotEmpty) {
      return storedToken;
    }
    return AuthSessionMemory.accessToken;
  }

  Future<void> _persistLoginTokens(Response<Object?> response) async {
    if (!response.requestOptions.path.contains(ApiEndpoints.login)) {
      return;
    }

    final tokens = _extractTokens(response.data);
    if (tokens == null) {
      return;
    }

    await KeychainRetryHelper.retryKeychainWrites({
      'access_token': tokens.$1,
      'refresh_token': tokens.$2,
    });
    AuthSessionMemory.setTokens(
      access: tokens.$1,
      refresh: tokens.$2,
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
    final tokenData = rawData is Map ? Map<String, dynamic>.from(rawData) : root;
    final accessToken = tokenData['access_token'];
    final refreshToken = tokenData['refresh_token'];

    if (accessToken is! String ||
        refreshToken is! String ||
        accessToken.isEmpty ||
        refreshToken.isEmpty) {
      return null;
    }

    return (accessToken, refreshToken);
  }
}
