import 'package:socketio_client/socketio_client.dart';
import 'package:syncos_screen/services/realtime/reconnect_safe_socketio_client_service_decorator.dart';

final class RemoteSocketioClientServiceCreator
    implements SocketioClientServiceCreator {
  RemoteSocketioClientServiceCreator({required this._webSocketUri});

  static const _path = '/device-gateway';
  static const _bearerPrefix = 'Bearer ';

  final Uri _webSocketUri;

  @override
  SocketioClientService call(SocketioClientServiceCreatorParam param) {
    return ReconnectSafeSocketioClientServiceDecorator(
      decoratee: SocketIoClientServiceImpl.fromOptions(optionsFor(param)),
    );
  }

  SocketioClientOptions optionsFor(SocketioClientServiceCreatorParam param) {
    final rawToken = param.token.startsWith(_bearerPrefix)
        ? param.token.substring(_bearerPrefix.length)
        : param.token;
    final bearerToken = rawToken.isEmpty ? '' : '$_bearerPrefix$rawToken';
    return SocketioClientOptions(
      url: _webSocketUri,
      path: _path,
      authorizationHeader: bearerToken,
      authHeaders: {'token': bearerToken},
      forceNewConnection: true,
    );
  }
}
