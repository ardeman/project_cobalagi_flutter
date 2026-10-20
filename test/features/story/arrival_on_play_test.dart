import 'package:cobalagi/app/app.dart';
import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/core/entitlement/entitlement_service.dart';
import 'package:cobalagi/core/entitlement/plan.dart';
import 'package:cobalagi/core/settings/settings_repository.dart';
import 'package:cobalagi/features/learning/data/curriculum_repository.dart';
import 'package:cobalagi/features/learning/data/progress_repository.dart';
import 'package:cobalagi/features/profiles/data/profile_repository.dart';
import 'package:cobalagi/features/story/view/arrival_scenes.dart';
import 'package:cobalagi/features/story/view/story_player.dart';
import 'package:cobalagi/features/tutorial/view/tutorial_view.dart';
import 'package:cobalagi/learning/learner_state.dart';
import 'package:cobalagi/learning/placement/placement.dart';
import 'package:cobalagi/learning/story.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sembast/sembast_memory.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('a planet first plays its arrival, then its demo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2400, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final (db, id) = (await tester.runAsync(() async {
      final db = await newDatabaseFactoryMemory().openDatabase('arrival.db');
      final child = await ProfileRepository(db).add(nickname: 'Ayu', avatar: 0);
      await ProgressRepository(db).save(
        child.id,
        LearnerState(
          currentConcept: 'loops',
          tutorialsSeen: const {'tour-play', 'tour-warmup', Story.intro},
          placement: Placement(
            startConcept: 'loops',
            levels: const {},
            readsWords: false,
            at: DateTime(2026, 10, 1),
            byParent: false,
          ),
        ),
      );
      return (db, child.id);
    }))!;
    await tester.pumpWidget(
      CobaLagiApp(
        profiles: ProfileRepository(db),
        settings: SettingsRepository(db),
        entitlement: const StaticEntitlementService(Plan.free),
        audio: const SilentAudioService(),
        curriculum: CurriculumRepository(),
        progress: ProgressRepository(db),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await _settle(tester);
    GoRouter.of(
      tester.element(find.byType(Scaffold).first),
    ).go('/child/$id/play');
    await _settle(tester);
    final player = tester.widget<StoryPlayer>(find.byType(StoryPlayer));
    expect(player.scene, arrivalScenes['loops']);

    // Skip.
    await tester.tap(
      find.descendant(
        of: find.byType(StoryPlayer),
        matching: find.byType(TextButton),
      ),
    );
    await _settle(tester);
    expect(find.byType(StoryPlayer), findsNothing);
    expect(find.byType(TutorialView), findsOneWidget);
    final saved = await tester.runAsync(() => ProgressRepository(db).load(id));
    expect(saved!.tutorialsSeen, contains(Story.arrival('loops')));

    // The demo's timers end with it.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}
