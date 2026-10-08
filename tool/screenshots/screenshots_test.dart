// Renders the README, website and store screenshots from the real app with
// sample data, in Indonesian and English:
//
//   flutter test tool/screenshots --update-goldens
//   tool/screenshots/export.sh
//
// Not part of the Checks: it writes images instead of testing behaviour.
import 'dart:io';

import 'package:cobalagi/app/app.dart';
import 'package:cobalagi/features/pretest/view/question_views.dart';
import 'package:cobalagi/learning/placement/pretest_question.dart';
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

/// Phone screenshots, portrait.
const _phone = Size(400, 760);

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
  // Typed code asks for 'monospace', which Android maps to its own mono
  // font; tests have none, so borrow the Mac's.
  final mono = FontLoader('monospace')
    ..addFont(
      Future.value(
        ByteData.sublistView(
          File('/System/Library/Fonts/SFNSMono.ttf').readAsBytesSync(),
        ),
      ),
    );
  await mono.load();
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
Future<Database> _seed(String language, {bool reader = false}) async {
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
        readsWords: reader,
        at: DateTime(2026, 9, 28),
        byParent: false,
      ),
      warmUp: const {
        'counting': 3,
        'colors': 3,
        'shapes': 2,
        'patterns': 2,
        'sides': 1,
      },
      progress: {
        for (final (id, n) in [
          ('directions', 6),
          ('sequencing', 6),
          ('loops', 6),
        ])
          id: ConceptProgress(
            scores: const [1, 0.9, 1],
            difficulty: 3,
            attemptedLessons: lessons(id, n),
            solvedLessons: lessons(id, n),
            // Mostly first tries; one level could still earn a star.
            lessonStars: {
              for (final l in lessons(id, n)) l: l.endsWith('5') ? 2 : 3,
            },
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

/// Builds checked corridor sweeps for a Conditions lesson.
Future<void> _buildConditionAnswer(WidgetTester tester) async {
  final cubit = tester.element(find.byType(BlockEditor)).read<BlocksCubit>();
  cubit.add(BlockType.repeat);
  final loop = cubit.state.main.single.id;
  cubit.setCount(loop, 6);
  cubit.add(BlockType.ifPathClear, parentId: loop);
  final eye = cubit.state.main.single.children.single.id;
  cubit.add(BlockType.forward, parentId: eye);
  cubit.add(BlockType.turnRight);
  cubit.add(BlockType.repeat);
  final secondLoop = cubit.state.main.last.id;
  cubit.setCount(secondLoop, 6);
  cubit.add(BlockType.ifPathClear, parentId: secondLoop);
  final secondEye = cubit.state.main.last.children.single.id;
  cubit.add(BlockType.forward, parentId: secondEye);
  await _settle(tester);
}

/// Builds the Step Box answer to variables-02: save 3, move, turn, move.
Future<void> _buildStepBoxAnswer(WidgetTester tester) async {
  final cubit = tester.element(find.byType(BlockEditor)).read<BlocksCubit>();
  cubit.add(BlockType.setSteps);
  cubit.setCount(cubit.state.main.single.id, 3);
  cubit.add(BlockType.moveSteps);
  cubit.add(BlockType.turnRight);
  cubit.add(BlockType.moveSteps);
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

/// Builds a one-repeat answer to the loops level [levelId] in the editor.
Future<void> _buildLoopAnswer(WidgetTester tester, String levelId) async {
  final level = parseLevelPack(
    File('assets/levels/loops.json').readAsStringSync(),
  ).firstWhere((l) => l.id == levelId);
  final steps = solve(level)!.body.map((i) => i.kind).toList();
  final cubit = tester.element(find.byType(BlockEditor)).read<BlocksCubit>();
  BlockType type(InstructionKind kind) =>
      BlockType.values.firstWhere((t) => t.kind == kind);
  for (var unit = 1; unit <= steps.length ~/ 2; unit++) {
    for (var start = 0; start + unit * 2 <= steps.length; start++) {
      final body = steps.sublist(start, start + unit);
      bool same(int at) => List.generate(
        unit,
        (j) => at + j < steps.length && steps[at + j] == body[j],
      ).every((s) => s);
      var times = 1;
      while (same(start + times * unit)) {
        times++;
      }
      var rest = steps.sublist(start + times * unit);
      // The run stops on the goal, so a final repeat may end part-way.
      if (rest.isNotEmpty &&
          rest.length < unit &&
          List.generate(
            rest.length,
            (j) => rest[j] == body[j],
          ).every((s) => s)) {
        times++;
        rest = [];
      }
      final blocks = start + 1 + unit + rest.length;
      if (times >= 2 && blocks <= level.maxBlocks!) {
        for (final kind in steps.sublist(0, start)) {
          cubit.add(type(kind));
        }
        cubit.add(BlockType.repeat);
        final loop = cubit.state.main.last.id;
        cubit.setCount(loop, times);
        for (final kind in body) {
          cubit.add(type(kind), parentId: loop);
        }
        for (final kind in rest) {
          cubit.add(type(kind));
        }
        await _settle(tester);
        return;
      }
    }
  }
  throw StateError('no loop answer for $levelId');
}

/// Advances the real warm-up to its first picture-pattern question.
Future<void> _openWarmUpPattern(WidgetTester tester) async {
  await _open(tester, '/child/2/pretest');
  for (var i = 0; i < 30; i++) {
    final view = tester.widget<QuestionView>(find.byType(QuestionView));
    if (view.question is PatternQuestion) return;
    view.onAnswer!(view.question.correct);
    await _settle(tester);
  }
  throw StateError('warm-up did not reach a pattern question');
}

Future<void> _openPlacement(WidgetTester tester, String language) async {
  await _open(tester, '/parent');
  final context = tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).push('/parent/progress/1');
  await _settle(tester);
  await tester.tap(
    find.text(language == 'id' ? 'Ubah planet awal' : 'Change starting planet'),
  );
  await _settle(tester);
}

Future<void> _showSolved(WidgetTester tester, String language) async {
  await _open(tester, '/child/1/replay/loops-03');
  await _buildLoopAnswer(tester, 'loops-03');
  final go = language == 'id' ? 'Jalan!' : 'Go!';
  // Small phones show Go as a picture with a tooltip.
  await tester.tap(
    find.text(go).evaluate().isNotEmpty ? find.text(go) : find.byTooltip(go),
  );
  for (var i = 0; i < 200; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    if (find
        .text(language == 'id' ? 'Kembali ke planet' : 'Back to the planet')
        .evaluate()
        .isNotEmpty) {
      return;
    }
  }
  throw StateError('loop answer did not reach the solved screen');
}

void main() {
  setUpAll(_loadFonts);

  for (final language in ['id', 'en']) {
    final suffix = language == 'id' ? '-id' : '';

    Future<void> pumpApp(
      WidgetTester tester, {
      Plan plan = Plan.free,
      Size size = _size,
      bool reader = false,
    }) async {
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      rootBundle.clear();
      final db = await tester.runAsync(() => _seed(language, reader: reader));
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
        version: '1.1.0',
        buildNumber: '8',
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
      // Decode the robot, but stay on the splash.
      await tester.runAsync(() async {
        final robot = tester.element(find.byType(Image).first);
        for (final part in ['head', 'body']) {
          await precacheImage(
            AssetImage('assets/images/robot_$part.png'),
            robot,
          );
        }
      });
      await tester.pump(const Duration(milliseconds: 100));
      await shoot('splash');
      await tester.pump(const Duration(seconds: 2));
    });

    for (final (prefix, size) in [('', _size), ('phone-', _phone)]) {
      group('${prefix.isEmpty ? 'tablet' : 'phone'} $language', () {
        Future<void> device(
          WidgetTester tester, {
          Plan plan = Plan.free,
          bool reader = false,
        }) => pumpApp(tester, plan: plan, size: size, reader: reader);

        testWidgets('map', (tester) async {
          await device(tester);
          await _open(tester, '/child/1');
          await shoot('${prefix}adventure-map');
        });

        testWidgets('profiles', (tester) async {
          await device(tester);
          await _open(tester, '/');
          await shoot('${prefix}profiles');
        });

        testWidgets('loops puzzle', (tester) async {
          await device(tester);
          await _open(tester, '/child/1/replay/loops-03');
          await _buildLoopAnswer(tester, 'loops-03');
          await shoot('${prefix}play-loops');
        });

        testWidgets('magic block', (tester) async {
          await device(tester);
          final level = prefix.isEmpty ? 'functions-02' : 'functions-01';
          await _open(tester, '/child/1/replay/$level');
          await _buildAnswer(tester, level);
          await shoot('${prefix}play-functions');
        });

        testWidgets('look ahead', (tester) async {
          await device(tester);
          await _open(tester, '/child/1/replay/conditions-02');
          await _buildConditionAnswer(tester);
          await shoot('${prefix}play-conditions');
        });

        testWidgets('step box', (tester) async {
          await device(tester);
          await _open(tester, '/child/1/replay/variables-02');
          await _buildStepBoxAnswer(tester);
          await shoot('${prefix}play-variables');
        });

        testWidgets('typed code', (tester) async {
          // A reader, so the Code tab shows.
          await device(tester, reader: true);
          await _open(tester, '/child/1/replay/loops-03');
          await _buildLoopAnswer(tester, 'loops-03');
          final code = language == 'id' ? 'Kode' : 'Code';
          // Phones show the switch as icons with tooltips.
          final icon = find.byTooltip(code);
          await tester.tap(icon.evaluate().isNotEmpty ? icon : find.text(code));
          await _settle(tester);
          await shoot('${prefix}play-code');
        });

        for (final level in ['loops-03', 'variables-04']) {
          testWidgets('hint $level', (tester) async {
            await device(tester);
            await _open(tester, '/child/1/replay/$level');
            // The bulb works after a few tries: one step, three times.
            final blocks = tester
                .element(find.byType(BlockEditor))
                .read<BlocksCubit>();
            blocks.add(
              level.startsWith('variables')
                  ? BlockType.moveSteps
                  : BlockType.forward,
            );
            await _settle(tester);
            for (var i = 0; i < 3; i++) {
              await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
              await _settle(tester);
              final again = find.byIcon(Icons.replay_rounded);
              if (again.evaluate().isNotEmpty) await tester.tap(again.first);
              await _settle(tester);
            }
            blocks.clear();
            await _settle(tester);
            await tester.tap(find.byIcon(Icons.lightbulb_rounded));
            // Every block of the hint has appeared.
            for (var i = 0; i < 40; i++) {
              await tester.pump(const Duration(milliseconds: 100));
            }
            await shoot('${prefix}hint-$level');
          });
        }

        // The two islands without a play screenshot, for the website.
        if (prefix.isEmpty) {
          for (final (concept, level) in [
            ('directions', 'directions-03'),
            ('sequencing', 'sequencing-03'),
          ]) {
            testWidgets('island $concept', (tester) async {
              await device(tester);
              await _open(tester, '/child/1/replay/$level');
              await shoot('island-$concept');
            });
          }
        }

        testWidgets('fix it', (tester) async {
          await device(tester);
          // A turn the wrong way inside stairs: the starter blocks are there.
          await _open(tester, '/child/1/replay/debugging-05');
          // The child has spotted the wrong turn and tapped it.
          final cubit = tester
              .element(find.byType(BlockEditor))
              .read<BlocksCubit>();
          cubit.pickBlock(cubit.state.main.single.children.last.id);
          await _settle(tester);
          await shoot('${prefix}play-debugging');
        });

        testWidgets('until the flag', (tester) async {
          await device(tester);
          await _open(tester, '/child/1/replay/until-03');
          // Stairs of any size: one loop that runs to the flag.
          final cubit = tester
              .element(find.byType(BlockEditor))
              .read<BlocksCubit>();
          cubit.add(BlockType.untilGoal);
          final until = cubit.state.main.single.id;
          for (final type in [
            BlockType.forward,
            BlockType.turnLeft,
            BlockType.forward,
            BlockType.turnRight,
          ]) {
            cubit.add(type, parentId: until);
          }
          await _settle(tester);
          await shoot('${prefix}play-until');
        });

        testWidgets('otherwise', (tester) async {
          await device(tester);
          await _open(tester, '/child/1/replay/otherwise-04');
          // Follow the walls: step if clear, otherwise turn.
          final cubit = tester
              .element(find.byType(BlockEditor))
              .read<BlocksCubit>();
          cubit.add(BlockType.untilGoal);
          final until = cubit.state.main.single.id;
          cubit.add(BlockType.ifElse, parentId: until);
          final check = cubit.state.main.single.children.single.id;
          cubit.add(BlockType.forward, parentId: check);
          cubit.add(
            BlockType.turnRight,
            parentId: BlocksCubit.otherwiseOf(check),
          );
          await _settle(tester);
          await shoot('${prefix}play-otherwise');
        });

        testWidgets('watch me', (tester) async {
          await device(tester);
          await _open(tester, '/child/1/tutorial/loops');
          // Part-way: the hand is about to drop forward into the repeat.
          for (var i = 0; i < 52; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          await shoot('${prefix}tutorial-loops');
          await tester.tap(find.text(language == 'id' ? 'Lewati' : 'Skip'));
          await _settle(tester);
        });

        // Frames of "Watch me!" demos, 10 per second, for the promo videos
        // (tool/marketing/). Only on request:
        //   VIDEO_FRAMES=1 flutter test tool/screenshots --update-goldens \
        //     --plain-name 'video frames'
        for (final (concept, frames) in [
          ('loops', 130),
          ('debugging', 130),
          ('until', 170),
        ]) {
          testWidgets(
            'video frames $concept',
            skip: !Platform.environment.containsKey('VIDEO_FRAMES'),
            (tester) async {
              await device(tester);
              await _open(tester, '/child/1/tutorial/$concept');
              for (var frame = 0; frame < frames; frame++) {
                await expectLater(
                  find.byType(CobaLagiApp),
                  matchesGoldenFile(
                    'out/video/$prefix$concept$suffix-'
                    '${frame.toString().padLeft(3, '0')}.png',
                  ),
                );
                await tester.pump(const Duration(milliseconds: 100));
              }
            },
          );
        }

        testWidgets('solved', (tester) async {
          await device(tester);
          await _showSolved(tester, language);
          await shoot('${prefix}solved');
        });

        testWidgets('warm-up', (tester) async {
          await device(tester);
          await _openWarmUpPattern(tester);
          await shoot(prefix.isEmpty ? 'warm-up-pattern' : 'phone-warm-up');
        });

        testWidgets('sticker book', (tester) async {
          await device(tester);
          await _open(tester, '/child/1/stickers');
          await shoot('${prefix}sticker-book');
        });

        testWidgets('warm-up island', (tester) async {
          await device(tester);
          await _open(tester, '/child/1/warm-up');
          await shoot('${prefix}warm-up-island');
        });

        testWidgets('warm-up colours', (tester) async {
          await device(tester);
          await _open(tester, '/child/1/warm-up/colors');
          await shoot('${prefix}warm-up-colors');
        });

        testWidgets('parent placement', (tester) async {
          await device(tester, plan: Plan.full);
          await _openPlacement(tester, language);
          await shoot('${prefix}parent-placement');
        });

        testWidgets('progress', (tester) async {
          await device(tester, plan: Plan.full);
          await _open(tester, '/parent');
          final context = tester.element(find.byType(Scaffold).first);
          GoRouter.of(context).push('/parent/progress/1');
          await _settle(tester);
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -280),
          );
          await _settle(tester);
          await shoot('${prefix}parent-progress');
        });
      });
    }
  }
}
