import 'package:flutter/material.dart';
import 'package:syncos_screen/features/devices/view/widgets/power_clamp/power_info_card.dart';
import 'package:syncos_screen/generated/assets.dart';

class PhaseMetricsSection extends StatelessWidget {
  const PhaseMetricsSection({
    required this.voltage,
    required this.current,
    required this.activePower,
    required this.powerFactor,
    super.key,
  });

  final String voltage;
  final String current;
  final String activePower;
  final String powerFactor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PowerClampInfoCard(
              iconPath: Assets.voltageIcon,
              title: 'Voltage',
              value: voltage,
              unit: ' V',
            ),
            PowerClampInfoCard(
              iconPath: Assets.voltMeterIcon,
              title: 'Current',
              value: current,
              unit: ' A',
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PowerClampInfoCard(
              iconPath: Assets.powerActiveIcon,
              title: 'Active Power',
              value: activePower,
              unit: ' w',
            ),
            PowerClampInfoCard(
              iconPath: Assets.speedoMeter,
              title: 'Power Factor',
              value: powerFactor,
              unit: '',
            ),
          ],
        ),
      ],
    );
  }
}
