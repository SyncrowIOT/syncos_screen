import 'package:intl/intl.dart';
import 'package:power_clamp_device_history/power_clamp_device_history.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/widgets/power_clamp_chart.dart';

abstract final class PowerClampEnergyDataMapper {
  static List<EnergyData> map(
    PowerClampDeviceHistoryLoaded state, {
    required bool isGeneral,
    required String phaseType,
  }) {
    return state.chartData
        .map(
          (item) => EnergyData(
            time: DateFormat('dd MMM').format(item.date),
            consumption: _consumptionFor(
              item,
              isGeneral: isGeneral,
              phaseType: phaseType,
            ).toDouble(),
          ),
        )
        .toList();
  }

  static num _consumptionFor(
    DeviceEnergyDataModel item, {
    required bool isGeneral,
    required String phaseType,
  }) {
    if (isGeneral) {
      return item.energyConsumedKw;
    }
    if (phaseType.contains('Phase A')) {
      return item.energyConsumedA;
    }
    if (phaseType.contains('Phase B')) {
      return item.energyConsumedB;
    }
    if (phaseType.contains('Phase C')) {
      return item.energyConsumedC;
    }
    return item.energyConsumedKw;
  }
}
