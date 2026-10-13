import 'package:networking/networking.dart';
import 'package:syncos_screen/services/auth/token_refresh_service.dart';

final class RecoveringSocketTokenRefresher {
  RecoveringSocketTokenRefresher({
    required this._tokenRefreshService,
    required this._tokenStore,
    required this._awaitRecovery,
  });

  final TokenRefreshService _tokenRefreshService;
  final TokenStore _tokenStore;
  final Future<bool> Function() _awaitRecovery;

  Future<String> call() async {
    final staleToken = await _tokenStore.readAccessToken();
    try {
      return await _tokenRefreshService();
    } on Object {
      if (!await _awaitRecovery()) {
        throw StateError('Session recovery failed');
      }
      final freshToken = await _tokenStore.readAccessToken();
      if (freshToken == null || freshToken.isEmpty) rethrow;
      if (freshToken == staleToken) rethrow;
      return freshToken;
    }
  }
}
