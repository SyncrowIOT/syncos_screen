import 'package:flutter/material.dart';
import 'package:syncos_screen/utils/responsive/app_scale.dart';
import 'package:syncos_screen/widgets/default_container.dart';

class PowerClampScrollableSection extends StatelessWidget {
  const PowerClampScrollableSection({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DefaultContainer(
      child: Padding(
        padding: EdgeInsets.only(
          left: 5.s(context),
          right: 5.s(context),
          top: 10.s(context),
          bottom: 10.s(context),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 900.s(context)),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
