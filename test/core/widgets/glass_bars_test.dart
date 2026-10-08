import 'package:cobalagi/core/widgets/glass_app_bar.dart';
import 'package:cobalagi/core/widgets/glass_bar.dart';
import 'package:cobalagi/core/widgets/glass_frame.dart';
import 'package:cobalagi/core/widgets/glass_popups.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

/// Whether the [GlassBar] on [edge] currently shows its glass.
bool frosted(WidgetTester tester, GlassEdge edge) {
  final blur = find.descendant(
    of: find.byWidgetPredicate((w) => w is GlassBar && w.edge == edge),
    matching: find.byType(LiquidGlassScrollEdge),
  );
  // Never inside an opacity layer: it fades by its own blur and tint.
  expect(
    find.ancestor(of: blur, matching: find.byType(AnimatedOpacity)),
    findsNothing,
  );
  return blur.evaluate().isNotEmpty;
}

void main() {
  testWidgets('frame bars frost only while content is under them', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlassFrame(
            top: const SizedBox(height: 80),
            bottom: const SizedBox(key: Key('bottom'), height: 80),
            builder: (context, insets) => ListView(
              padding: insets,
              children: [
                for (var i = 0; i < 30; i++)
                  SizedBox(height: 50, child: Text('row $i')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Bar content spans the bar, so centred content stays centred.
    expect(tester.getSize(find.byKey(const Key('bottom'))).width, 400);
    // The first row starts below the top bar; more rows wait below.
    expect(tester.getTopLeft(find.text('row 0')).dy, 80);
    expect(frosted(tester, GlassEdge.top), isFalse);
    expect(frosted(tester, GlassEdge.bottom), isTrue);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(frosted(tester, GlassEdge.top), isTrue);
    expect(frosted(tester, GlassEdge.bottom), isTrue);

    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pumpAndSettle();
    expect(frosted(tester, GlassEdge.top), isTrue);
    expect(frosted(tester, GlassEdge.bottom), isFalse);
    // The last row ends above the bottom bar.
    expect(
      tester.getBottomLeft(find.text('row 29')).dy,
      lessThan(600 - 80 + 1),
    );
  });

  testWidgets('the app bar frosts once the page scrolls under it', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            extendBodyBehindAppBar: true,
            appBar: const GlassAppBar(title: Text('Title')),
            body: Builder(
              builder: (context) => ListView(
                padding: belowBars(context, EdgeInsets.zero),
                children: [
                  for (var i = 0; i < 40; i++)
                    SizedBox(height: 50, child: Text('row $i')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getTopLeft(find.text('row 0')).dy,
      greaterThanOrEqualTo(kToolbarHeight),
    );
    expect(frosted(tester, GlassEdge.top), isFalse);
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(frosted(tester, GlassEdge.top), isTrue);
    await tester.drag(find.byType(ListView), const Offset(0, 1000));
    await tester.pumpAndSettle();
    expect(frosted(tester, GlassEdge.top), isFalse);
  });

  for (final highContrast in [false, true]) {
    testWidgets(
      'dialogs blur the screen unless high contrast ($highContrast)',
      (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(highContrast: highContrast);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => showGlassDialog<void>(
                  context: context,
                  builder: (_) => const AlertDialog(content: Text('hello')),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        );
        expect(find.byType(BackdropFilter), findsNothing);
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.text('hello'), findsOneWidget);
        expect(
          find.byType(BackdropFilter),
          highContrast ? findsNothing : findsOneWidget,
        );
      },
    );
  }
}
