import 'dart:async';

import 'package:device_manager/device_manager.dart';

final class DebouncedControlDeviceServiceDecorator
    implements ControlDeviceService {
  DebouncedControlDeviceServiceDecorator({
    required this._decoratee,
    this._debounceDuration = const Duration(milliseconds: 300),
  });

  final ControlDeviceService _decoratee;
  final Duration _debounceDuration;

  Timer? _debounceTimer;
  _PendingControlRequest? _pendingRequest;

  @override
  Future<bool> controlDevice({
    required String deviceUuid,
    required DeviceStatus status,
  }) {
    _debounceTimer?.cancel();
    _pendingRequest?.completer.complete(false);

    final completer = Completer<bool>();
    _pendingRequest = _PendingControlRequest(
      deviceUuid: deviceUuid,
      status: status,
      completer: completer,
    );
    _debounceTimer = Timer(_debounceDuration, _flush);
    return completer.future;
  }

  Future<void> _flush() async {
    final request = _pendingRequest;
    _pendingRequest = null;
    if (request == null) return;
    final result = await _decoratee.controlDevice(
      deviceUuid: request.deviceUuid,
      status: request.status,
    );
    request.completer.complete(result);
  }

  Future<void> dispose() async {
    _debounceTimer?.cancel();
    _pendingRequest?.completer.complete(false);
  }
}

final class _PendingControlRequest {
  _PendingControlRequest({
    required this.deviceUuid,
    required this.status,
    required this.completer,
  });

  final String deviceUuid;
  final DeviceStatus status;
  final Completer<bool> completer;
}
