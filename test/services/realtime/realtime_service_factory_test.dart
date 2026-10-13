import 'package:device_manager/device_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncos_screen/services/api/notifying_token_store_decorator.dart';
import 'package:syncos_screen/services/auth/token_refresh_service.dart';
import 'package:syncos_screen/services/realtime/realtime_service_factory.dart';

import '../../helpers/socketio_client_spies.dart';
import '../../helpers/token_store_spy.dart';

class TokenRefreshServiceSpy implements TokenRefreshService {
  TokenRefreshServiceSpy({required this.tokenStore});

  final NotifyingTokenStoreDecorator tokenStore;
  int callCount = 0;
  bool _fails = false;

  void completeWithFailure() => _fails = true;

  @override
  Future<String> call() async {
    callCount++;
    if (_fails) throw StateError('invalid refresh token');
    final token = 'refreshed-token-$callCount';
    await tokenStore.writeTokens(accessToken: token, refreshToken: 'refresh');
    return token;
  }
}

class SessionRecoverySpy {
  SessionRecoverySpy({required this.tokenStore});

  final NotifyingTokenStoreDecorator tokenStore;
  int callCount = 0;
  bool _fails = false;

  void completeWithFailure() => _fails = true;

  Future<bool> call() async {
    callCount++;
    if (_fails) return false;
    await tokenStore.writeTokens(
      accessToken: 'login-token',
      refreshToken: 'refresh',
    );
    return true;
  }
}

Future<
  ({
    DeviceStatusRealtimeService sut,
    NotifyingTokenStoreDecorator tokenStore,
    TokenRefreshServiceSpy tokenRefreshService,
    SessionRecoverySpy sessionRecovery,
    SocketioClientServiceCreatorSpy creator,
  })
>
_makeSut() async {
  final tokenStore = NotifyingTokenStoreDecorator(tokenStore: TokenStoreSpy());
  final tokenRefreshService = TokenRefreshServiceSpy(tokenStore: tokenStore);
  final sessionRecovery = SessionRecoverySpy(tokenStore: tokenStore);
  final creator = SocketioClientServiceCreatorSpy();
  await tokenStore.writeTokens(
    accessToken: 'initial-token',
    refreshToken: 'refresh',
  );
  final sut = RealtimeServiceFactory.create(
    tokenStore: tokenStore,
    tokenRefreshService: tokenRefreshService,
    awaitRecovery: sessionRecovery.call,
    socketioClientServiceCreator: creator,
  );
  return (
    sut: sut,
    tokenStore: tokenStore,
    tokenRefreshService: tokenRefreshService,
    sessionRecovery: sessionRecovery,
    creator: creator,
  );
}

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

const _tokenExpired = {'error': 'TOKEN_EXPIRED'};

void main() {
  test('opens one socket with the current access token', () async {
    final (
      :sut,
      tokenStore: _,
      :tokenRefreshService,
      :sessionRecovery,
      :creator,
    ) = await _makeSut();

    expect(sut, isA<WebSocketDeviceStatusRealtimeService>());
    expect(creator.requestedTokens, ['initial-token']);
    expect(tokenRefreshService.callCount, 0);
    expect(sessionRecovery.callCount, 0);
  });

  test(
    'reconnects once with the refreshed token when the socket token expires',
    () async {
      final (
        sut: _,
        tokenStore: _,
        :tokenRefreshService,
        :sessionRecovery,
        :creator,
      ) = await _makeSut();

      creator.createdServices.first.fireEvent('err', _tokenExpired);
      await _settle();

      expect(creator.requestedTokens, ['initial-token', 'refreshed-token-1']);
      expect(creator.createdServices.first.isDisposed, isTrue);
      expect(tokenRefreshService.callCount, 1);
      expect(sessionRecovery.callCount, 0);
    },
  );

  test(
    'reconnects once with the re-login token when the refresh token is rejected',
    () async {
      final (
        sut: _,
        tokenStore: _,
        :tokenRefreshService,
        :sessionRecovery,
        :creator,
      ) = await _makeSut();
      tokenRefreshService.completeWithFailure();

      creator.createdServices.first.fireEvent('connect_error', _tokenExpired);
      await _settle();

      expect(creator.requestedTokens, ['initial-token', 'login-token']);
      expect(sessionRecovery.callCount, 1);
    },
  );

  test('keeps the socket when both refresh and re-login fail', () async {
    final (
      sut: _,
      tokenStore: _,
      :tokenRefreshService,
      :sessionRecovery,
      :creator,
    ) = await _makeSut();
    tokenRefreshService.completeWithFailure();
    sessionRecovery.completeWithFailure();

    creator.createdServices.first.fireEvent('err', _tokenExpired);
    await _settle();

    expect(creator.requestedTokens, ['initial-token']);
    expect(creator.createdServices.first.isDisposed, isFalse);
  });

  test(
    'reconnects with a token renewed outside the socket, such as a login',
    () async {
      final (
        sut: _,
        :tokenStore,
        tokenRefreshService: _,
        sessionRecovery: _,
        :creator,
      ) = await _makeSut();

      await tokenStore.writeTokens(
        accessToken: 'http-token',
        refreshToken: 'refresh',
      );
      await _settle();

      expect(creator.requestedTokens, ['initial-token', 'http-token']);
    },
  );

  test('does not surface token-expired errors to status listeners', () async {
    final (
      :sut,
      tokenStore: _,
      tokenRefreshService: _,
      sessionRecovery: _,
      :creator,
    ) = await _makeSut();
    final errors = <Object>[];
    sut.statusUpdates.listen((_) {}, onError: errors.add);

    creator.createdServices.first.fireEvent('err', _tokenExpired);
    await _settle();

    expect(errors, isEmpty);
  });

  test('rejoins subscribed devices on the reconnected socket', () async {
    final (
      :sut,
      tokenStore: _,
      tokenRefreshService: _,
      sessionRecovery: _,
      :creator,
    ) = await _makeSut();
    final updates = <DeviceStatusUpdate>[];
    sut.statusUpdates.listen(updates.add);
    await sut.subscribe(deviceUuids: ['device-1']);

    creator.createdServices.first.fireEvent('err', _tokenExpired);
    await _settle();
    creator.createdServices.last
      ..isConnectedValue = true
      ..ackResponseFor['get-device-status'] = {
        'deviceUuid': 'device-1',
        'statuses': [
          {'code': 'power_total', 'value': 10},
        ],
      }
      ..fireEvent('connect', null);

    await _settle();

    final joinCalls = creator.createdServices.last.emitWithAckCalls;
    expect(joinCalls.map((call) => call.$1), ['get-device-status']);
    expect(joinCalls.single.$2, {'deviceUuid': 'device-1'});
    expect(updates.single.deviceUuid, 'device-1');
    expect(updates.single.statuses.single.code, 'power_total');
  });

  test('instance returns the same shared service on repeated access', () {
    dotenv.loadFromString(envString: 'WS_URL=wss://api.example.com');

    final first = RealtimeServiceFactory.instance;
    addTearDown(first.dispose);

    expect(identical(first, RealtimeServiceFactory.instance), isTrue);
    expect(first, isA<WebSocketDeviceStatusRealtimeService>());
  });
}
