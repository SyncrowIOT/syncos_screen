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
          left: 5.scaledBy(context),
          right: 5.scaledBy(context),
          top: 10.scaledBy(context),
          bottom: 10.scaledBy(context),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 900.scaledBy(context)),
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
