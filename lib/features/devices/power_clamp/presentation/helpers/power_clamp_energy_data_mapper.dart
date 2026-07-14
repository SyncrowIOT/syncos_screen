import 'package:intl/intl.dart';
import 'package:power_clamp_device_history/power_clamp_device_history.dart';
import 'package:syncos_screen/features/devices/power_clamp/domain/power_clamp_energy_calculator.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/widgets/power_clamp_chart.dart';

abstract final class PowerClampEnergyDataMapper {
  static List<EnergyData> map(
    PowerClampDeviceHistoryLoaded state, {
    required bool isGeneral,
    required String phaseType,
  }) {
    return PowerClampEnergyCalculator.readings(
      state,
      isGeneral: isGeneral,
      phaseType: phaseType,
    ).map((reading) {
      return EnergyData(
        time: DateFormat('dd MMM').format(reading.date),
        consumption: reading.consumption,
      );
    }).toList();
  }

  static double totalConsumption(List<EnergyData> data) {
    return data.fold(0, (sum, item) => sum + item.consumption);
  }
}
