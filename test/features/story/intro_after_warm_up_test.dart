import 'package:cobalagi/app/app.dart';
import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/core/entitlement/entitlement_service.dart';
import 'package:cobalagi/core/entitlement/plan.dart';
import 'package:cobalagi/core/settings/settings_repository.dart';
import 'package:cobalagi/features/learning/cubit/learning_cubit.dart';
import 'package:cobalagi/features/learning/data/curriculum_repository.dart';
import 'package:cobalagi/features/learning/data/progress_repository.dart';
import 'package:cobalagi/features/pretest/view/pretest_screen.dart';
import 'package:cobalagi/features/profiles/data/profile_repository.dart';
import 'package:cobalagi/features/story/view/story_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  // The warm-up opens on top of the map, which is built before the child has
  // a starting point, so the intro becomes due while the map is hidden.
  testWidgets('a new child sees the intro right after the first warm-up', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2400, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final (db, id) = (await tester.runAsync(() async {
      final db = await newDatabaseFactoryMemory().openDatabase('new.db');
      final child = await ProfileRepository(
        db,
      ).add(nickname: 'Bima', avatar: 0);
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
    ).go('/child/$id/pretest');
    await _settle(tester);
    final pretest = tester.element(find.byType(PretestScreen));
    await tester.runAsync(
      () => pretest.read<LearningCubit>().completePretest(const {}),
    );
    await _settle(tester);
    // Not over the warm-up's last screen.
    expect(find.byType(StoryPlayer), findsNothing);

    GoRouter.of(pretest).go('/child/$id');
    await _settle(tester);
    expect(find.byType(StoryPlayer), findsOneWidget);
  });
}
