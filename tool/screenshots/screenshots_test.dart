// Renders the README, website and store screenshots from the real app with
// sample data, in Indonesian and English:
//
//   flutter test tool/screenshots --update-goldens
//   tool/screenshots/export.sh
//
// Not part of the Checks: it writes images instead of testing behaviour.
import 'dart:io';

import 'package:cobalagi/app/app.dart';
import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/core/entitlement/entitlement_service.dart';
import 'package:cobalagi/core/entitlement/plan.dart';
import 'package:cobalagi/core/settings/settings_repository.dart';
import 'package:cobalagi/engine/generator/solver.dart';
import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/features/editors/blocks/cubit/blocks_cubit.dart';
import 'package:cobalagi/features/editors/blocks/data/block.dart';
import 'package:cobalagi/features/editors/blocks/view/block_editor.dart';
import 'package:cobalagi/features/learning/data/curriculum_repository.dart';
import 'package:cobalagi/features/learning/data/progress_repository.dart';
import 'package:cobalagi/features/play/data/level_repository.dart';
import 'package:cobalagi/features/profiles/data/profile_repository.dart';
import 'package:cobalagi/learning/exercise_result.dart';
import 'package:cobalagi/learning/learner_state.dart';
import 'package:cobalagi/learning/placement/placement.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sembast/sembast_memory.dart';

/// Screenshots are 1280 x 740 logical pixels, rendered at 2x.
const _size = Size(1280, 740);

/// The Material fonts that ship with the Flutter SDK running this test.
Future<void> _loadFonts() async {
  final tester = Platform.resolvedExecutable;
  final root = tester.substring(0, tester.indexOf('/bin/cache/'));
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(
        Future.value(
          ByteData.sublistView(File('$dir/$file').readAsBytesSync()),
        ),
      );
    }
    await loader.load();
  }

  await load('Roboto', [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Black.ttf',
  ]);
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
}

ExerciseResult _result(String concept, String level, {int seconds = 80}) =>
    ExerciseResult(
      conceptId: concept,
      levelId: level,
      mode: ExerciseMode.lesson,
      difficulty: 2,
      succeeded: true,
      runs: 1,
      hintsUsed: 0,
      duration: Duration(seconds: seconds),
    );

/// Eclo has finished the first three islands and started Magic Block.
Future<Database> _seed(String language) async {
  final db = await newDatabaseFactoryMemory().openDatabase('shots.db');
  final eclo = await ProfileRepository(db).add(nickname: 'Eclo', avatar: 0);
  await ProfileRepository(db).add(nickname: 'Gito', avatar: 2);
  final progress = ProgressRepository(db);
  Set<String> lessons(String id, int n) => {
    for (var i = 1; i <= n; i++) '$id-0$i',
  };
  await progress.save(
    eclo.id,
    LearnerState(
      currentConcept: 'functions',
      placement: Placement(
        startConcept: 'directions',
        levels: const {},
        readsWords: false,
        at: DateTime(2026, 9, 28),
        byParent: false,
      ),
      progress: {
        for (final (id, n) in [
          ('directions', 5),
          ('sequencing', 4),
          ('loops', 4),
        ])
          id: ConceptProgress(
            scores: const [1, 0.9, 1],
            difficulty: 3,
            attemptedLessons: lessons(id, n),
            solvedLessons: lessons(id, n),
          ),
        'functions': ConceptProgress(
          scores: const [0.6],
          difficulty: 1,
          attemptedLessons: lessons('functions', 2),
          solvedLessons: lessons('functions', 1),
        ),
      },
    ),
  );
  // Older attempts, then this week's (attempts are timed when logged).
  await db.transaction((txn) async {
    final attempts = intMapStoreFactory.store('attempts');
    final weekAgo = DateTime.now().subtract(const Duration(days: 9));
    for (var i = 0; i < 26; i++) {
      await attempts.add(txn, {
        'profile': eclo.id,
        'at': weekAgo.add(Duration(minutes: i * 30)).millisecondsSinceEpoch,
        ..._result('loops', 'loops-0${i % 4 + 1}').toJson(),
      });
    }
  });
  for (var i = 0; i < 9; i++) {
    await progress.logAttempt(
      eclo.id,
      _result('functions', 'functions-0${i % 2 + 1}', seconds: 95),
    );
  }
  await SettingsRepository(db).saveLanguageCode(language);
  return db;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _open(WidgetTester tester, String path) async {
  final context = tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).go(path);
  await _settle(tester);
}

