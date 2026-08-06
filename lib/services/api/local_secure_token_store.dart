import 'package:networking/networking.dart';
import 'package:syncos_screen/utils/secure_storage.dart';

final class LocalSecureTokenStore implements TokenStore {
  String _memoryAccessToken = '';
  String _memoryRefreshToken = '';

  @override
  Future<String?> readAccessToken() async {
    final stored = await flutterSecureStorage.read(key: 'access_token');
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    return _memoryAccessToken;
  }

  @override
  Future<String?> readRefreshToken() async {
    final stored = await flutterSecureStorage.read(key: 'refresh_token');
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    return _memoryRefreshToken;
  }

  @override
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      flutterSecureStorage.write(key: 'access_token', value: accessToken),
      flutterSecureStorage.write(key: 'refresh_token', value: refreshToken),
    ]);
    _memoryAccessToken = accessToken;
    _memoryRefreshToken = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    await Future.wait([
      flutterSecureStorage.delete(key: 'access_token'),
      flutterSecureStorage.delete(key: 'refresh_token'),
    ]);
    _memoryAccessToken = '';
    _memoryRefreshToken = '';
  }
}
