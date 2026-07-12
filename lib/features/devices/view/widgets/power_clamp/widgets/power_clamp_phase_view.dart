import 'package:device_manager/device_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:power_clamp_device_history/power_clamp_device_history.dart';
import 'package:syncos_screen/features/devices/view/widgets/power_clamp/power_chart.dart';
import 'package:syncos_screen/features/devices/view/widgets/power_clamp/widgets/consumption_info_section.dart';
import 'package:syncos_screen/features/devices/view/widgets/power_clamp/widgets/energy_consumption_header.dart';
import 'package:syncos_screen/features/devices/view/widgets/power_clamp/widgets/general_metrics_section.dart';
import 'package:syncos_screen/features/devices/view/widgets/power_clamp/widgets/phase_metrics_section.dart';
import 'package:syncos_screen/features/devices/view/widgets/power_clamp/widgets/power_clamp_chart_section.dart';
import 'package:syncos_screen/features/devices/view/widgets/power_clamp/widgets/power_clamp_empty_state.dart';
import 'package:syncos_screen/features/devices/view/widgets/power_clamp/widgets/power_clamp_failure_state.dart';
import 'package:syncos_screen/widgets/default_container.dart';
import 'package:syncos_screen/widgets/month_year_selector.dart';

class PowerClampPhaseView extends StatefulWidget {
  const PowerClampPhaseView({
    required this.deviceUuid,
    required this.title,
    required this.phaseType,
    required this.isGeneral,
    required this.chartData,
    required this.selectedDateNotifier,
    this.generalData,
    this.phaseData,
    super.key,
  });

  final String deviceUuid;
  final PowerClampGeneralData? generalData;
  final PowerClampPhaseData? phaseData;
  final String title;
  final String phaseType;
  final bool isGeneral;
  final List<EnergyData> chartData;
  final ValueNotifier<DateTime> selectedDateNotifier;

  @override
  State<PowerClampPhaseView> createState() => _PowerClampPhaseViewState();
}

class _PowerClampPhaseViewState extends State<PowerClampPhaseView> {
  @override
  void initState() {
    super.initState();
    widget.selectedDateNotifier.addListener(_onDateChanged);
    _fetchHistoryData();
  }

  @override
  void dispose() {
    widget.selectedDateNotifier.removeListener(_onDateChanged);
    super.dispose();
  }

  void _onDateChanged() {
    if (mounted) {
      _fetchHistoryData();
    }
  }

  void _fetchHistoryData() {
    final selectedDate = widget.selectedDateNotifier.value;
    final monthDate = DateTime(selectedDate.year, selectedDate.month);

    context.read<PowerClampDeviceHistoryBloc>().add(
      LoadPowerClampDeviceHistoryEvent(
        GetPowerClampDeviceHistoryParam(
          deviceUuid: widget.deviceUuid,
          monthDate: monthDate,
        ),
      ),
    );
  }

  String _getDateRange() {
    final selectedDate = widget.selectedDateNotifier.value;
    final firstDay = DateTime(selectedDate.year, selectedDate.month);
    final lastDay = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    final dateFormat = DateFormat('dd/MM/yyyy');
    return '${dateFormat.format(firstDay)} - ${dateFormat.format(lastDay)}';
  }

  List<EnergyData> _convertHistoryToEnergyData(
    PowerClampDeviceHistoryLoaded state,
  ) {
    if (state.chartData.isEmpty) {
      return [];
    }

    return state.chartData.map<EnergyData>((item) {
      num consumption;
      if (widget.isGeneral) {
        consumption = item.energyConsumedKw;
      } else if (widget.phaseType.contains('Phase A')) {
        consumption = item.energyConsumedA;
      } else if (widget.phaseType.contains('Phase B')) {
        consumption = item.energyConsumedB;
      } else if (widget.phaseType.contains('Phase C')) {
        consumption = item.energyConsumedC;
      } else {
        consumption = item.energyConsumedKw;
      }

      return EnergyData(
        time: DateFormat('dd MMM').format(item.date),
        consumption: consumption.toDouble(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final energyConsumed = widget.isGeneral
        ? widget.generalData?.energyConsumed.toString() ?? '--'
        : widget.phaseData?.energyConsumed.toString() ?? '--';

    return DefaultContainer(
      child: Padding(
        padding: const EdgeInsets.only(
          left: 5,
          right: 5,
          top: 10,
          bottom: 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EnergyConsumptionHeader(
              title: widget.title,
              energyConsumption: energyConsumed,
            ),
            const SizedBox(height: 10),
            if (widget.isGeneral)
              GeneralMetricsSection(
                activePower: widget.generalData?.active ?? '--',
                current: widget.generalData?.current ?? '--',
                frequency: widget.generalData?.frequency ?? '--',
              )
            else
              PhaseMetricsSection(
                voltage: widget.phaseData?.voltage ?? '--',
                current: widget.phaseData?.current ?? '--',
                activePower: widget.phaseData?.activePower ?? '--',
                powerFactor: widget.phaseData?.powerFactor ?? '--',
              ),
            const SizedBox(height: 10),
            ConsumptionInfoSection(
              isGeneral: widget.isGeneral,
              phaseType: widget.phaseType,
              dateTimeSelected: _getDateRange(),
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<DateTime>(
              valueListenable: widget.selectedDateNotifier,
              builder: (context, selectedDate, _) {
                return BlocBuilder<
                  PowerClampDeviceHistoryBloc,
                  PowerClampDeviceHistoryState
                >(
                  builder: (context, state) {
                    return switch (state) {
                      PowerClampDeviceHistoryLoading() => const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      PowerClampDeviceHistoryFailure(:final errorMessage) =>
                        PowerClampFailureState(
                          message: errorMessage,
                          onRetry: _fetchHistoryData,
                        ),
                      PowerClampDeviceHistoryLoaded() => () {
                        final displayData = _convertHistoryToEnergyData(state);

                        if (displayData.isEmpty) {
                          return const PowerClampEmptyState();
                        }

                        return PowerClampChartSection(
                          chartData: displayData,
                          selectedDate: selectedDate,
                        );
                      }(),
                      _ => const PowerClampEmptyState(),
                    };
                  },
                );
              },
            ),
            const SizedBox(height: 30),
            ValueListenableBuilder<DateTime>(
              valueListenable: widget.selectedDateNotifier,
              builder: (context, selectedDate, _) {
                return MonthYearSelector(
                  selectedDate: selectedDate,
                  onDateChanged: (newDate) {
                    widget.selectedDateNotifier.value = newDate;
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
