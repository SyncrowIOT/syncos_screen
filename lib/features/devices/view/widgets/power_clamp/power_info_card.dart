import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:syncos_screen/features/shared_widgets/default_container.dart';
import 'package:syncos_screen/utils/resource_manager/color_manager.dart';

class PowerClampInfoCard extends StatelessWidget {
  const PowerClampInfoCard({
    required this.iconPath,
    required this.title,
    required this.value,
    required this.unit,
    super.key,
  });

  final String iconPath;
  final String title;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DefaultContainer(
        height: 55,
        color: ColorsManager.grayBox,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: SvgPicture.asset(
                iconPath,
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: context.appTheme.typography.body.medium,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        value,
                        style: context.appTheme.typography.body.medium,
                      ),
                      Text(
                        unit,
                        style: context.appTheme.typography.body.medium,
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
