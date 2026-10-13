import 'package:flutter_test/flutter_test.dart';
import 'package:syncos_screen/services/api/notifying_token_store_decorator.dart';

import '../../helpers/token_store_spy.dart';

(NotifyingTokenStoreDecorator, TokenStoreSpy) _makeSut({
  String? accessToken,
  String? refreshToken,
}) {
  final tokenStore = TokenStoreSpy(
    accessToken: accessToken,
    refreshToken: refreshToken,
  );
  return (NotifyingTokenStoreDecorator(tokenStore: tokenStore), tokenStore);
}

void main() {
  test('starts with an empty current access token', () {
    final (sut, _) = _makeSut(accessToken: 'stored');

    expect(sut.currentAccessToken, isEmpty);
  });

  test('reads tokens from the wrapped store', () async {
    final (sut, _) = _makeSut(accessToken: 'access', refreshToken: 'refresh');

    expect(await sut.readAccessToken(), 'access');
    expect(await sut.readRefreshToken(), 'refresh');
  });

  test(
    'writes tokens to the wrapped store and caches the access token',
    () async {
      final (sut, tokenStore) = _makeSut();

      await sut.writeTokens(accessToken: 'access', refreshToken: 'refresh');

      expect(tokenStore.writtenTokens, [
        (accessToken: 'access', refreshToken: 'refresh'),
      ]);
      expect(sut.currentAccessToken, 'access');
    },
  );

  test('emits the written access token synchronously', () async {
    final (sut, _) = _makeSut();
    final emitted = <String>[];
    sut.accessTokenWrites.listen(emitted.add);

    await sut.writeTokens(accessToken: 'first', refreshToken: 'r1');
    await sut.writeTokens(accessToken: 'second', refreshToken: 'r2');

    expect(emitted, ['first', 'second']);
  });

  test(
    'clears the wrapped store and the cached access token without emitting',
    () async {
      final (sut, tokenStore) = _makeSut();
      final emitted = <String>[];
      sut.accessTokenWrites.listen(emitted.add);
      await sut.writeTokens(accessToken: 'access', refreshToken: 'refresh');

      await sut.clearTokens();

      expect(tokenStore.clearCount, 1);
      expect(sut.currentAccessToken, isEmpty);
      expect(emitted, ['access']);
    },
  );
}
