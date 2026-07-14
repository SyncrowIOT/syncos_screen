import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncos_screen/utils/responsive/app_scale.dart';

void main() {
  Future<double> pumpScale(WidgetTester tester, Size size) async {
    double? scale;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            scale = context.shortestSideScaleFactor;
            return const SizedBox();
          },
        ),
      ),
    );
    return scale!;
  }

  testWidgets('scale is 1.0 at the reference shortest side', (tester) async {
    final scale = await pumpScale(
      tester,
      const Size(
        kDesignReferenceShortestSide,
        kDesignReferenceShortestSide * 1.5,
      ),
    );
    expect(scale, closeTo(1.0, 0.001));
  });

  testWidgets(
    'scale is clamped to kLegibilityFloorScale on a very small screen',
    (
      tester,
    ) async {
      final scale = await pumpScale(tester, const Size(200, 320));
      expect(scale, kLegibilityFloorScale);
    },
  );

  testWidgets(
    'scale is clamped to kLayoutCeilingScale on a very large screen',
    (
      tester,
    ) async {
      final scale = await pumpScale(tester, const Size(2000, 2600));
      expect(scale, kLayoutCeilingScale);
    },
  );

  testWidgets('scale follows the shortest side, not the longest', (
    tester,
  ) async {
    final portrait = await pumpScale(tester, const Size(600, 1200));
    final landscape = await pumpScale(tester, const Size(1200, 600));
    expect(portrait, equals(landscape));
  });

  testWidgets('num.scaledBy scales a literal by the current context scale', (
    tester,
  ) async {
    double? scaledValue;
    tester.view.physicalSize = const Size(
      kDesignReferenceShortestSide * 2,
      kDesignReferenceShortestSide * 2,
    );
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            scaledValue = 10.scaledBy(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(scaledValue, 10 * kLayoutCeilingScale);
  });
}
