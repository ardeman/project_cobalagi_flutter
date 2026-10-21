// Drives the real app from a fresh install the way a child and a parent use
// it: add a player, the first warm-up, the story, the map, a planet's demo,
// a lesson solved with blocks, and the parent area behind the parent gate.
// Prints a marker at each step and a screenshot of the key screens.
//
//   flutter test integration_test/app_flow_test.dart -d <device> > run.log
//   dart run tool/collect_screenshots.dart run.log <folder>
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:cobalagi/app/app.dart';
import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/core/entitlement/entitlement_service.dart';
import 'package:cobalagi/core/entitlement/plan.dart';
import 'package:cobalagi/core/settings/settings_repository.dart';
import 'package:cobalagi/core/widgets/coach_tour.dart';
import 'package:cobalagi/engine/generator/solver.dart';
import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/features/editors/blocks/view/block_editor.dart';
import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/features/adventure_map/view/adventure_map_screen.dart';
import 'package:cobalagi/features/adventure_map/view/island_screen.dart';
import 'package:cobalagi/features/learning/cubit/learning_cubit.dart';
import 'package:cobalagi/features/learning/data/curriculum_repository.dart';
import 'package:cobalagi/features/learning/view/concepts.dart';
import 'package:cobalagi/features/parent/view/parent_screen.dart';
import 'package:cobalagi/features/play/view/play_screen.dart';
import 'package:cobalagi/features/profiles/view/profiles_screen.dart';
import 'package:cobalagi/features/tutorial/view/tutorial_view.dart';
import 'package:cobalagi/features/learning/data/progress_repository.dart';
import 'package:cobalagi/features/play/cubit/play_cubit.dart';
import 'package:cobalagi/features/pretest/view/question_views.dart';
import 'package:cobalagi/features/profiles/data/profile_repository.dart';
import 'package:cobalagi/features/story/view/story_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sembast/sembast_memory.dart' show newDatabaseFactoryMemory;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a fresh install, from a new player to a solved lesson', (
    tester,
  ) async {
    final db = await newDatabaseFactoryMemory().openDatabase('flow.db');
    final settings = SettingsRepository(db);
    await settings.saveLanguageCode('en');
    await tester.pumpWidget(
      CobaLagiApp(
        profiles: ProfileRepository(db),
        settings: settings,
        entitlement: const StaticEntitlementService(Plan.free),
        audio: AudioplayersAudioService(),
        curriculum: CurriculumRepository(),
        progress: ProgressRepository(db),
      ),
    );

    Future<void> shot(String name) => _screenshot(tester, name);

    // 1. A new player.
    await waitFor(tester, find.text('New player'), step: 'players screen');
    await shot('01_players');
    await tester.tap(find.text('New player'));
    await waitFor(tester, find.byType(TextField), step: 'new player dialog');
    await tester.enterText(find.byType(TextField), 'Tester');
    await tester.tap(find.text('Save'));
    await waitGone(tester, find.byType(TextField), step: 'dialog closed');
    await calm(tester);
    await tester.tap(find.text('Tester'));

    // 2. The first warm-up: one wrong answer first, then until it ends.
    await waitFor(tester, find.text('Start'), step: 'warm-up welcome');
    await calm(tester);
    await shot('02_warm_up_welcome');
    await tester.tap(find.text('Start'));
    final cards = find.descendant(
      of: find.byType(QuestionView),
      // Only cards that take a tap: they wait for the question's voice.
      matching: find.byWidgetPredicate((w) => w is InkWell && w.onTap != null),
    );
    final check = find.byIcon(Icons.check_rounded);
    var questions = 0;
    var sawTryAgain = false;
    while (true) {
      await waitFor(
        tester,
        find.byType(QuestionView),
        step: 'question ${questions + 1}',
      );
      if (questions == 0) await tour(tester, 'warm-up', shot);
      await waitFor(tester, cards, step: 'question ${questions + 1}');
      await calm(tester);
      if (questions == 1) await shot('03_warm_up_question');
      // Card 0 first, then the next card each time, so some answers are
      // right and some are not.
      await tester.tap(cards.at(questions % cards.evaluate().length));
      await waitFor(tester, check, step: 'answer feedback');
      if (find.text('The answer is this one!').evaluate().isNotEmpty &&
          !sawTryAgain) {
        sawTryAgain = true;
        await shot('04_warm_up_show_answer');
      }
      questions++;
      await waitGone(tester, check, step: 'after answer $questions');
      await tester.pump(const Duration(milliseconds: 300));
      if (find.byType(QuestionView).evaluate().isEmpty) break;
      expect(questions, lessThan(30), reason: 'the warm-up never ended');
    }
    step('warm-up ended after $questions questions');
    expect(sawTryAgain, isTrue, reason: 'no answer showed the right one');

    await waitFor(tester, find.text("Let's go!"), step: 'warm-up done');
    await calm(tester);
    await shot('05_warm_up_done');
    await tester.tap(find.text("Let's go!"));

    // 3. The story's intro plays to its end.
    await watchStory(tester, 'intro', shot);

    // 4. The map: open the child's planet, where its arrival scene and its
    // demo play first, then a lesson.
    await waitFor(
      tester,
      find.byType(AdventureMapScreen),
      step: 'map after the intro',
    );
    await calm(tester);
    await shot('06_map');
    final map = tester.element(find.byType(AdventureMapScreen));
    final planet = map.read<LearningCubit>().state.learner!.currentConcept;
    final name = conceptName(AppLocalizations.of(map), planet);
    step('the child starts on $planet ($name)');
    await tester.tap(find.text(name).first);

    final play = find.byType(PlayScreen);
    final scene = find.byType(StoryPlayer);
    final demo = find.byType(TutorialView);
    final island = find.byType(IslandScreen);
    final tourShows = find.byType(CoachTour);
    var turns = 0;
    // The arrival scene and the demo may play over the lesson screen.
    while (play.evaluate().isEmpty ||
        scene.evaluate().isNotEmpty ||
        demo.evaluate().isNotEmpty) {
      await _until(
        tester,
        () =>
            scene.evaluate().isNotEmpty ||
            demo.evaluate().isNotEmpty ||
            island.evaluate().isNotEmpty ||
            tourShows.evaluate().isNotEmpty,
        step: 'the way into a lesson',
        timeout: const Duration(seconds: 30),
      );
      if (scene.evaluate().isNotEmpty) {
        await watchStory(tester, 'arrival', shot);
      } else if (demo.evaluate().isNotEmpty) {
        await watchDemo(tester, shot);
      } else if (island.evaluate().isNotEmpty && play.evaluate().isEmpty) {
        await calm(tester);
        await shot('07_planet');
        final go = find.textContaining('Play level');
        await tester.tap(
          go.evaluate().isNotEmpty
              ? go.first
              : find.text('Continue the adventure'),
        );
        await waitGone(tester, island, step: 'planet left');
      } else {
        break;
      }
      expect(++turns, lessThan(6), reason: 'never reached a lesson');
    }

    // 5. The lesson: its tour, then the shortest route as blocks, and Go.
    await tour(tester, 'play', shot);
    await waitFor(tester, find.byType(BlockEditor), step: 'block editor');
    await calm(tester);
    final playCubit = tester
        .element(find.byType(BlockEditor))
        .read<PlayCubit>();
    final route = solve(playCubit.state.level)!.body;
    step('solving ${playCubit.state.level.id} with ${route.length} blocks');
    for (final move in route) {
      final icon = switch (move) {
        Move() => Icons.arrow_upward_rounded,
        TurnLeft() => Icons.turn_left_rounded,
        TurnRight() => Icons.turn_right_rounded,
        _ => throw StateError('the solver only moves and turns'),
      };
      final block = find.descendant(
        of: find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_PaletteBlock',
        ),
        matching: find.byIcon(icon),
      );
      await tester.ensureVisible(block.first);
      await tester.tap(block.first);
      await tester.pump(const Duration(milliseconds: 300));
    }
    await calm(tester);
    await shot('08_program');
    await tester.tap(find.text('Go!'));
    final back = find.text('Back to the planet');
    await _until(
      tester,
      () =>
          back.evaluate().isNotEmpty ||
          find.text('To the map').evaluate().isNotEmpty,
      step: 'the solved card',
      timeout: const Duration(minutes: 1),
    );
    await calm(tester);
    await shot('09_solved');
    step('lesson solved');
    await tester.tap(
      back.evaluate().isNotEmpty ? back : find.text('To the map'),
    );
    await waitGone(tester, play, step: 'lesson closed');
    await calm(tester);

    // 6. Back to the players, and into the parent area through the gate.
    while (find.byType(ProfilesScreen).evaluate().isEmpty) {
      await tester.tap(find.byType(BackButton).first);
      await calm(tester);
    }
    await tester.tap(find.byTooltip('Parent area'));
    await waitFor(tester, find.byType(TextField), step: 'parent gate');
    await calm(tester);
    await shot('10_parent_gate');
    final question = RegExp(
      r'(\d+) × (\d+)',
    ).firstMatch(_texts().firstWhere((t) => t.contains('×')))!;
    await tester.enterText(
      find.byType(TextField),
      '${int.parse(question[1]!) * int.parse(question[2]!)}',
    );
    await tester.tap(find.text('OK'));
    await waitFor(tester, find.byType(ParentScreen), step: 'parent area');
    await calm(tester);
    await shot('11_parent_area');
    await tester.tap(find.text('Tester').first);
    await waitGone(tester, find.byType(ParentScreen), step: 'progress report');
    await calm(tester);
    await shot('12_progress');
    step('done');

    // Unmounting the app disposes the players, whose position updater
    // otherwise keeps ticking after the test.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}

