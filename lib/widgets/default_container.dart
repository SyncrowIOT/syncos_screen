import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class DefaultContainer extends StatelessWidget {
  const DefaultContainer({
    required this.child,
    super.key,
    this.height,
    this.width,
    this.color,
    this.boxConstraints,
    this.margin = const EdgeInsets.only(right: 3, bottom: 3),
    this.padding = const EdgeInsets.all(10),
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  final double? height;
  final double? width;
  final Widget child;
  final BoxConstraints? boxConstraints;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final Color? color;
  final void Function()? onTap;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.card,
      borderRadius: borderRadius,
      color: color ?? context.appTheme.colors.background.neutralPrimary,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          height: height,
          width: width,
          constraints: boxConstraints,
          margin: margin,
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
