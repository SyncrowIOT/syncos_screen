import 'dart:async';

import 'package:flutter/foundation.dart';

enum AuthStatus { loading, authenticated, error }

class AuthController extends ChangeNotifier {
  AuthController({required this._ensureAuthenticated}) {
    unawaited(_run());
  }

  final Future<bool> Function() _ensureAuthenticated;

  AuthStatus status = AuthStatus.loading;

  Future<void> _run() async {
    status = AuthStatus.loading;
    notifyListeners();
    try {
      final ok = await _ensureAuthenticated();
      status = ok ? AuthStatus.authenticated : AuthStatus.error;
    } on Object {
      status = AuthStatus.error;
    }
    notifyListeners();
  }

  void retry() => _run();
}
