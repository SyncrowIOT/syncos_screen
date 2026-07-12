import 'package:auth/auth.dart';
import 'package:networking/networking.dart';
import 'package:syncos_screen/services/auth/env_config.dart';

/// Orchestrates getting a real session at app startup: try a silent
/// refresh using a stored refresh token first, then fall back to a full
/// login with default POC credentials (with retries/backoff).
///
/// Does not reimplement token refresh or persistence — both
/// [RemoteTokenRefreshService] and [LoginService] already write tokens into
/// the shared [TokenStore] as a side effect of succeeding.
class SessionBootstrapper {
  SessionBootstrapper({
    required TokenStore tokenStore,
    required RemoteTokenRefreshService tokenRefreshService,
    required LoginService loginService,
    LoginParam Function()? credentialsBuilder,
    Future<void> Function(Duration duration)? delay,
    this.maxLoginAttempts = 3,
    this.backoff = const [Duration(seconds: 2), Duration(seconds: 4)],
  })  : // The public parameter name is part of this class's required API
        // and can't carry a leading underscore, so it can't be an
        // initializing formal for the private field it populates.
        // ignore: prefer_initializing_formals
        _tokenStore = tokenStore,
        // The public parameter name is part of this class's required API
        // and can't carry a leading underscore, so it can't be an
        // initializing formal for the private field it populates.
        // ignore: prefer_initializing_formals
        _tokenRefreshService = tokenRefreshService,
        // The public parameter name is part of this class's required API
        // and can't carry a leading underscore, so it can't be an
        // initializing formal for the private field it populates.
        // ignore: prefer_initializing_formals
        _loginService = loginService,
        _credentialsBuilder = credentialsBuilder ?? _defaultCredentials,
        _delay = delay ?? Future.delayed;

  final TokenStore _tokenStore;
  final RemoteTokenRefreshService _tokenRefreshService;
  final LoginService _loginService;
  final LoginParam Function() _credentialsBuilder;
  final Future<void> Function(Duration duration) _delay;

  /// Maximum number of full-login attempts (only used when silent refresh
  /// is unavailable/fails).
  final int maxLoginAttempts;

  /// Delay before each retry, indexed by attempt number (0-based). If there
  /// are more attempts than entries, the last entry is reused.
  final List<Duration> backoff;

  static LoginParam _defaultCredentials() => LoginParam(
        email: EnvConfig.defaultEmail,
        password: EnvConfig.defaultPassword,
        isMobilePlatform: true,
      );

  /// Returns true once a real access token is confirmed to be in the
  /// [TokenStore], false if every attempt (silent refresh + all login
  /// retries) failed.
  Future<bool> ensureAuthenticated() async {
    if (await _trySilentRefresh()) return true;
    return _loginWithRetries();
  }

  Future<bool> _trySilentRefresh() async {
    final refresh = await _tokenStore.readRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    try {
      await _tokenRefreshService.call();
      return true;
    } on Object {
      return false;
    }
  }

  Future<bool> _loginWithRetries() async {
    for (var attempt = 0; attempt < maxLoginAttempts; attempt++) {
      if (await _attemptLogin()) return true;
      final isLastAttempt = attempt == maxLoginAttempts - 1;
      if (!isLastAttempt) {
        final delayIndex =
            attempt < backoff.length ? attempt : backoff.length - 1;
        await _delay(backoff[delayIndex]);
      }
    }
    return false;
  }

  Future<bool> _attemptLogin() async {
    try {
      await _loginService.login(_credentialsBuilder());
    } on Object {
      return false;
    }
    // Don't trust LoginModel alone: the login response's token shape may
    // not match what HTTPInterceptor._extractTokens persists (a known
    // snake_case-vs-camelCase risk flagged during planning) — verify the
    // token store actually received a token.
    final access = await _tokenStore.readAccessToken();
    return access != null && access.isNotEmpty;
  }
}
