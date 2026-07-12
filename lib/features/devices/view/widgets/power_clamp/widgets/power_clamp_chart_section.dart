import 'package:flutter/material.dart';
import 'package:syncos_screen/features/devices/view/widgets/power_clamp/power_chart.dart';

class PowerClampChartSection extends StatelessWidget {
  const PowerClampChartSection({
    required this.chartData,
    required this.selectedDate,
    super.key,
  });

  final List<EnergyData> chartData;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: EnergyConsumptionChart(
        chartData: chartData,
        totalConsumption: chartData.fold(
          0,
          (sum, data) => sum + data.consumption,
        ),
      ),
    );
  }
}
