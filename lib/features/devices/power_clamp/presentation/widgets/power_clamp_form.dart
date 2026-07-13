import 'package:device_manager/device_manager.dart';
import 'package:devices/devices.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/widgets/power_clamp_chart.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/widgets/power_clamp_phase_pages.dart';
import 'package:syncos_screen/widgets/page_indicator.dart';

class PowerClampForm extends StatefulWidget {
  const PowerClampForm({required this.device, super.key});

  final Device device;

  @override
  State<PowerClampForm> createState() => _PowerClampFormState();
}

class _PowerClampFormState extends State<PowerClampForm> {
  final _pageController = PageController();
  final _currentPageNotifier = ValueNotifier<int>(0);
  final _selectedDateNotifier = ValueNotifier<DateTime>(DateTime.now());
  static const _pageCount = 4;

  @override
  void initState() {
    _pageController.addListener(_handlePageChange);
    super.initState();
  }

  void _handlePageChange() {
    final nextPage = _pageController.page?.round() ?? 0;
    _currentPageNotifier.value = nextPage;
  }

  @override
  void dispose() {
    context.read<DevicesManagerBloc<PowerClampStatusModel>>().add(
      const StopListeningEvent(),
    );
    _pageController
      ..removeListener(_handlePageChange)
      ..dispose();
    _currentPageNotifier.dispose();
    _selectedDateNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      DevicesManagerBloc<PowerClampStatusModel>,
      DevicesManagerState<PowerClampStatusModel>
    >(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.device.name),
          ),
          body: Column(
            children: [
              Expanded(
                child: PowerClampPhasePages(
                  device: widget.device,
                  powerClampModel: state.device,
                  pageController: _pageController,
                  chartData: const <EnergyData>[],
                  selectedDateNotifier: _selectedDateNotifier,
                ),
              ),
              PageIndicator(
                currentPageNotifier: _currentPageNotifier,
                pageCount: _pageCount,
              ),
            ],
          ),
        );
      },
    );
  }
}
