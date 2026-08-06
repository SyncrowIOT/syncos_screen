import 'package:device_manager/device_manager.dart';
import 'package:devices/devices.dart';
import 'package:flutter/material.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/widgets/power_clamp_phase_pages.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/widgets/power_clamp_scaffold.dart';
import 'package:syncos_screen/widgets/page_indicator.dart';

class PowerClampForm extends StatelessWidget {
  const PowerClampForm({
    required this.device,
    required this.powerClampModel,
    required this.pageController,
    required this.currentPageNotifier,
    required this.selectedDateNotifier,
    super.key,
  });

  static const _pageCount = 4;

  final Device device;
  final PowerClampStatusModel? powerClampModel;
  final PageController pageController;
  final ValueNotifier<int> currentPageNotifier;
  final ValueNotifier<DateTime> selectedDateNotifier;

  @override
  Widget build(BuildContext context) {
    return PowerClampScaffold(
      device: device,
      body: Column(
        children: [
          Expanded(
            child: PowerClampPhasePages(
              device: device,
              powerClampModel: powerClampModel,
              pageController: pageController,
              selectedDateNotifier: selectedDateNotifier,
            ),
          ),
          PageIndicator(
            currentPageNotifier: currentPageNotifier,
            pageCount: _pageCount,
          ),
        ],
      ),
    );
  }
}