/// Steps through a guided tour to its end with Next, as a child would.
Future<void> tour(
  WidgetTester tester,
  String name,
  Future<void> Function(String) shot,
) async {
  await waitFor(tester, find.byType(CoachTour), step: '$name tour');
  var steps = 0;
  while (find.byType(CoachTour).evaluate().isNotEmpty) {
    final next = find.descendant(
      of: find.byType(CoachTour),
      matching: find.byWidgetPredicate(
        (w) => w is Text && (w.data == 'Next' || w.data == 'Got it!'),
      ),
    );
    await waitFor(tester, next, step: '$name tour step ${steps + 1}');
    await calm(tester);
    if (steps == 0) await shot('${name}_tour');
    await tester.tap(next.first);
    steps++;
    await tester.pump(const Duration(milliseconds: 400));
    expect(steps, lessThan(30), reason: 'the $name tour never ended');
  }
  step('$name tour: $steps steps');
}

/// Lets a story scene play to its end, then taps "Let's play!".
Future<void> watchStory(
  WidgetTester tester,
  String name,
  Future<void> Function(String) shot,
) async {
  await waitFor(tester, find.byType(StoryPlayer), step: '$name scene');
  final started = DateTime.now();
  await tester.pump(const Duration(seconds: 3));
  await shot('${name}_scene');
  final play = letsPlay;
  await waitFor(
    tester,
    play,
    step: 'end of $name scene',
    timeout: const Duration(minutes: 3),
  );
  await calm(tester);
  await shot('${name}_scene_end');
  step('$name scene: ${DateTime.now().difference(started).inSeconds} s');
  await tester.tap(play);
  await waitGone(tester, find.byType(StoryPlayer), step: '$name scene closed');
}

