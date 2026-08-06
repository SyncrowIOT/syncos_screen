import 'package:device_manager/device_manager.dart';
import 'package:devices/devices.dart';
import 'package:flutter/material.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/widgets/power_clamp_phase_view.dart';

class PowerClampPhasePages extends StatelessWidget {
  const PowerClampPhasePages({
    required this.device,
    required this.powerClampModel,
    required this.pageController,
    required this.selectedDateNotifier,
    super.key,
  });

  final Device device;
  final PowerClampStatusModel? powerClampModel;
  final PageController pageController;
  final ValueNotifier<DateTime> selectedDateNotifier;

  static const _phases = [
    _PhasePageConfig(
      title: 'Total Energy \nConsumption',
      phaseType: '',
      isGeneral: true,
    ),
    _PhasePageConfig(
      title: 'Phase A Energy \nConsumption',
      phaseType: 'Phase A consumption',
    ),
    _PhasePageConfig(
      title: 'Phase B Energy \nConsumption',
      phaseType: 'Phase B consumption',
    ),
    _PhasePageConfig(
      title: 'Phase C Energy \nConsumption',
      phaseType: 'Phase C consumption',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: pageController,
      children: _phases.map(
        (phase) {
          return PowerClampPhaseView(
            deviceUuid: device.uuid,
            generalData: phase.isGeneral ? powerClampModel?.general : null,
            phaseData: phase.dataFor(powerClampModel),
            title: phase.title,
            phaseType: phase.phaseType,
            isGeneral: phase.isGeneral,
            selectedDateNotifier: selectedDateNotifier,
          );
        },
      ).toList(),
    );
  }
}

class _PhasePageConfig {
  const _PhasePageConfig({
    required this.title,
    required this.phaseType,
    this.isGeneral = false,
  });

  final String title;
  final String phaseType;
  final bool isGeneral;

  PowerClampPhaseData? dataFor(PowerClampStatusModel? model) {
    if (isGeneral || model == null) {
      return null;
    }
    return switch (phaseType) {
      'Phase A consumption' => model.phaseA,
      'Phase B consumption' => model.phaseB,
      'Phase C consumption' => model.phaseC,
      _ => null,
    };
  }
}
