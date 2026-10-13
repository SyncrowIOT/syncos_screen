import 'package:flutter_test/flutter_test.dart';
import 'package:socketio_client/socketio_client.dart';
import 'package:syncos_screen/services/realtime/reconnect_safe_socketio_client_service_decorator.dart';
import 'package:syncos_screen/services/realtime/remote_socketio_client_service_creator.dart';

final Uri _webSocketUri = Uri.parse('wss://api.example.com');

RemoteSocketioClientServiceCreator _makeSut() {
  return RemoteSocketioClientServiceCreator(webSocketUri: _webSocketUri);
}

void main() {
  test('targets the device gateway over websocket with a fresh connection', () {
    final sut = _makeSut();

    final options = sut.optionsFor(
      const SocketioClientServiceCreatorParam(token: 'jwt'),
    );

    expect(options.url, _webSocketUri);
    expect(options.path, '/device-gateway');
    expect(options.transports, ['websocket']);
    expect(options.forceNewConnection, isTrue);
  });

  test('sends a raw token as a bearer header and auth token', () {
    final sut = _makeSut();

    final options = sut.optionsFor(
      const SocketioClientServiceCreatorParam(token: 'jwt'),
    );

    expect(options.authorizationHeader, 'Bearer jwt');
    expect(options.authHeaders, {'token': 'Bearer jwt'});
  });

  test('does not double the bearer prefix', () {
    final sut = _makeSut();

    final options = sut.optionsFor(
      const SocketioClientServiceCreatorParam(token: 'Bearer jwt'),
    );

    expect(options.authorizationHeader, 'Bearer jwt');
    expect(options.authHeaders, {'token': 'Bearer jwt'});
  });

  test('sends empty credentials for an empty token', () {
    final sut = _makeSut();

    final options = sut.optionsFor(
      const SocketioClientServiceCreatorParam(token: ''),
    );

    expect(options.authorizationHeader, isEmpty);
    expect(options.authHeaders, {'token': ''});
  });

  test('creates a reconnect-safe socket service', () async {
    final sut = _makeSut();

    final service = sut(const SocketioClientServiceCreatorParam(token: 'jwt'));
    addTearDown(service.dispose);

    expect(service, isA<ReconnectSafeSocketioClientServiceDecorator>());
  });
}
