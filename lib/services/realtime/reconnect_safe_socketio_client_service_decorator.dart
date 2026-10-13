import 'package:socketio_client/socketio_client.dart';

final class ReconnectSafeSocketioClientServiceDecorator
    implements SocketioClientService {
  ReconnectSafeSocketioClientServiceDecorator({
    required this._decoratee,
    this._suppressTokenExpiredErrors = false,
  });

  final SocketioClientService _decoratee;
  final bool _suppressTokenExpiredErrors;
  final Map<String, Map<void Function(dynamic), void Function(dynamic)>>
  _forwarders = {};

  @override
  bool get isConnected => _decoratee.isConnected;

  @override
  void on(String event, void Function(dynamic) handler) {
    final forwarder = _forwarderFor(event, handler);
    _forwarders.putIfAbsent(event, () => {})[handler] = forwarder;
    _decoratee.on(event, forwarder);
    if (event == 'connect' && _decoratee.isConnected) {
      handler(null);
    }
  }

  @override
  void off(String event, void Function(dynamic) handler) {
    final forwarder = _forwarders[event]?.remove(handler) ?? handler;
    _decoratee.off(event, forwarder);
  }

  @override
  void emit(String event, dynamic data) => _decoratee.emit(event, data);

  @override
  void emitWithAck(
    String event,
    dynamic data, {
    required void Function(dynamic) ack,
  }) => _decoratee.emitWithAck(event, data, ack: ack);

  @override
  Future<void> dispose() => _decoratee.dispose();

  void Function(dynamic) _forwarderFor(
    String event,
    void Function(dynamic) handler,
  ) {
    if (event == 'disconnect') {
      return (dynamic data) {
        if (_decoratee.isConnected) return;
        handler(data);
      };
    }
    if ((event == 'err' || event == 'connect_error') &&
        _suppressTokenExpiredErrors) {
      return (dynamic data) {
        if (SocketAuthError.isTokenExpired(data)) return;
        handler(data);
      };
    }
    return handler;
  }
}
