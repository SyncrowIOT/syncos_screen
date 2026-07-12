import 'package:design_system/design_system.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class EnergyConsumptionChart extends StatefulWidget {
  const EnergyConsumptionChart({
    required this.chartData,
    required this.totalConsumption,
    super.key,
  });

  final List<EnergyData> chartData;
  final double totalConsumption;
  @override
  State<EnergyConsumptionChart> createState() => _EnergyConsumptionChartState();
}

class _EnergyConsumptionChartState extends State<EnergyConsumptionChart> {
  late List<EnergyData> _chartData;

  @override
  void initState() {
    _chartData = widget.chartData;
    super.initState();
  }

  @override
  void didUpdateWidget(EnergyConsumptionChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chartData != widget.chartData) {
      _chartData = widget.chartData;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          getTouchLineEnd: (barData, spotIndex) => 10.0,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchTooltipItem) {
              return context.appTheme.colors.background.neutralPrimary;
            },
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            tooltipBorder: BorderSide(
              color: context.appTheme.colors.text.bodySubtle,
            ),
            tooltipBorderRadius: BorderRadius.circular(12),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.x},\n ${spot.y.toStringAsFixed(2)} kWh',
                  TextStyle(
                    color: context.appTheme.colors.text.brand,
                    fontWeight: FontWeight.w400,
                    fontSize: 9,
                  ),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: const AxisTitles(),
          leftTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          topTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 70,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < _chartData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: 24,
                    ),
                    child: RotatedBox(
                      quarterTurns: -1,
                      child: Text(
                        _chartData[index].time,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        gridData: FlGridData(
          verticalInterval: 1,
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: context.appTheme.colors.text.bodySubtle.withAlpha(100),
              dashArray: [8, 8],
              strokeWidth: 1,
            );
          },
          drawHorizontalLine: false,
        ),
        lineBarsData: [
          LineChartBarData(
            preventCurveOvershootingThreshold: 0.1,
            curveSmoothness: 0.5,
            preventCurveOverShooting: true,
            spots: _chartData
                .asMap()
                .entries
                .map(
                  (entry) => FlSpot(
                    entry.key.toDouble(),
                    entry.value.consumption,
                  ),
                )
                .toList(),
            isCurved: true,
            color: context.appTheme.colors.text.brand,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  context.appTheme.colors.text.brandSoft,
                  context.appTheme.colors.text.brandSofter,
                  context.appTheme.colors.background.neutralPrimary,
                ],
                begin: Alignment.center,
                end: Alignment.bottomCenter,
              ),
            ),
            dotData: const FlDotData(show: false),
            isStrokeCapRound: true,
            barWidth: 5,
          ),
        ],
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class EnergyData {
  const EnergyData({required this.time, required this.consumption});
  final String time;
  final double consumption;
}
