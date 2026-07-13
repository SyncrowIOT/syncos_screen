import 'package:flutter/material.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/widgets/power_clamp_info_card.dart';
import 'package:syncos_screen/utils/assets.dart';

class PowerClampGeneralMetricsSection extends StatelessWidget {
  const PowerClampGeneralMetricsSection({
    required this.activePower,
    required this.current,
    required this.frequency,
    super.key,
  });

  final String activePower;
  final String current;
  final String frequency;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        PowerClampInfoCard(
          iconPath: Assets.powerActiveIcon,
          title: 'Active',
          value: activePower,
          unit: ' w',
        ),
        PowerClampInfoCard(
          iconPath: Assets.voltMeterIcon,
          title: 'Current',
          value: current,
          unit: ' A',
        ),
        PowerClampInfoCard(
          iconPath: Assets.frequencyIcon,
          title: 'Frequency',
          value: frequency,
          unit: ' Hz',
        ),
      ],
    );
  }
}
