import 'package:device_manager/device_manager.dart';
import 'package:syncos_screen/features/devices/data/services/event_bus_control_device_service_decorator.dart';
import 'package:syncos_screen/services/api/networking_service_factory.dart';
import 'package:syncos_screen/services/realtime/realtime_service_factory.dart';

abstract final class DeviceManagerFactory {
  static Future<DevicesManagerBloc<T>> create<T>({
    required String deviceUuid,
    required T Function(String id, List<DeviceStatus> jsonList) fromStatusList,
  }) async {
    final dioNetworkingService = NetworkingServiceFactory.create();

    return DevicesManagerBloc<T>(
      deviceUuid: deviceUuid,
      fromStatusList: fromStatusList,
      controlDeviceService: EventBusControlDeviceServiceDecorator(
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
      realtimeService: await RealtimeServiceFactory.create(),
    );
  }

  static Future<DevicesManagerBloc<T>> withStartListening<T>(
    Future<DevicesManagerBloc<T>> future,
  ) {
    return future.then((bloc) {
      bloc.add(const StartListeningEvent());
      return bloc;
    });
  }
}
