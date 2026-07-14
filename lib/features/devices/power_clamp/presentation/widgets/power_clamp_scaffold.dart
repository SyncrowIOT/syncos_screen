import 'package:devices/devices.dart';
import 'package:flutter/material.dart';

class PowerClampScaffold extends StatelessWidget {
  const PowerClampScaffold({
    required this.device,
    required this.body,
    super.key,
  });

  final Device device;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
      ),
      body: body,
    );
  }
}
