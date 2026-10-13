import 'dart:async';

import 'package:networking/networking.dart';

final class NotifyingTokenStoreDecorator implements TokenStore {
  NotifyingTokenStoreDecorator({required this._tokenStore});

  final TokenStore _tokenStore;
  final _accessTokenWrites = StreamController<String>.broadcast(sync: true);
  String _currentAccessToken = '';

  String get currentAccessToken => _currentAccessToken;

  Stream<String> get accessTokenWrites => _accessTokenWrites.stream;

  @override
  Future<String?> readAccessToken() => _tokenStore.readAccessToken();

  @override
  Future<String?> readRefreshToken() => _tokenStore.readRefreshToken();

  @override
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _tokenStore.writeTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    _currentAccessToken = accessToken;
    _accessTokenWrites.add(accessToken);
  }

  @override
  Future<void> clearTokens() async {
    await _tokenStore.clearTokens();
    _currentAccessToken = '';
  }
}
