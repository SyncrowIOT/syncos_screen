import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:syncos_screen/utils/responsive/app_scale.dart';

class PowerClampConsumptionInfoSection extends StatelessWidget {
  const PowerClampConsumptionInfoSection({
    required this.isGeneral,
    required this.phaseType,
    required this.dateTimeSelected,
    super.key,
  });

  final bool isGeneral;
  final String phaseType;
  final String dateTimeSelected;

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
              style: context.appTheme.typography.body.medium.scaled(context),
            ),
            Text(
              dateTimeSelected,
              style: TextStyle(
                fontSize: 8.s(context),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
         Row(
          children: [
            Text(
              '1000.00 ',
              style: context.appTheme.typography.body.medium.scaled(context),
            ),
            Text(
              'kWh',
              style: context.appTheme.typography.body.medium.scaled(context),
            ),
          ],
        ),
      ],
    );
  }
}
