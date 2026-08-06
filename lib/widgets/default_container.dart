import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:syncos_screen/utils/responsive/app_scale.dart';

class DefaultContainer extends StatelessWidget {
  const DefaultContainer({
    required this.child,
    super.key,
    this.height,
    this.width,
    this.color,
    this.boxConstraints,
    this.margin,
    this.padding,
    this.onTap,
    this.borderRadius,
  });

  final double? height;
  final double? width;
  final Widget child;
  final BoxConstraints? boxConstraints;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Color? color;
  final void Function()? onTap;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final resolvedBorderRadius =
        borderRadius ?? BorderRadius.all(Radius.circular(20.scaledBy(context)));
    return Material(
      type: MaterialType.card,
      borderRadius: resolvedBorderRadius,
      color: color ?? context.appTheme.colors.background.neutralPrimary,
      child: InkWell(
        onTap: onTap,
        borderRadius: resolvedBorderRadius,
        child: Container(
          height: height,
          width: width,
          constraints: boxConstraints,
          margin:
              margin ??
              EdgeInsets.only(
                right: 3.scaledBy(context),
                bottom: 3.scaledBy(context),
              ),
          padding: padding ?? EdgeInsets.all(10.scaledBy(context)),
          child: child,
        ),
      ),
    );
  }
}
