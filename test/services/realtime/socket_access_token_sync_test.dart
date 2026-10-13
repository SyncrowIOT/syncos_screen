import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncos_screen/services/realtime/socket_access_token_sync.dart';

class AccessTokenApplierSpy {
  final List<String> appliedTokens = [];

  Future<void> call(String accessToken) async => appliedTokens.add(accessToken);
}

(StreamController<String>, AccessTokenApplierSpy) _makeSut({
  String initialToken = 'initial-token',
}) {
  final writes = StreamController<String>.broadcast(sync: true);
  final applier = AccessTokenApplierSpy();
  SocketAccessTokenSync(
    accessTokenWrites: writes.stream,
    applyAccessToken: applier.call,
    initialToken: initialToken,
  );
  addTearDown(writes.close);
  return (writes, applier);
}

void main() {
  test('does not apply anything on initialization', () {
    final (_, applier) = _makeSut();

    expect(applier.appliedTokens, isEmpty);
  });

  test('ignores a write of the initial token', () {
    final (writes, applier) = _makeSut();

    writes.add('initial-token');

    expect(applier.appliedTokens, isEmpty);
  });

  test('ignores an empty token', () {
    final (writes, applier) = _makeSut();

    writes.add('');

    expect(applier.appliedTokens, isEmpty);
  });

  test('applies a new token exactly once', () {
    final (writes, applier) = _makeSut();

    writes
      ..add('new-token')
      ..add('new-token');

    expect(applier.appliedTokens, ['new-token']);
  });

  test('applies every distinct token in order', () {
    final (writes, applier) = _makeSut();

    writes
      ..add('first')
      ..add('second')
      ..add('first');

    expect(applier.appliedTokens, ['first', 'second', 'first']);
  });
}
