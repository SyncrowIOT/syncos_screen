import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:syncos_screen/features/devices/view/widgets/power_clamp/energy_data.dart';
import 'package:syncos_screen/features/devices/view/widgets/power_clamp/power_chart_config.dart';

export 'package:syncos_screen/features/devices/view/widgets/power_clamp/energy_data.dart';

class EnergyConsumptionChart extends StatelessWidget {
  const EnergyConsumptionChart({
    required this.chartData,
    required this.totalConsumption,
    super.key,
  });

  final List<EnergyData> chartData;
  final double totalConsumption;
  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        lineTouchData: PowerChartConfig.lineTouchData(context),
        titlesData: PowerChartConfig.titlesData(chartData),
        gridData: PowerChartConfig.gridData(context),
        lineBarsData: [PowerChartConfig.lineBarData(context, chartData)],
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
