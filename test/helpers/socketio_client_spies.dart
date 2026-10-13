import 'package:socketio_client/socketio_client.dart';

class SocketioClientServiceSpy implements SocketioClientService {
  SocketioClientServiceSpy({this.isConnectedValue = false});

  bool isConnectedValue;
  bool isDisposed = false;
  final List<(String, dynamic)> emitCalls = [];
  final List<(String, dynamic)> emitWithAckCalls = [];
  final Map<String, dynamic> ackResponseFor = {};
  final Map<String, List<void Function(dynamic)>> _listeners = {};

  @override
  bool get isConnected => isConnectedValue;

  @override
  void on(String event, void Function(dynamic) handler) {
    _listeners.putIfAbsent(event, () => []).add(handler);
  }

  @override
  void off(String event, void Function(dynamic) handler) {
    _listeners[event]?.remove(handler);
  }

  @override
  void emit(String event, dynamic data) => emitCalls.add((event, data));

  @override
  void emitWithAck(
    String event,
    dynamic data, {
    required void Function(dynamic) ack,
  }) {
    emitWithAckCalls.add((event, data));
    ack(ackResponseFor[event]);
  }

  @override
  Future<void> dispose() async {
    isDisposed = true;
    isConnectedValue = false;
  }

  int listenerCount(String event) => _listeners[event]?.length ?? 0;

  void fireEvent(String event, dynamic data) {
    final handlers = List<void Function(dynamic)>.of(_listeners[event] ?? []);
    for (final handler in handlers) {
      handler(data);
    }
  }
}

class SocketioClientServiceCreatorSpy implements SocketioClientServiceCreator {
  final List<String> requestedTokens = [];
  final List<SocketioClientServiceSpy> createdServices = [];

  @override
  SocketioClientService call(SocketioClientServiceCreatorParam param) {
    requestedTokens.add(param.token);
    final service = SocketioClientServiceSpy();
    createdServices.add(service);
    return service;
  }
}
