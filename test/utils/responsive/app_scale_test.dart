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
            scale = context.scale;
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
      const Size(kBaseShortestSide, kBaseShortestSide * 1.5),
    );
    expect(scale, closeTo(1.0, 0.001));
  });

  testWidgets('scale is clamped to kMinScale on a very small screen', (
    tester,
  ) async {
    final scale = await pumpScale(tester, const Size(200, 320));
    expect(scale, kMinScale);
  });

  testWidgets('scale is clamped to kMaxScale on a very large screen', (
    tester,
  ) async {
    final scale = await pumpScale(tester, const Size(2000, 2600));
    expect(scale, kMaxScale);
  });

  testWidgets('scale follows the shortest side, not the longest', (
    tester,
  ) async {
    final portrait = await pumpScale(tester, const Size(600, 1200));
    final landscape = await pumpScale(tester, const Size(1200, 600));
    expect(portrait, equals(landscape));
  });

  testWidgets('num.s scales a literal by the current context scale', (
    tester,
  ) async {
    double? scaledValue;
    tester.view.physicalSize = const Size(
      kBaseShortestSide * 2,
      kBaseShortestSide * 2,
    );
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            scaledValue = 10.s(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(scaledValue, 10 * kMaxScale);
  });
}
