import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:syncos_screen/utils/responsive/app_scale.dart';

class PowerClampConsumptionInfoSection extends StatelessWidget {
  const PowerClampConsumptionInfoSection({
    required this.isGeneral,
    required this.phaseType,
    required this.dateTimeSelected,
    required this.energyConsumed,
    super.key,
  });

  final bool isGeneral;
  final String phaseType;
  final String dateTimeSelected;
  final double energyConsumed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isGeneral ? 'Total consumption' : phaseType,
              style: context.appTheme.typography.body.medium.scaledFontSize(
                context,
              ),
            ),
            Text(
              dateTimeSelected,
              style: TextStyle(
                fontSize: 8.scaledBy(context),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              '${energyConsumed.toStringAsFixed(2)} ',
              style: context.appTheme.typography.body.medium.scaledFontSize(
                context,
              ),
            ),
            Text(
              'kWh',
              style: context.appTheme.typography.body.medium.scaledFontSize(
                context,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
