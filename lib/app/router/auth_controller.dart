import 'package:flutter/foundation.dart';

enum AuthStatus { loading, authenticated, error }

class AuthController extends ChangeNotifier {
  AuthController({required Future<bool> Function() ensureAuthenticated})
      : _ensureAuthenticated = ensureAuthenticated {
    _run();
  }

  final Future<bool> Function() _ensureAuthenticated;

  AuthStatus status = AuthStatus.loading;

  Future<void> _run() async {
    status = AuthStatus.loading;
    notifyListeners();
    final ok = await _ensureAuthenticated();
    status = ok ? AuthStatus.authenticated : AuthStatus.error;
    notifyListeners();
  }

  void retry() => _run();
}
