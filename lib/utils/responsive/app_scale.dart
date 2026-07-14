import 'package:flutter/widgets.dart';

const double kDesignReferenceShortestSide = 600;

const double kLegibilityFloorScale = 0.75;
const double kLayoutCeilingScale = 1.6;

extension AppScale on BuildContext {
  double get shortestSideScaleFactor {
    final shortestSide = MediaQuery.sizeOf(this).shortestSide;
    return (shortestSide / kDesignReferenceShortestSide).clamp(
      kLegibilityFloorScale,
      kLayoutCeilingScale,
    );
  }
}

extension ResponsiveNum on num {
  double scaledBy(BuildContext context) =>
      this * context.shortestSideScaleFactor;
}

extension ResponsiveTextStyle on TextStyle {
  TextStyle scaledFontSize(BuildContext context) =>
      copyWith(fontSize: (fontSize ?? 14) * context.shortestSideScaleFactor);
}
