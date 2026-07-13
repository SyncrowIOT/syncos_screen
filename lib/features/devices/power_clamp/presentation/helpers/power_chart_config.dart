import 'package:design_system/design_system.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:syncos_screen/features/devices/power_clamp/data/energy_data.dart';

abstract final class PowerChartConfig {
  static LineTouchData lineTouchData(BuildContext context) {
    return LineTouchData(
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
    );
  }

  static FlTitlesData titlesData(List<EnergyData> chartData) {
    return FlTitlesData(
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
            if (index >= 0 && index < chartData.length) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: RotatedBox(
                  quarterTurns: -1,
                  child: Text(
                    chartData[index].time,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  static FlGridData gridData(BuildContext context) {
    return FlGridData(
      verticalInterval: 1,
      getDrawingVerticalLine: (value) {
        return FlLine(
          color: context.appTheme.colors.text.bodySubtle.withAlpha(100),
          dashArray: [8, 8],
          strokeWidth: 1,
        );
      },
      drawHorizontalLine: false,
    );
  }

  static LineChartBarData lineBarData(
    BuildContext context,
    List<EnergyData> chartData,
  ) {
    return LineChartBarData(
      preventCurveOvershootingThreshold: 0.1,
      curveSmoothness: 0.5,
      preventCurveOverShooting: true,
      spots: chartData
          .asMap()
          .entries
          .map(
            (entry) => FlSpot(entry.key.toDouble(), entry.value.consumption),
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
    );
  }
}
