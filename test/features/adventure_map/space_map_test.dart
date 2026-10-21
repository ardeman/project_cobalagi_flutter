import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/features/adventure_map/view/space_map.dart';
import 'package:cobalagi/features/story/data/story_art.dart';
import 'package:cobalagi/features/story/view/ship_flight.dart';
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
        body: SpaceMap(
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

/// Lets a [ShipFlight.hop] load its pictures, fly and land.
Future<void> flyShip(WidgetTester tester) async {
  await tester.pump();
  // The loaded pictures reach the flight on the real event loop.
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
  await tester.pump(ShipFlight.hopDuration);
  await tester.pump();
}

void main() {
  // Loaded once on the real event loop: a load started inside a test's fake
  // clock never finishes for the tests after it.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await StoryArt.load();
  });

  testWidgets('Koba\'s ship stands on the current planet', (tester) async {
    await pumpMap(tester, const Size(1280, 740));
    final ship = tester.widget<ParkedShip>(find.byType(ParkedShip));
    // On the current planet, whose name sits below its centre.
    final name = tester.getCenter(find.text('Step by step'));
    expect(ship.centre.dx, closeTo(name.dx, 1));
    expect(name.dy, greaterThan(ship.centre.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard navigation opens only unlocked islands', (
    tester,
  ) async {
    // Without animations the ship's trips don't wait.
    final opened = await pumpMap(
      tester,
      const Size(1280, 740),
      disableAnimations: true,
    );

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

  for (final (name, size) in [
    ('tablet', const Size(1280, 740)),
    ('phone', const Size(400, 760)),
  ]) {
    testWidgets('on a $name, open islands open and locked ones stay shut', (
      tester,
    ) async {
      final opened = await pumpMap(tester, size);
      // Koba's ship stands on the current planet.
      expect(find.byType(ParkedShip), findsOneWidget);
      expect(find.text('1/6'), findsNWidgets(4));
      // Fog on the two locked islands.
      expect(find.byIcon(Icons.cloud_rounded), findsNWidgets(2));

      // The ship is already on the current planet: it opens at once.
      await tester.tap(find.text('Step by step'));
      expect(opened, ['sequencing']);
      await tester.ensureVisible(find.text('Directions'));
      await tester.pump();
      await tester.tap(find.text('Directions'));
      await flyShip(tester);
      expect(opened, ['sequencing', 'directions']);
      await tester.ensureVisible(find.text('Loops'));
      await tester.pump();
      await tester.tap(find.text('Loops'));
      await tester.pump();
      expect(find.byType(ShipFlight), findsNothing);
      expect(opened, ['sequencing', 'directions']);
    });
  }

  testWidgets('the ship flies to an opened planet, and back for Play', (
    tester,
  ) async {
    final opened = await pumpMap(tester, const Size(1280, 740));
    Offset shipAt() =>
        tester.widget<ParkedShip>(find.byType(ParkedShip)).centre;
    final home = shipAt();

    await tester.tap(find.text('Directions'));
    await tester.pump();
    // It flies first, and the planet opens once it lands there.
    expect(find.byType(ParkedShip), findsNothing);
    expect(opened, isEmpty);
    await flyShip(tester);
    expect(opened, ['directions']);
    final visited = shipAt();
    expect(visited, isNot(home));
    expect(find.byType(ShipFlight), findsNothing);

    // Play flies it back to the current planet before the puzzle starts.
    var played = false;
    tester
        .state<SpaceMapState>(find.byType(SpaceMap))
        .flyHome(() => played = true);
    await tester.pump();
    expect(played, isFalse);
    await flyShip(tester);
    expect(played, isTrue);
    expect(shipAt(), home);

    // From home, Play starts at once.
    played = false;
    tester
        .state<SpaceMapState>(find.byType(SpaceMap))
        .flyHome(() => played = true);
    expect(played, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a phone held sideways shows one big row it can scroll', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(840, 380);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final ids = [
      'directions', 'sequencing', 'loops', 'functions', //
      'conditions', 'variables', 'debugging', 'until',
    ];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SpaceMap(
            islands: [
              for (final id in ids)
                island(id, current: id == 'variables', locked: id == 'until'),
            ],
            onOpen: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    // One row, big enough to read, scrolling sideways.
    final scroll = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(scroll.scrollDirection, Axis.horizontal);
    final names = [
      for (final n in ['Loops', 'Step Box']) find.text(n),
    ];
    final tops = {
      for (final n in names)
        if (n.evaluate().isNotEmpty) tester.getTopLeft(n).dy.round(),
    };
    expect(tops, hasLength(1), reason: 'all labels on one line');
    final current = tester.getCenter(find.text('Step Box'));
    // The current island starts in the middle of the screen.
    expect(current.dx, closeTo(420, 60));
    expect(tester.getSize(find.text('Step Box')).height, greaterThan(14));
    expect(tester.takeException(), isNull);
  });

  for (final still in [false, true]) {
    testWidgets('a newly reached island opens with stars (still: $still)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: still),
            child: child!,
          ),
          home: Scaffold(
            body: SpaceMap(
              islands: [
                island('directions'),
                MapIsland(
                  conceptId: 'sequencing',
                  stars: 0,
                  solvedLessons: 0,
                  totalLessons: 6,
                  current: true,
                  locked: false,
                  unlocking: true,
                ),
                island('loops', locked: true),
              ],
              onOpen: (_) {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      // Stars burst and the lock lifts, unless motion is reduced.
      final stars = find.byIcon(Icons.star_rounded).evaluate().length;
      final locks = find.byIcon(Icons.lock_rounded).evaluate().length;
      if (still) {
        expect(locks, 1, reason: 'only the locked island');
      } else {
        expect(locks, 2, reason: 'the lifting lock as well');
        expect(stars, greaterThanOrEqualTo(10));
      }
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a tablet held sideways keeps islands apart and scrolls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final ids = [
      'warmup', 'directions', 'sequencing', 'loops', 'functions', //
      'conditions', 'variables', 'debugging', 'until', 'otherwise',
    ];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SpaceMap(
            padding: const EdgeInsets.only(top: 96, bottom: 96),
            islands: [
              for (final id in ids)
                island(id, current: id == 'functions', locked: false),
            ],
            onOpen: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    final scroll = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(scroll.scrollDirection, Axis.horizontal);
    // Neighbours sit on alternate rows, far enough apart to read.
    final loops = tester.getCenter(find.text('Loops'));
    final magic = tester.getCenter(find.text('Magic Block'));
    expect(loops.dy, isNot(moreOrLessEquals(magic.dy, epsilon: 4)));
    expect((magic.dx - loops.dx).abs(), greaterThanOrEqualTo(180));
    // It opens on the current island.
    expect(magic.dx, inInclusiveRange(400, 880));
  });
}
