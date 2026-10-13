import 'package:flutter_test/flutter_test.dart';
import 'package:syncos_screen/services/realtime/reconnect_safe_socketio_client_service_decorator.dart';

import '../../helpers/socketio_client_spies.dart';

(ReconnectSafeSocketioClientServiceDecorator, SocketioClientServiceSpy)
_makeSut({bool isConnected = false, bool suppressTokenExpiredErrors = false}) {
  final socket = SocketioClientServiceSpy(isConnectedValue: isConnected);
  return (
    ReconnectSafeSocketioClientServiceDecorator(
      decoratee: socket,
      suppressTokenExpiredErrors: suppressTokenExpiredErrors,
    ),
    socket,
  );
}

void main() {
  test('reports the connection state of the wrapped socket', () {
    final (sut, socket) = _makeSut(isConnected: true);

    expect(sut.isConnected, isTrue);
    socket.isConnectedValue = false;
    expect(sut.isConnected, isFalse);
  });

  test('replays connect for a handler registered on a connected socket', () {
    final (sut, _) = _makeSut(isConnected: true);
    final received = <dynamic>[];

    sut.on('connect', received.add);

    expect(received, [null]);
  });

  test('does not replay connect when the socket is disconnected', () {
    final (sut, _) = _makeSut();
    final received = <dynamic>[];

    sut.on('connect', received.add);

    expect(received, isEmpty);
  });

  test('forwards other events unchanged', () {
    final (sut, socket) = _makeSut();
    final received = <dynamic>[];
    sut.on('device-update', received.add);

    socket.fireEvent('device-update', {'deviceUuid': 'device-1'});

    expect(received, [
      {'deviceUuid': 'device-1'},
    ]);
  });

  test('stops forwarding an event after the handler is removed', () {
    final (sut, socket) = _makeSut();
    final received = <dynamic>[];
    void handler(dynamic data) => received.add(data);
    sut
      ..on('err', handler)
      ..off('err', handler);

    socket.fireEvent('err', {'message': 'device offline'});

    expect(received, isEmpty);
    expect(socket.listenerCount('err'), 0);
  });

  test('removes a handler that was never registered through it', () {
    final (sut, socket) = _makeSut();
    void handler(dynamic _) {}
    socket.on('err', handler);

    sut.off('err', handler);

    expect(socket.listenerCount('err'), 0);
  });

  test(
    'delegates emit, emitWithAck and dispose to the wrapped socket',
    () async {
      final (sut, socket) = _makeSut();
      socket.ackResponseFor['get-device-status'] = 'ack';
      final acks = <dynamic>[];

      sut
        ..emit('ping', 1)
        ..emitWithAck('get-device-status', 2, ack: acks.add);
      await sut.dispose();

      expect(socket.emitCalls, [('ping', 1)]);
      expect(socket.emitWithAckCalls, [('get-device-status', 2)]);
      expect(acks, ['ack']);
      expect(socket.isDisposed, isTrue);
    },
  );

  group('disconnect', () {
    test('is ignored while the socket is still connected', () {
      final (sut, socket) = _makeSut(isConnected: true);
      final received = <dynamic>[];
      sut.on('disconnect', received.add);

      socket.fireEvent('disconnect', 'io server disconnect');

      expect(received, isEmpty);
    });

    test('is forwarded when the socket is not connected', () {
      final (sut, socket) = _makeSut();
      final received = <dynamic>[];
      sut.on('disconnect', received.add);

      socket.fireEvent('disconnect', 'io server disconnect');

      expect(received, ['io server disconnect']);
    });
  });

  group('token expired errors', () {
    for (final event in ['err', 'connect_error']) {
      test('$event is forwarded by default so refresh can run', () {
        final (sut, socket) = _makeSut();
        final received = <dynamic>[];
        sut.on(event, received.add);

        socket.fireEvent(event, {'message': 'Token expired'});

        expect(received, hasLength(1));
      });

      test('$event is swallowed when suppressed', () {
        final (sut, socket) = _makeSut(suppressTokenExpiredErrors: true);
        final received = <dynamic>[];
        sut.on(event, received.add);

        socket.fireEvent(event, {'message': 'Token expired'});

        expect(received, isEmpty);
      });

      test('non-auth $event is forwarded even when suppressed', () {
        final (sut, socket) = _makeSut(suppressTokenExpiredErrors: true);
        final received = <dynamic>[];
        sut.on(event, received.add);

        socket.fireEvent(event, 'SocketException: Failed host lookup');

        expect(received, ['SocketException: Failed host lookup']);
      });
    }
  });
}
