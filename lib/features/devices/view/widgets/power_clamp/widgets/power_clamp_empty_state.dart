import 'package:flutter/material.dart';
import 'package:syncos_screen/utils/resource_manager/color_manager.dart';

class PowerClampEmptyState extends StatelessWidget {
  const PowerClampEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            _buildTitle(),
            _buildSubtitle(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'No Data Available',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: ColorsManager.grayColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'No energy consumption data found\nfor the selected period.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: ColorsManager.grayColor.withValues(alpha: 0.8),
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
    );
  }
}
