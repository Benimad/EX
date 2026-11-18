import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myex_app/core/design/design.dart';

void main() {
  group('spring curves (spec §13)', () {
    test('every spring starts at 0 and settles at 1', () {
      for (final c in [
        MyExCurves.smooth,
        MyExCurves.snappy,
        MyExCurves.bouncy,
      ]) {
        expect(c.transform(0), closeTo(0, 1e-9));
        expect(c.transform(1), 1);
      }
    });

    double peak(Curve c) {
      var m = 0.0;
      for (var i = 0; i <= 200; i++) {
        final v = c.transform(i / 200);
        if (v > m) m = v;
      }
      return m;
    }

    test('smooth is critically damped (no overshoot)', () {
      expect(peak(MyExCurves.smooth), lessThanOrEqualTo(1.0 + 1e-6));
    });

    test('snappy overshoots slightly (~1.5%)', () {
      final p = peak(MyExCurves.snappy);
      expect(p, greaterThan(1.0));
      expect(p, lessThan(1.04));
    });

    test('bouncy overshoots clearly (~12%) and only for success moments', () {
      final p = peak(MyExCurves.bouncy);
      expect(p, greaterThan(1.08));
      expect(p, lessThan(1.18));
    });
  });

  testWidgets('Reduce Motion: no selection slides, no bounce, no loops', (
    tester,
  ) async {
    late MyExMotion m;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            m = MyExMotion.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(m.reduced, isTrue);
    expect(m.snappy, Duration.zero);
    expect(m.bouncy, Duration.zero);
    expect(m.smooth, MyExDurations.reducedFade);
    expect(m.pressScale, 1.0);
    expect(m.allowLoops, isFalse);
    expect(m.allowPresentingScale, isFalse);
  });

  test('display serif is upright and only weight 400', () {
    expect(MyExType.display.fontStyle, FontStyle.normal);
    expect(MyExType.display.fontWeight, FontWeight.w400);
    expect(MyExType.display.fontFamily, MyExFonts.serif);
    // UI text uses the platform system font (no bundled sans).
    expect(MyExType.body.fontFamily, isNull);
  });
}
