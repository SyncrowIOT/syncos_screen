import 'dart:async';

import 'package:flutter/foundation.dart';

enum AuthStatus { loading, authenticated, error }

class AuthController extends ChangeNotifier {
  AuthController({required this._ensureAuthenticated}) {
    unawaited(_run());
  }

  final Future<bool> Function() _ensureAuthenticated;

  AuthStatus status = AuthStatus.loading;

  Future<void>? _inFlight;

  Future<void> _run() {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    final future = _runOnce();
    _inFlight = future;
    return future;
  }

  Future<void> _runOnce() async {
    status = AuthStatus.loading;
    notifyListeners();
    try {
      final ok = await _ensureAuthenticated();
      status = ok ? AuthStatus.authenticated : AuthStatus.error;
    } on Object {
      status = AuthStatus.error;
    }
    _inFlight = null;
    notifyListeners();
  }

  void retry() => unawaited(_run());
}
