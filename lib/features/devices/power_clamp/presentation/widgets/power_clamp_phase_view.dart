import 'package:device_manager/device_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:power_clamp_device_history/power_clamp_device_history.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/widgets/power_clamp_consumption_summary.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/widgets/power_clamp_energy_consumption_header.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/widgets/power_clamp_general_metrics_section.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/widgets/power_clamp_history_section.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/widgets/power_clamp_phase_metrics_section.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/widgets/power_clamp_scrollable_section.dart';
import 'package:syncos_screen/utils/responsive/app_scale.dart';
import 'package:syncos_screen/widgets/month_year_selector.dart';

class PowerClampPhaseView extends StatefulWidget {
  const PowerClampPhaseView({
    required this.deviceUuid,
    required this.title,
    required this.phaseType,
    required this.isGeneral,
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

  @override
  Widget build(BuildContext context) {
    final energyConsumed = widget.isGeneral
        ? widget.generalData?.energyConsumed.toString() ?? '--'
        : widget.phaseData?.energyConsumed.toString() ?? '--';

    return PowerClampScrollableSection(
      children: [
        PowerClampEnergyConsumptionHeader(
          title: widget.title,
          energyConsumption: energyConsumed,
        ),
        SizedBox(height: 10.s(context)),
        if (widget.isGeneral)
          PowerClampGeneralMetricsSection(
            activePower: widget.generalData?.active ?? '--',
            current: widget.generalData?.current ?? '--',
            frequency: widget.generalData?.frequency ?? '--',
          )
        else
          PowerClampPhaseMetricsSection(
            voltage: widget.phaseData?.voltage ?? '--',
            current: widget.phaseData?.current ?? '--',
            activePower: widget.phaseData?.activePower ?? '--',
            powerFactor: widget.phaseData?.powerFactor ?? '--',
          ),
        SizedBox(height: 10.s(context)),
        PowerClampConsumptionSummary(
          isGeneral: widget.isGeneral,
          phaseType: widget.phaseType,
          selectedDate: widget.selectedDateNotifier.value,
        ),
        SizedBox(height: 10.s(context)),
        SizedBox(
          height: 220.s(context),
          child: ValueListenableBuilder<DateTime>(
            valueListenable: widget.selectedDateNotifier,
            builder: (context, selectedDate, _) {
              return PowerClampHistorySection(
                isGeneral: widget.isGeneral,
                phaseType: widget.phaseType,
                selectedDate: selectedDate,
                onRetry: _fetchHistoryData,
              );
            },
          ),
        ),
        SizedBox(height: 30.s(context)),
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
    );
  }
}
