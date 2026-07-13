import 'package:auth/auth.dart';
import 'package:networking/networking.dart';
import 'package:syncos_screen/services/auth/env_config.dart';

class SessionBootstrapper {
  SessionBootstrapper({
    required this._tokenStore,
    required this._tokenRefreshService,
    required this._loginService,
    LoginParam Function()? credentialsBuilder,
    Future<void> Function(Duration duration)? delay,
    this.maxLoginAttempts = 3,
    this.backoff = const [Duration(seconds: 2), Duration(seconds: 4)],
  }) : _credentialsBuilder = credentialsBuilder ?? _defaultCredentials,
       _delay = delay ?? Future.delayed;

  final TokenStore _tokenStore;
  final RemoteTokenRefreshService _tokenRefreshService;
  final LoginService _loginService;
  final LoginParam Function() _credentialsBuilder;
  final Future<void> Function(Duration duration) _delay;

  final int maxLoginAttempts;

  final List<Duration> backoff;

  static LoginParam _defaultCredentials() => LoginParam(
    email: EnvConfig.defaultEmail,
    password: EnvConfig.defaultPassword,
    isMobilePlatform: true,
  );

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
        final delayIndex = attempt < backoff.length ? attempt : backoff.length - 1;
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
    final access = await _tokenStore.readAccessToken();
    return access != null && access.isNotEmpty;
  }
}
