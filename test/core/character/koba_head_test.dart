import 'package:cobalagi/core/character/koba_head.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final still in [false, true]) {
    testWidgets(
      'Koba looks where it is told${still ? ', reduced motion' : ''}',
      (tester) async {
        Widget head(Offset? at) => MediaQuery(
          data: MediaQueryData(disableAnimations: still),
          child: Center(child: KobaHead(size: 56, lookAt: at)),
        );
        await tester.pumpWidget(head(null));
        await tester.pumpWidget(head(const Offset(0, 0)));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpWidget(head(const Offset(800, 600)));
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        expect(find.byType(KobaHead), findsOneWidget);
        // It only repaints while its eyes move: at rest nothing runs.
        expect(tester.hasRunningAnimations, isFalse);
      },
    );
  }

  for (final still in [false, true]) {
    testWidgets(
      'Koba follows touch and the focused control${still ? ', reduced motion' : ''}',
      (tester) async {
        final focus = FocusNode();
        addTearDown(focus.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: still),
              child: Column(
                children: [
                  const KobaHead.follow(size: 56),
                  Focus(focusNode: focus, child: const SizedBox(height: 64)),
                ],
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tapAt(const Offset(700, 500));
        await tester.pump();
        // A touch sets the eyes gliding (they jump with reduced motion).
        expect(tester.hasRunningAnimations, !still);
        await tester.pump(const Duration(milliseconds: 500));
        focus.requestFocus();
        await tester.pump(const Duration(milliseconds: 500));
        // The touch fades after a moment and Koba looks ahead again.
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(tester.hasRunningAnimations, isFalse);
        // It stops listening once gone.
        await tester.pumpWidget(const SizedBox());
        await tester.tapAt(const Offset(10, 10));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
