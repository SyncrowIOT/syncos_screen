import 'dart:math';

import 'package:design_system/design_system.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:syncos_screen/features/devices/power_clamp/data/energy_data.dart';
import 'package:syncos_screen/utils/responsive/app_scale.dart';

abstract final class PowerClampChartConfig {
  static LineTouchData lineTouchData(
    BuildContext context,
    List<EnergyData> chartData,
  ) {
    return LineTouchData(
      getTouchLineEnd: (barData, spotIndex) => 10.0,
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (touchTooltipItem) {
          return context.appTheme.colors.background.neutralPrimary;
        },
        tooltipPadding: EdgeInsets.symmetric(
          horizontal: 10.s(context),
          vertical: 8.s(context),
        ),
        tooltipBorder: BorderSide(
          color: context.appTheme.colors.text.bodySubtle,
        ),
        tooltipBorderRadius: BorderRadius.circular(12.s(context)),
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            final index = spot.x.toInt();
            final time = index >= 0 && index < chartData.length
                ? chartData[index].time
                : '';
            return LineTooltipItem(
              '$time,\n ${spot.y.toStringAsFixed(2)} kWh',
              TextStyle(
                color: context.appTheme.colors.text.brand,
                fontWeight: FontWeight.w400,
                fontSize: max(9,9.s(context)),
              ),
            );
          }).toList();
        },
      ),
    );
  }

  static FlTitlesData titlesData(
    BuildContext context,
    List<EnergyData> chartData,
  ) {
    return FlTitlesData(
      bottomTitles: const AxisTitles(),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 12.s(context),
          getTitlesWidget: (value, meta) => const SizedBox.shrink(),
        ),
      ),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 12.s(context),
          getTitlesWidget: (value, meta) => const SizedBox.shrink(),
        ),
      ),
      topTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 70.s(context),
          interval: 1,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < chartData.length) {
              return Padding(
                padding: EdgeInsets.only(bottom: 24.s(context)),
                child: RotatedBox(
                  quarterTurns: -1,
                  child: Text(
                    chartData[index].time,
                    style: TextStyle(fontSize: max(9,10.s(context))),
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
      barWidth: 5.s(context),
    );
  }
}
