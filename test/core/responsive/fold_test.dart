import 'dart:async';
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:cobalagi/core/responsive/fold.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

MediaQueryData _screen(Size size, List<DisplayFeature> features) =>
    MediaQueryData(size: size, displayFeatures: features);

DisplayFeature _fold(Rect bounds, DisplayFeatureState state) =>
    DisplayFeature(bounds: bounds, type: DisplayFeatureType.fold, state: state);

void main() {
  group('FoldHalves', () {
    test('a flat or folded-shut screen has no halves', () {
      const size = Size(669, 951);
      const line = Rect.fromLTWH(0, 475, 669, 0);
      expect(FoldHalves.fromMediaQuery(_screen(size, [])), isNull);
      expect(
        FoldHalves.fromMediaQuery(
          _screen(size, [_fold(line, DisplayFeatureState.postureFlat)]),
        ),
        isNull,
      );
    });

    test('on a table: the world above, the controls below the fold', () {
      final halves = FoldHalves.fromMediaQuery(
        _screen(const Size(669, 951), [
          _fold(
            const Rect.fromLTWH(0, 475, 669, 0),
            DisplayFeatureState.postureHalfOpened,
          ),
        ]),
      )!;
      expect(halves.view, const Rect.fromLTRB(0, 0, 669, 475 - foldClearance));
      expect(
        halves.controls,
        const Rect.fromLTRB(0, 475 + foldClearance, 669, 951),
      );
    });

    test('like a book: the world left, the controls right of the fold', () {
      final halves = FoldHalves.fromMediaQuery(
        _screen(const Size(951, 669), [
          _fold(
            const Rect.fromLTWH(475, 0, 0, 669),
            DisplayFeatureState.postureHalfOpened,
          ),
        ]),
      )!;
      expect(halves.view.right, 475 - foldClearance);
      expect(halves.controls.left, 475 + foldClearance);
      expect(halves.controls.contains(halves.anchor), isTrue);
    });

    test('a hinge between two screens always splits', () {
      final halves = FoldHalves.fromMediaQuery(
        _screen(const Size(1114, 705), [
          const DisplayFeature(
            bounds: Rect.fromLTWH(540, 0, 34, 705),
            type: DisplayFeatureType.hinge,
            state: DisplayFeatureState.unknown,
          ),
        ]),
      );
      expect(halves?.controls.left, 574 + foldClearance);
    });
  });

  testWidgets('HingeFold puts the iPhone hinge across the long side', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(951, 669);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final hinge = StreamController<bool>();
    addTearDown(hinge.close);
    FoldHalves? halves;
    await tester.pumpWidget(
      HingeFold(
        halfOpen: hinge.stream,
        child: Builder(
          builder: (context) {
            halves = FoldHalves.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(halves, isNull);

    hinge.add(true);
    await tester.pump();
    await tester.pump();
    expect(halves?.view.right, 951 / 2 - foldClearance);

    hinge.add(false);
    await tester.pump();
    await tester.pump();
    expect(halves, isNull);
  });

  testWidgets('FoldHalf moves a screen into the flat half, keeping it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(669, 951);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final hinge = StreamController<bool>();
    addTearDown(hinge.close);
    final key = GlobalKey();
    await tester.pumpWidget(
      HingeFold(
        halfOpen: hinge.stream,
        child: FoldHalf(child: SizedBox.expand(key: key)),
      ),
    );
    final before = key.currentContext;
    expect(
      tester.getRect(find.byKey(key)),
      const Rect.fromLTWH(0, 0, 669, 951),
    );

    hinge.add(true);
    await tester.pump();
    await tester.pump();
    expect(
      tester.getRect(find.byKey(key)),
      const Rect.fromLTRB(0, 951 / 2 + foldClearance, 669, 951),
    );
    // The same element: the screen keeps its state as the phone folds.
    expect(key.currentContext, same(before));
  });
}
