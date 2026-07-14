import 'package:device_manager/device_manager.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:syncos_screen/features/devices/data/services/debounced_control_device_service_decorator.dart';
import 'package:syncos_screen/services/api/networking_service_factory.dart';
import 'package:syncos_screen/services/realtime/firebase_device_status_realtime_service.dart';

abstract final class DeviceManagerFactory {
  static DevicesManagerBloc<T> create<T>({
    required String deviceUuid,
    required T Function(String id, List<DeviceStatus> jsonList) fromStatusList,
  }) {
    final dioNetworkingService = NetworkingServiceFactory.create();

    return DevicesManagerBloc<T>(
      deviceUuid: deviceUuid,
      fromStatusList: fromStatusList,
      controlDeviceService: DebouncedControlDeviceServiceDecorator(
        decoratee: RemoteControlDeviceService(
          networkingService: dioNetworkingService,
        ),
      ),
      batchControlDevicesService: RemoteBatchControlDevicesService(
        networkingService: dioNetworkingService,
      ),
      factoryResetDeviceService: RemoteFactoryResetDeviceService(
        networkingService: dioNetworkingService,
      ),
      batchStatusService: RemoteBatchStatusService(
        networkingService: dioNetworkingService,
      ),
      realtimeService: FirebaseDeviceStatusRealtimeService(
        databaseReference: FirebaseDatabase.instance.ref('device-status'),
      ),
    );
  }
}
