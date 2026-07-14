import 'package:flutter/material.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/widgets/power_clamp_info_card.dart';
import 'package:syncos_screen/utils/assets.dart';
import 'package:syncos_screen/utils/responsive/app_scale.dart';

class PowerClampPhaseMetricsSection extends StatelessWidget {
  const PowerClampPhaseMetricsSection({
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
            Expanded(
              child: PowerClampInfoCard(
                iconPath: Assets.voltageIcon,
                title: 'Voltage',
                value: voltage,
              ),
            ),
            Expanded(
              child: PowerClampInfoCard(
                iconPath: Assets.voltMeterIcon,
                title: 'Current',
                value: current,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.s(context)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: PowerClampInfoCard(
                iconPath: Assets.powerActiveIcon,
                title: 'Active Power',
                value: activePower,
              ),
            ),
            Expanded(
              child: PowerClampInfoCard(
                iconPath: Assets.speedoMeter,
                title: 'Power Factor',
                value: powerFactor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
