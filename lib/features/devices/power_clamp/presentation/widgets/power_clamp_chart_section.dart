import 'package:flutter/material.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/helpers/power_clamp_energy_data_mapper.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/widgets/power_clamp_chart.dart';

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
    return PowerClampChart(
      chartData: chartData,
      totalConsumption: PowerClampEnergyDataMapper.totalConsumption(chartData),
    );
  }
}
