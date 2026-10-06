import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/features/adventure_map/view/ocean_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

MapIsland island(String id, {bool current = false, bool locked = false}) =>
    MapIsland(
      conceptId: id,
      stars: current ? 1 : 0,
      solvedLessons: 1,
      totalLessons: 6,
      current: current,
      locked: locked,
    );

Future<List<String>> pumpMap(
  WidgetTester tester,
  Size size, {
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final opened = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
      home: Scaffold(
        body: OceanMap(
          marker: const Icon(Icons.face, key: Key('marker')),
          islands: [
            island('directions'),
            island('sequencing', current: true),
            island('loops', locked: true),
            island('functions', locked: true),
          ],
          onOpen: opened.add,
        ),
      ),
    ),
  );
  await tester.pump();
  return opened;
}

void main() {
  testWidgets('keyboard navigation opens only unlocked islands', (
    tester,
  ) async {
    final opened = await pumpMap(tester, const Size(1280, 740));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(opened, ['directions', 'sequencing', 'directions']);
  });

  testWidgets('reduced motion stops bobbing and responds to setting changes', (
    tester,
  ) async {
    final marker = find.byKey(const Key('marker'));
    await pumpMap(tester, const Size(1280, 740));
    final start = tester.getTopLeft(marker);
    await tester.pump(const Duration(milliseconds: 450));
    expect(tester.getTopLeft(marker).dy, lessThan(start.dy));

    await pumpMap(tester, const Size(1280, 740), disableAnimations: true);
    final still = tester.getTopLeft(marker);
    await tester.pump(const Duration(milliseconds: 450));
    expect(tester.getTopLeft(marker), still);
    expect(tester.hasRunningAnimations, isFalse);

    await pumpMap(tester, const Size(1280, 740));
    await tester.pump(const Duration(milliseconds: 450));
    expect(tester.getTopLeft(marker).dy, lessThan(still.dy));
  });

  for (final (name, size) in [
    ('tablet', const Size(1280, 740)),
    ('phone', const Size(400, 760)),
  ]) {
    testWidgets('on a $name, open islands open and locked ones stay shut', (
      tester,
    ) async {
      final opened = await pumpMap(tester, size);
      expect(find.byKey(const Key('marker')), findsOneWidget);
      expect(find.text('1/6'), findsNWidgets(4));
      // Fog on the two locked islands.
      expect(find.byIcon(Icons.cloud_rounded), findsNWidgets(2));

      await tester.tap(find.text('Step by step'));
      await tester.ensureVisible(find.text('Directions'));
      await tester.pump();
      await tester.tap(find.text('Directions'));
      await tester.ensureVisible(find.text('Loops'));
      await tester.pump();
      await tester.tap(find.text('Loops'));
      expect(opened, ['sequencing', 'directions']);
    });
  }
}
