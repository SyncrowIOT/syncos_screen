import 'package:networking/networking.dart';
import 'package:syncos_screen/services/api/auth_session_memory.dart';
import 'package:syncos_screen/utils/secure_storage.dart';

final class SecureTokenStore implements TokenStore {
  @override
  Future<String?> readAccessToken() =>
      flutterSecureStorage.read(key: 'access_token');

  @override
  Future<String?> readRefreshToken() =>
      flutterSecureStorage.read(key: 'refresh_token');

  @override
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      flutterSecureStorage.write(key: 'access_token', value: accessToken),
      flutterSecureStorage.write(key: 'refresh_token', value: refreshToken),
    ]);
    AuthSessionMemory.setTokens(
      access: accessToken,
      refresh: refreshToken,
    );
  }

  @override
  Future<void> clearTokens() async {
    await Future.wait([
      flutterSecureStorage.delete(key: 'access_token'),
      flutterSecureStorage.delete(key: 'refresh_token'),
    ]);
    AuthSessionMemory.clear();
  }
}
