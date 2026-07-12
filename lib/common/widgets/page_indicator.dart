import 'package:flutter/material.dart';
import 'package:syncos_screen/utils/resource_manager/color_manager.dart';

class PageIndicator extends StatelessWidget {
  const PageIndicator({
    required this.currentPageNotifier,
    required this.pageCount,
    this.activeColor,
    this.inactiveColor,
    this.dotSize,
    this.dotSpacing,
    this.padding,
    super.key,
  });

  final ValueNotifier<int> currentPageNotifier;
  final int pageCount;
  final Color? activeColor;
  final Color? inactiveColor;
  final double? dotSize;
  final double? dotSpacing;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 10),
      child: ValueListenableBuilder<int>(
        valueListenable: currentPageNotifier,
        builder: (context, currentPage, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pageCount, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(
                  horizontal: dotSpacing ?? 4,
                ),
                height: dotSize ?? 10,
                width: dotSize ?? 10,
                decoration: BoxDecoration(
                  color: currentPage == index
                      ? (activeColor ?? Colors.grey)
                      : (inactiveColor ?? ColorsManager.greyColor),
                  borderRadius: BorderRadius.circular((dotSize ?? 10) / 2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
