import 'dart:async';

final class SocketAccessTokenSync {
  SocketAccessTokenSync({
    required Stream<String> accessTokenWrites,
    required this._applyAccessToken,
    required String initialToken,
  }) : _lastAppliedToken = initialToken {
    accessTokenWrites.listen(_onAccessTokenWritten);
  }

  final Future<void> Function(String accessToken) _applyAccessToken;
  String _lastAppliedToken;

  void _onAccessTokenWritten(String accessToken) {
    if (accessToken.isEmpty || accessToken == _lastAppliedToken) return;
    _lastAppliedToken = accessToken;
    unawaited(_applyAccessToken(accessToken));
  }
}
