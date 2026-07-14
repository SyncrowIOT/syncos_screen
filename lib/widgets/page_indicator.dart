import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:syncos_screen/utils/responsive/app_scale.dart';

class PageIndicator extends StatelessWidget {
  const PageIndicator({
    required this.currentPageNotifier,
    required this.pageCount,
    this.activeColor,
    this.inactiveColor,
    this.dotSize = 10,
    this.dotSpacing,
    this.padding,
    super.key,
  });

  final ValueNotifier<int> currentPageNotifier;
  final int pageCount;
  final Color? activeColor;
  final Color? inactiveColor;
  final double dotSize;
  final double? dotSpacing;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final scaledDotSize = dotSize.s(context);
    return Padding(
      padding:
          padding ?? EdgeInsets.symmetric(vertical: 10.s(context)),
      child: ValueListenableBuilder<int>(
        valueListenable: currentPageNotifier,
        builder: (context, currentPage, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pageCount, (index) {
              final isActive = currentPage == index;
              final color = isActive
                  ? activeColor ?? context.appTheme.colors.text.title
                  : inactiveColor ?? context.appTheme.colors.text.bodySubtle;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(
                  horizontal: (dotSpacing ?? 4).s(context),
                ),
                height: scaledDotSize,
                width: scaledDotSize,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(scaledDotSize / 2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