/// Watches a planet's "Watch me!" demo to its end, then taps "Let's play!".
Future<void> watchDemo(
  WidgetTester tester,
  Future<void> Function(String) shot,
) async {
  final started = DateTime.now();
  await tester.pump(const Duration(seconds: 4));
  await shot('demo');
  final play = letsPlay;
  await waitFor(
    tester,
    play,
    step: 'end of the demo',
    timeout: const Duration(minutes: 3),
  );
  await calm(tester);
  await shot('demo_end');
  step('demo: ${DateTime.now().difference(started).inSeconds} s');
  await tester.tap(play);
  await waitGone(tester, find.byType(TutorialView), step: 'demo closed');
}

/// Lets a moment of animation play. Not `pumpAndSettle`: the screens have
/// animations that loop (the hint bulb, Koba's bobbing), so they never
/// settle.
Future<void> calm(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await tester.pump();
  }
}

/// "Let's play!" at the end of a scene or demo, once it takes a tap: it is
/// there from the start, hidden and ignoring taps.
final letsPlay = find.text("Let's play!").hitTestable();

/// Prints a marker for the person watching the run.
void step(String text) {
  // ignore: avoid_print
  print('▶ $text');
}

/// Pumps until [finder] finds something, or fails with what is on screen.
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  required String step,
  Duration timeout = const Duration(seconds: 30),
}) => _until(
  tester,
  () => finder.evaluate().isNotEmpty,
  step: step,
  timeout: timeout,
);

/// Pumps until [finder] finds nothing.
Future<void> waitGone(
  WidgetTester tester,
  Finder finder, {
  required String step,
  Duration timeout = const Duration(seconds: 30),
}) => _until(
  tester,
  () => finder.evaluate().isEmpty,
  step: step,
  timeout: timeout,
);

Future<void> _until(
  WidgetTester tester,
  bool Function() done, {
  required String step,
  required Duration timeout,
}) async {
  final end = DateTime.now().add(timeout);
  while (!done()) {
    if (DateTime.now().isAfter(end)) {
      fail('timed out waiting for: $step. On screen: ${_texts()}');
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await tester.pump();
  }
}

List<String> _texts() => [
  for (final e in find.byType(Text).evaluate())
    (e.widget as Text).data ?? (e.widget as Text).textSpan?.toPlainText() ?? '',
].where((t) => t.trim().isNotEmpty).take(20).toList();

/// Prints what the app shows as a PNG in base64 lines (`SHOT <name> <part>`),
/// since the app's own folders can't be read from outside on every device:
/// `tool/collect_screenshots.dart` turns a saved run log back into files.
Future<void> _screenshot(WidgetTester tester, String name) async {
  final view = tester.binding.renderViews.first;
  final layer = view.debugLayer! as OffsetLayer;
  final image = await tester.runAsync(
    // The root layer is in device pixels; half of them is enough to look at.
    () => layer.toImage(
      Offset.zero & view.flutterView.physicalSize,
      pixelRatio: 0.5,
    ),
  );
  final bytes = await tester.runAsync(
    () => image!.toByteData(format: ui.ImageByteFormat.png),
  );
  final text = base64Encode(bytes!.buffer.asUint8List());
  // Short lines, so Android's log doesn't cut them.
  for (var i = 0; i < text.length; i += 800) {
    // ignore: avoid_print
    print('SHOT $name ${text.substring(i, min(i + 800, text.length))}');
  }
  step('screenshot $name');
}
