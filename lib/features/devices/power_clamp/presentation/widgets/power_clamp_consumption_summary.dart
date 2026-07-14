import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:power_clamp_device_history/power_clamp_device_history.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/helpers/power_clamp_date_range_formatter.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/helpers/power_clamp_energy_data_mapper.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/widgets/power_clamp_consumption_info_section.dart';

class PowerClampConsumptionSummary extends StatelessWidget {
  const PowerClampConsumptionSummary({
    required this.isGeneral,
    required this.phaseType,
    required this.selectedDate,
    super.key,
  });

  final bool isGeneral;
  final String phaseType;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      PowerClampDeviceHistoryBloc,
      PowerClampDeviceHistoryState
    >(
      builder: (context, historyState) {
        return PowerClampConsumptionInfoSection(
          isGeneral: isGeneral,
          phaseType: phaseType,
          dateTimeSelected: PowerClampDateRangeFormatter.monthRange(
            selectedDate,
          ),
          energyConsumed: historyState is PowerClampDeviceHistoryLoaded
              ? PowerClampEnergyDataMapper.totalConsumption(
                  PowerClampEnergyDataMapper.map(
                    historyState,
                    isGeneral: isGeneral,
                    phaseType: phaseType,
                  ),
                )
              : 0,
        );
      },
    );
  }
}
