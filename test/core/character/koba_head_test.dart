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
        // Nothing keeps rebuilding: it only repaints while it watches.
        expect(tester.hasRunningAnimations, !still);
      },
    );
  }
}
