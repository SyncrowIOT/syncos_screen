import 'dart:async';

import 'package:flutter/foundation.dart';

enum AuthStatus { loading, authenticated, error }

class AuthController extends ChangeNotifier {
  AuthController({required this._ensureAuthenticated}) {
    unawaited(_run(silent: false));
  }

  final Future<bool> Function() _ensureAuthenticated;

  AuthStatus status = AuthStatus.loading;

  Future<void>? _inFlight;

  Future<void> _run({required bool silent}) {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    final future = _runOnce(silent: silent);
    _inFlight = future;
    return future;
  }

  Future<void> _runOnce({required bool silent}) async {
    if (!silent) {
      status = AuthStatus.loading;
      notifyListeners();
    }
    try {
      final ok = await _ensureAuthenticated();
      status = ok ? AuthStatus.authenticated : AuthStatus.error;
    } on Object {
      status = AuthStatus.error;
    }
    _inFlight = null;
    notifyListeners();
  }

  /// Re-runs [_ensureAuthenticated], showing the splash screen while it's
  /// in flight. Used by the auth-error screen's manual "Retry" button.
  void retry() => unawaited(_run(silent: false));

  /// Re-runs [_ensureAuthenticated] in the background without navigating
  /// away from the current screen. Only surfaces the auth-error screen if
  /// the run ultimately fails; success is invisible to the user. Used to
  /// recover from a mid-session refresh-token failure.
  void retrySilently() => unawaited(_run(silent: true));

  /// Resolves once the current recovery attempt (if any) settles, then
  /// reports whether the session ended up authenticated. If no recovery is
  /// in flight, resolves immediately with the current status. Used by
  /// `SessionRecoveryInterceptor` to retry a request that failed while the
  /// session was being recovered.
  Future<bool> awaitRecovery() async {
    final inFlight = _inFlight;
    if (inFlight != null) await inFlight;
    return status == AuthStatus.authenticated;
  }
}
