import 'package:device_manager/device_manager.dart';
import 'package:devices/devices.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:power_clamp_device_history/power_clamp_device_history.dart';
import 'package:syncos_screen/features/devices/factories/device_manager_factory.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/widgets/power_clamp_view.dart';
import 'package:syncos_screen/services/api/networking_service_factory.dart';

class PowerClampRoute extends StatelessWidget {
  const PowerClampRoute({
    required this.device,
    super.key,
  });

  final Device device;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            final bloc = DeviceManagerFactory.create<PowerClampStatusModel>(
              deviceUuid: device.uuid,
              fromStatusList: (id, jsonList) {
                return PowerClampStatusModel.fromStatusList(
                  id,
                  jsonList,
                  device.productType,
                );
              },
            )..add(const StartListeningEvent());
            return bloc;
          },
        ),
        BlocProvider(
          create: (context) {
            return PowerClampDeviceHistoryBloc(
              powerClampDeviceHistoryService:
                  DebouncedPowerClampDeviceHistoryService(
                    RemotePowerClampDeviceHistoryService(
                      networkService: NetworkingServiceFactory.create(),
                    ),
                  ),
            );
          },
        ),
      ],
      child: PowerClampView(device: device),
    );
  }
}
