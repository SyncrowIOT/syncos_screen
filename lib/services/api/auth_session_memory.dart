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
