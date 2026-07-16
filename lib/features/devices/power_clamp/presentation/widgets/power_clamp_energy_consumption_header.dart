import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:syncos_screen/utils/responsive/app_scale.dart';

class PowerClampEnergyConsumptionHeader extends StatelessWidget {
  const PowerClampEnergyConsumptionHeader({
    required this.title,
    required this.energyConsumption,
    super.key,
  });

  final String title;
  final String energyConsumption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10.scaledBy(context),
      children: [
        const Text('Energy usage'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: context.appTheme.typography.body.large.scaledFontSize(context),
            ),
            Text(
              '$energyConsumption kWh',
              style: context.appTheme.typography.body.large.scaledFontSize(context),
            ),
          ],
        ),
      ],
    );
  }
}
