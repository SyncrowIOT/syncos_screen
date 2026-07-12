import 'dart:async';

import 'package:device_manager/device_manager.dart';

final class EventBusControlDeviceServiceDecorator
    implements ControlDeviceService {
  EventBusControlDeviceServiceDecorator({
    required this._decoratee,
    this._debounceDuration = const Duration(milliseconds: 300),
  }) {
    _subscription = _bus.stream.listen(_onEvent);
  }

  final ControlDeviceService _decoratee;
  final Duration _debounceDuration;
  final _bus = StreamController<_ControlEvent>();
  late final StreamSubscription<_ControlEvent> _subscription;

  Timer? _debounceTimer;
  _ControlEvent? _pendingEvent;

  @override
  Future<bool> controlDevice({
    required String deviceUuid,
    required DeviceStatus status,
  }) {
    final completer = Completer<bool>();
    _bus.add(
      _ControlEvent(
        deviceUuid: deviceUuid,
        status: status,
        completer: completer,
      ),
    );
    return completer.future;
  }

  void _onEvent(_ControlEvent event) {
    _debounceTimer?.cancel();
    _pendingEvent?.completer.complete(false);
    _pendingEvent = event;
    _debounceTimer = Timer(_debounceDuration, _flush);
  }

  Future<void> _flush() async {
    final event = _pendingEvent;
    _pendingEvent = null;
    if (event == null) return;
    final result = await _decoratee.controlDevice(
      deviceUuid: event.deviceUuid,
      status: event.status,
    );
    event.completer.complete(result);
  }

  Future<void> dispose() async {
    _debounceTimer?.cancel();
    _pendingEvent?.completer.complete(false);
    await _subscription.cancel();
    await _bus.close();
  }
}

final class _ControlEvent {
  _ControlEvent({
    required this.deviceUuid,
    required this.status,
    required this.completer,
  });

  final String deviceUuid;
  final DeviceStatus status;
  final Completer<bool> completer;
}