/// Builds a star-block answer to [levelId] in the editor, like a child would.
Future<void> _buildAnswer(WidgetTester tester, String levelId) async {
  final level = parseLevelPack(
    File('assets/levels/functions.json').readAsStringSync(),
  ).firstWhere((l) => l.id == levelId);
  final steps = solve(level)!.body.map((i) => i.kind).toList();
  // The shortest repeating shape that, called each time it comes back, fits.
  for (var unit = 2; unit <= steps.length ~/ 2; unit++) {
    for (var start = 0; start + unit <= steps.length; start++) {
      final shape = steps.sublist(start, start + unit);
      bool at(int i) =>
          List.generate(
            shape.length,
            (j) => i + j < steps.length && steps[i + j] == shape[j],
          ).every((same) => same) ||
          (steps.length - i < unit &&
              List.generate(
                steps.length - i,
                (j) => steps[i + j] == shape[j],
              ).every((same) => same));
      final main = <InstructionKind>[];
      for (var i = 0; i < steps.length;) {
        if (at(i)) {
          main.add(InstructionKind.call);
          i += unit;
        } else {
          main.add(steps[i++]);
        }
      }
      if (main.length + shape.length <= level.maxBlocks!) {
        final cubit = tester
            .element(find.byType(BlockEditor))
            .read<BlocksCubit>();
        BlockType type(InstructionKind kind) =>
            BlockType.values.firstWhere((t) => t.kind == kind);
        for (final kind in shape) {
          cubit.add(type(kind), parentId: BlocksCubit.starRow);
        }
        for (final kind in main) {
          cubit.add(type(kind));
        }
        await _settle(tester);
        return;
      }
    }
  }
  throw StateError('no star answer for $levelId');
}

void main() {
  setUpAll(_loadFonts);

  for (final language in ['id', 'en']) {
    final suffix = language == 'id' ? '-id' : '';

    Future<void> pumpApp(
      WidgetTester tester, {
      Plan plan = Plan.free,
      Size size = _size,
    }) async {
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      rootBundle.clear();
      final db = await tester.runAsync(() => _seed(language));
      await tester.pumpWidget(
        CobaLagiApp(
          profiles: ProfileRepository(db!),
          settings: SettingsRepository(db),
          entitlement: StaticEntitlementService(plan),
          audio: const SilentAudioService(),
          curriculum: CurriculumRepository(),
          progress: ProgressRepository(db),
        ),
      );
      // Past the splash screen.
      await tester.pump(const Duration(seconds: 2));
      await _settle(tester);
    }

    Future<void> shoot(String name) => expectLater(
      find.byType(CobaLagiApp),
      matchesGoldenFile('out/$name$suffix.png'),
    );

    testWidgets('splash ($language)', (tester) async {
      // A test-only API: this file is a test, but lives in tool/ so it stays
      // out of the Checks.
      // ignore: invalid_use_of_visible_for_testing_member
      PackageInfo.setMockInitialValues(
        appName: 'Coba Lagi',
        packageName: 'com.ardeman.cobalagi',
        version: '1.0.0',
        buildNumber: '4',
        buildSignature: '',
      );
      tester.view.physicalSize = _size * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final db = await tester.runAsync(() => _seed(language));
      await tester.pumpWidget(
        CobaLagiApp(
          profiles: ProfileRepository(db!),
          settings: SettingsRepository(db),
          entitlement: const StaticEntitlementService(Plan.free),
          audio: const SilentAudioService(),
          curriculum: CurriculumRepository(),
          progress: ProgressRepository(db),
        ),
      );
      // Decode the logo, but stay on the splash.
      await tester.runAsync(() async {
        final logo = tester.element(find.byType(Image));
        await precacheImage(const AssetImage('assets/images/logo.png'), logo);
      });
      await tester.pump(const Duration(milliseconds: 100));
      await shoot('splash');
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('adventure map ($language)', (tester) async {
      await pumpApp(tester);
      await _open(tester, '/child/1');
      await shoot('adventure-map');
    });

    testWidgets('magic block ($language)', (tester) async {
      await pumpApp(tester);
      await _open(tester, '/child/1/replay/functions-02');
      await _buildAnswer(tester, 'functions-02');
      await shoot('play-functions');
    });

    testWidgets('progress report ($language)', (tester) async {
      // Tall enough for every island; shown as a framed card in the store.
      await pumpApp(tester, plan: Plan.full, size: const Size(760, 820));
      await _open(tester, '/parent');
      final context = tester.element(find.byType(Scaffold).first);
      GoRouter.of(context).push('/parent/progress/1');
      await _settle(tester);
      await shoot('parent-progress');
    });
  }
}
