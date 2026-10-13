import 'package:networking/networking.dart';

class TokenStoreSpy implements TokenStore {
  TokenStoreSpy({this.accessToken, this.refreshToken});

  String? accessToken;
  String? refreshToken;
  final List<({String accessToken, String refreshToken})> writtenTokens = [];
  int clearCount = 0;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    writtenTokens.add((accessToken: accessToken, refreshToken: refreshToken));
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    clearCount++;
    accessToken = null;
    refreshToken = null;
  }
}
