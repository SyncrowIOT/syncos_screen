import 'package:networking/networking.dart';
import 'package:syncos_screen/services/api/auth_session_memory.dart';
import 'package:syncos_screen/utils/keychain_retry_helper.dart';
import 'package:syncos_screen/utils/secure_storage.dart';

final class SecureTokenStore implements TokenStore {
  @override
  Future<String?> readAccessToken() =>
      KeychainRetryHelper.retryKeychainOperation(
    () => flutterSecureStorage.read(key: 'access_token'),
  );

  @override
  Future<String?> readRefreshToken() =>
      KeychainRetryHelper.retryKeychainOperation(
    () => flutterSecureStorage.read(key: 'refresh_token'),
  );

  @override
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await KeychainRetryHelper.retryKeychainWrites({
      'access_token': accessToken,
      'refresh_token': refreshToken,
    });
    AuthSessionMemory.setTokens(
      access: accessToken,
      refresh: refreshToken,
    );
  }

  @override
  Future<void> clearTokens() async {
    await KeychainRetryHelper.retryKeychainDeletes([
      'access_token',
      'refresh_token',
    ]);
    AuthSessionMemory.clear();
  }
}
