import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:power_clamp_device_history/power_clamp_device_history.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/helpers/power_clamp_energy_data_mapper.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/widgets/power_clamp_chart_section.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/widgets/power_clamp_empty_state.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/widgets/power_clamp_failure_state.dart';

class PowerClampHistorySection extends StatelessWidget {
  const PowerClampHistorySection({
    required this.isGeneral,
    required this.phaseType,
    required this.selectedDate,
    required this.onRetry,
    super.key,
  });

  final bool isGeneral;
  final String phaseType;
  final DateTime selectedDate;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      PowerClampDeviceHistoryBloc,
      PowerClampDeviceHistoryState
    >(
      builder: (context, state) {
        return switch (state) {
          PowerClampDeviceHistoryLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          PowerClampDeviceHistoryFailure(:final errorMessage) =>
            PowerClampFailureState(message: errorMessage, onRetry: onRetry),
          PowerClampDeviceHistoryLoaded() => _buildLoaded(state),
          _ => const PowerClampEmptyState(),
        };
      },
    );
  }

  Widget _buildLoaded(PowerClampDeviceHistoryLoaded state) {
    final displayData = PowerClampEnergyDataMapper.map(
      state,
      isGeneral: isGeneral,
      phaseType: phaseType,
    );

    if (displayData.isEmpty) {
      return const PowerClampEmptyState();
    }

    return PowerClampChartSection(
      chartData: displayData,
      selectedDate: selectedDate,
    );
  }
}
