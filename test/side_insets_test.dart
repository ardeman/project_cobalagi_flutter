import 'package:cobalagi/app/app.dart';
import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/core/entitlement/entitlement_service.dart';
import 'package:cobalagi/core/entitlement/plan.dart';
import 'package:cobalagi/core/settings/settings_repository.dart';
import 'package:cobalagi/core/widgets/focus_tap.dart';
import 'package:cobalagi/features/learning/data/curriculum_repository.dart';
import 'package:cobalagi/features/learning/data/progress_repository.dart';
import 'package:cobalagi/features/profiles/data/profile_repository.dart';
import 'package:cobalagi/learning/learner_state.dart';
import 'package:cobalagi/learning/placement/placement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sembast/sembast_memory.dart';

import 'helpers/real_fonts.dart';

/// The iPhone Duo open (669 × 951 points) and closed (466 × 678), either
/// way up: its status bar and Dynamic Island sit on a side edge, so the
/// safe area comes in from the left or the right, as a notch does on other
/// phones held sideways.
const _devices = [
  ('Duo open', Size(951, 669)),
  ('Duo open upright', Size(669, 951)),
  ('Duo closed', Size(678, 466)),
  ('Duo closed upright', Size(466, 678)),
];
const _inset = 62.0;

const _screens = [
  '/',
  '/child/1',
  '/child/1/island/sequencing',
  '/child/1/replay/sequencing-01',
  '/child/1/stickers',
  '/child/1/warm-up',
  '/child/1/warm-up/colors',
  '/child/1/tutorial/sequencing',
  '/child/1/story/intro',
  '/child/1/stories',
  '/child/1/pretest',
  '/parent',
  '/parent/progress/1',
];

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpApp(WidgetTester tester) async {
  final db = await tester.runAsync(() async {
    final db = await newDatabaseFactoryMemory().openDatabase('duo.db');
    final child = await ProfileRepository(db).add(nickname: 'Eclo', avatar: 0);
    await ProgressRepository(db).save(
      child.id,
      LearnerState(
        currentConcept: 'sequencing',
        // Past the guided tours and the story's intro, so they don't cover
        // the screens.
        tutorialsSeen: const {'tour-play', 'tour-warmup', 'story-intro'},
        placement: Placement(
          startConcept: 'sequencing',
          levels: const {},
          readsWords: true,
          at: DateTime(2026, 10, 1),
          byParent: false,
        ),
      ),
    );
    return db;
  });
  await tester.pumpWidget(
    CobaLagiApp(
      profiles: ProfileRepository(db!),
      settings: SettingsRepository(db),
      entitlement: const StaticEntitlementService(Plan.full),
      audio: const SilentAudioService(),
      curriculum: CurriculumRepository(),
      progress: ProgressRepository(db),
    ),
  );
  // Past the splash screen.
  await tester.pump(const Duration(seconds: 2));
  await _settle(tester);
}

/// Everything a child or parent can tap.
final _tappable = find.byWidgetPredicate(
  (widget) =>
      widget is ButtonStyleButton ||
      widget is IconButton ||
      widget is InkWell ||
      widget is FocusTap,
);

void main() {
  setUpAll(loadRealFonts);

  for (final (device, size) in _devices) {
    for (final side in ['left', 'right']) {
      testWidgets('$device: controls stay clear of a $side inset', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.view.padding = FakeViewPadding(
          left: side == 'left' ? _inset : 0,
          right: side == 'right' ? _inset : 0,
          bottom: 21,
        );
        addTearDown(tester.view.reset);
        await _pumpApp(tester);

        final safe = Rect.fromLTRB(
          side == 'left' ? _inset : 0,
          0,
          size.width - (side == 'right' ? _inset : 0),
          size.height,
        );
        final clipped = <String>{};
        for (final path in _screens) {
          GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
          await _settle(tester);
          for (final element in _tappable.hitTestable().evaluate()) {
            final box = element.renderObject! as RenderBox;
            final rect = box.localToGlobal(Offset.zero) & box.size;
            // Only what shows on screen, and not in a list that scrolls
            // sideways (the map's sea): it passes under the edges, and its
            // ends scroll clear of them.
            if (!rect.overlaps(Offset.zero & size)) continue;
            final list = Scrollable.maybeOf(element);
            if (list != null && list.position.axis == Axis.horizontal) continue;
            if (rect.left < safe.left - 0.5 || rect.right > safe.right + 0.5) {
              clipped.add('$path: ${_describe(element)} at $rect');
            }
          }
        }
        expect(clipped, isEmpty);
        expect(tester.takeException(), isNull);
      });
    }
  }
}

/// The control's type, with its tooltip or words when it has them.
String _describe(Element element) {
  String? label;
  element.visitChildElements((_) {});
  void find(Element e) {
    if (label != null) return;
    final widget = e.widget;
    if (widget is Tooltip) label = widget.message;
    if (widget is Text) label = widget.data;
    e.visitChildElements(find);
  }

  find(element);
  return '${element.widget.runtimeType}(${label ?? ''})';
}
