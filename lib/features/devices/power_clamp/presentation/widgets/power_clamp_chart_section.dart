import 'package:flutter/material.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/widgets/power_clamp_chart.dart';

class PowerClampChartSection extends StatelessWidget {
  const PowerClampChartSection({
    required this.chartData,
    super.key,
  });

  final List<EnergyData> chartData;

  @override
  Widget build(BuildContext context) {
    return PowerClampChart(chartData: chartData);
  }
}
