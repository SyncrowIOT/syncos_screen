/// In-memory token cache used as a fallback when secure storage reads fail
/// or return empty (e.g. transient keychain issues on iOS).
abstract final class AuthSessionMemory {
  static String accessToken = '';
  static String refreshToken = '';

  static void setTokens({
    required String access,
    required String refresh,
  }) {
    accessToken = access;
    refreshToken = refresh;
  }

  static void clear() {
    accessToken = '';
    refreshToken = '';
  }
}
