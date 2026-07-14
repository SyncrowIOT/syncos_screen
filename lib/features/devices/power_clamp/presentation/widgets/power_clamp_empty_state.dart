import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:syncos_screen/utils/responsive/app_scale.dart';

class PowerClampEmptyState extends StatelessWidget {
  const PowerClampEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 16,
        children: [
          _buildTitle(context),
          _buildSubtitle(context),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      'No Data Available',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: context.appTheme.colors.text.body,
        fontSize: 20.scaledBy(context),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Text(
      'No energy consumption data found\nfor the selected period.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: context.appTheme.colors.text.bodySubtle,
        fontSize: 14.scaledBy(context),
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
    );
  }
}
