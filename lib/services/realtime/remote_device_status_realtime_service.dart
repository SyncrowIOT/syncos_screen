import 'dart:async';

import 'package:device_manager/device_manager.dart';
import 'package:firebase_database/firebase_database.dart';

class RemoteDeviceStatusRealtimeService implements DeviceStatusRealtimeService {
  RemoteDeviceStatusRealtimeService({
    required this._databaseReference,
  });

  final DatabaseReference _databaseReference;
  final _controller = StreamController<DeviceStatusUpdate>.broadcast();
  final _subscriptions = <String, StreamSubscription<DatabaseEvent>>{};

  @override
  Stream<DeviceStatusUpdate> get statusUpdates => _controller.stream;

  @override
  Future<void> subscribe({required List<String> deviceUuids}) async {
    for (final deviceUuid in deviceUuids) {
      if (_subscriptions.containsKey(deviceUuid)) continue;

      _subscriptions[deviceUuid] = _databaseReference
          .child(deviceUuid)
          .onValue
          .listen(
            (event) => _onEvent(deviceUuid, event),
            onError: _controller.addError,
          );
    }
  }

  @override
  Future<void> unsubscribe({required List<String> deviceUuids}) async {
    for (final deviceUuid in deviceUuids) {
      await _subscriptions.remove(deviceUuid)?.cancel();
    }
  }

  @override
  Future<void> dispose() async {
    for (final subscription in _subscriptions.values) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    if (!_controller.isClosed) await _controller.close();
  }

  void _onEvent(String deviceUuid, DatabaseEvent event) {
    if (_controller.isClosed) return;

    final statuses = _parseStatuses(event.snapshot.value);
    if (statuses == null || statuses.isEmpty) return;

    _controller.add(
      DeviceStatusUpdate(deviceUuid: deviceUuid, statuses: statuses),
    );
  }

  List<DeviceStatus>? _parseStatuses(Object? value) {
    final rawStatuses = _extractRawStatuses(value);
    if (rawStatuses == null) return null;

    return rawStatuses
        .map(_asMap)
        .whereType<Map<String, dynamic>>()
        .where((status) => status['code'] is String)
        .map(
          (status) => DeviceStatus(
            code: status['code'] as String,
            value: status['value'],
          ),
        )
        .toList();
  }

  List<dynamic>? _extractRawStatuses(Object? value) {
    if (value is List) return value;

    final message = _asMap(value);
    if (message == null) return null;

    final nested = _asMap(message['data']) ?? _asMap(message['payload']);
    final target = nested ?? message;

    final statuses = target['statuses'] ?? target['status'] ?? target['data'];
    return statuses is List ? statuses : null;
  }

  Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }
}
