import 'package:device_manager/device_manager.dart';
import 'package:devices/devices.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:power_clamp_device_history/power_clamp_device_history.dart';
import 'package:syncos_screen/features/devices/factories/device_manager_factory.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/widgets/power_clamp_form.dart';
import 'package:syncos_screen/services/api/networking_service_factory.dart';

class PowerClampView extends StatefulWidget {
  const PowerClampView({
    required this.device,
    super.key,
  });

  final Device device;

  @override
  State<PowerClampView> createState() => _PowerClampViewState();
}

class _PowerClampViewState extends State<PowerClampView> {
  late final Future<DevicesManagerBloc<PowerClampStatusModel>> _blocFuture;

  @override
  void initState() {
    super.initState();
    _blocFuture = DeviceManagerFactory.create<PowerClampStatusModel>(
      deviceUuid: widget.device.uuid,
      fromStatusList: (id, jsonList) => PowerClampStatusModel.fromStatusList(
        id,
        jsonList,
        widget.device.productType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DevicesManagerBloc<PowerClampStatusModel>>(
      future: _blocFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Text(
                snapshot.error?.toString() ?? 'Unable to connect',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: snapshot.data!),
            BlocProvider(
              create: (context) => PowerClampDeviceHistoryBloc(
                powerClampDeviceHistoryService:
                    DebouncedPowerClampDeviceHistoryService(
                      RemotePowerClampDeviceHistoryService(
                        networkService: NetworkingServiceFactory.create(),
                      ),
                    ),
              ),
            ),
          ],
          child: PowerClampForm(device: widget.device),
        );
      },
    );
  }
}
