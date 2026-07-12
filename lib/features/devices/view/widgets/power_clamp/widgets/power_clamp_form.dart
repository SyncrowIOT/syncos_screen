import 'package:device_manager/device_manager.dart';
import 'package:devices/devices.dart' as devices_package;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncos_screen/common/widgets/page_indicator.dart';
import 'package:syncos_screen/features/devices/view/widgets/power_clamp/power_chart.dart';
import 'package:syncos_screen/features/devices/view/widgets/power_clamp/widgets/power_clamp_phase_view.dart';

class PowerClampForm extends StatefulWidget {
  const PowerClampForm({required this.device, super.key});

  final devices_package.Device device;

  @override
  State<PowerClampForm> createState() => _PowerClampFormState();
}

class _PowerClampFormState extends State<PowerClampForm> {
  final _pageController = PageController();
  final _currentPageNotifier = ValueNotifier<int>(0);
  final _selectedDateNotifier = ValueNotifier<DateTime>(DateTime.now());
  static const _pageCount = 4;

  @override
  void initState() {
    _pageController.addListener(_handlePageChange);
    super.initState();
  }

  void _handlePageChange() {
    final nextPage = _pageController.page?.round() ?? 0;
    _currentPageNotifier.value = nextPage;
  }

  @override
  void dispose() {
    context.read<DevicesManagerBloc<PowerClampStatusModel>>().add(
          const StopListeningEvent(),
        );
    _pageController
      ..removeListener(_handlePageChange)
      ..dispose();
    _currentPageNotifier.dispose();
    _selectedDateNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DevicesManagerBloc<PowerClampStatusModel>,
        DevicesManagerState<PowerClampStatusModel>>(
      builder: (context, state) {
        final powerClampModel = state.device;

        final chartData = <EnergyData>[];

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.device.name),
          ),
          body: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  children: [
                    PowerClampPhaseView(
                      deviceUuid: widget.device.uuid,
                      generalData: powerClampModel?.general,
                      title: 'Total Energy \nConsumption',
                      phaseType: '',
                      isGeneral: true,
                      chartData: chartData,
                      selectedDateNotifier: _selectedDateNotifier,
                    ),
                    PowerClampPhaseView(
                      deviceUuid: widget.device.uuid,
                      phaseData: powerClampModel?.phaseA,
                      title: 'Phase A Energy \nConsumption',
                      phaseType: 'Phase A consumption',
                      isGeneral: false,
                      chartData: chartData,
                      selectedDateNotifier: _selectedDateNotifier,
                    ),
                    PowerClampPhaseView(
                      deviceUuid: widget.device.uuid,
                      phaseData: powerClampModel?.phaseB,
                      title: 'Phase B Energy \nConsumption',
                      phaseType: 'Phase B consumption',
                      isGeneral: false,
                      chartData: chartData,
                      selectedDateNotifier: _selectedDateNotifier,
                    ),
                    PowerClampPhaseView(
                      deviceUuid: widget.device.uuid,
                      phaseData: powerClampModel?.phaseC,
                      title: 'Phase C Energy \nConsumption',
                      phaseType: 'Phase C consumption',
                      isGeneral: false,
                      chartData: chartData,
                      selectedDateNotifier: _selectedDateNotifier,
                    ),
                  ],
                ),
              ),
              PageIndicator(
                currentPageNotifier: _currentPageNotifier,
                pageCount: _pageCount,
              ),
            ],
          ),
        );
      },
    );
  }
}
