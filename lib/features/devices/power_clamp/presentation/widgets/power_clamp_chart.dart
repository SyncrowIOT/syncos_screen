import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:syncos_screen/features/devices/power_clamp/data/energy_data.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/helpers/power_clamp_chart_config.dart';

export 'package:syncos_screen/features/devices/power_clamp/data/energy_data.dart';

class PowerClampChart extends StatelessWidget {
  const PowerClampChart({
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
        lineTouchData: PowerClampChartConfig.lineTouchData(context, chartData),
        titlesData: PowerClampChartConfig.titlesData(context, chartData),
        gridData: PowerClampChartConfig.gridData(context),
        lineBarsData: [PowerClampChartConfig.lineBarData(context, chartData)],
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
