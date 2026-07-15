import 'package:device_manager/device_manager.dart';
import 'package:devices/devices.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/widgets/power_clamp_form.dart';

class PowerClampView extends StatefulWidget {
  const PowerClampView({required this.device, super.key});

  final Device device;

  @override
  State<PowerClampView> createState() => _PowerClampViewState();
}

class _PowerClampViewState extends State<PowerClampView> {
  final _pageController = PageController();
  final _currentPageNotifier = ValueNotifier<int>(0);
  final _selectedDateNotifier = ValueNotifier<DateTime>(DateTime.now());

  late DevicesManagerBloc<PowerClampStatusModel> _devicesManagerBloc;

  @override
  void initState() {
    _pageController.addListener(_handlePageChange);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _devicesManagerBloc = context
        .read<DevicesManagerBloc<PowerClampStatusModel>>();
  }

  void _handlePageChange() {
    final nextPage = _pageController.page?.round() ?? 0;
    _currentPageNotifier.value = nextPage;
  }

  @override
  void dispose() {
    _devicesManagerBloc.add(const StopListeningEvent());
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
        return PowerClampForm(
          device: widget.device,
          powerClampModel: state.device,
          pageController: _pageController,
          currentPageNotifier: _currentPageNotifier,
          selectedDateNotifier: _selectedDateNotifier,
        );
      },
    );
  }
}
