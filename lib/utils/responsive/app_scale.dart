import 'package:flutter/widgets.dart';

/// Reference design canvas: the shortest-side size the current fixed-px UI
/// was tuned for. This is the "1.0x" baseline every scaled literal assumes,
/// not a target device resolution.
const double kBaseShortestSide = 600;

/// Clamp bounds so an unknown small panel doesn't shrink text below
/// legibility, and an unknown large panel doesn't blow spacing up so much
/// the layout looks broken. Revisit once real panel resolutions are known.
const double kMinScale = 0.75;
const double kMaxScale = 1.6;

extension AppScale on BuildContext {
  /// Scale factor derived from the shortest side of the current screen vs
  /// the reference canvas, clamped to [kMinScale, kMaxScale].
  double get scale {
    final shortestSide = MediaQuery.sizeOf(this).shortestSide;
    return (shortestSide / kBaseShortestSide).clamp(kMinScale, kMaxScale);
  }
}

extension ResponsiveNum on num {
  /// Scales a design literal (spacing, size, font) by the current screen's
  /// [AppScale.scale], e.g. `8.s(context)`.
  double s(BuildContext context) => this * context.scale;
}

extension ResponsiveTextStyle on TextStyle {
  /// Scales this style's fontSize by the current screen's [AppScale.scale],
  /// leaving weight/color/letterSpacing/height untouched.
  TextStyle scaled(BuildContext context) =>
      copyWith(fontSize: (fontSize ?? 14) * context.scale);
}
