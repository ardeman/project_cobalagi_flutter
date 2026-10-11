import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/features/pretest/view/question_game.dart';
import 'package:cobalagi/features/pretest/view/question_views.dart';
import 'package:cobalagi/learning/placement/pretest_generator.dart';
import 'package:cobalagi/learning/placement/pretest_question.dart';
import 'package:cobalagi/learning/placement/question_round.dart';
import 'package:cobalagi/learning/warm_up/warm_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// One question that stays on screen.
class _OneQuestion implements QuestionRound {
  _OneQuestion(this.current);

  @override
  final PretestQuestion current;

  @override
  bool get isFinished => false;

  @override
  int get questionsAsked => 1;

  @override
  double get progress => 0;

  @override
  bool answer(int option) => true;
}

final _vocabulary =
    (jsonDecode(File('assets/config/pretest.json').readAsStringSync())
            as Map<String, Object?>)['vocabulary']!
        as Map<String, Object?>;

/// Phones and tablets, upright and held sideways.
const _screens = [
  Size(360, 640),
  Size(400, 760),
  Size(412, 915),
  Size(640, 360),
  Size(760, 400),
  Size(915, 412),
  Size(1024, 600),
  Size(1280, 800),
  Size(800, 1280),
];

void main() {
  // Every Warm-up game, plus reading (only in the first warm-up).
  final games = <String, PretestQuestion Function(PretestGenerator, int)>{
    for (final game in WarmUpGame.values) game.name: game.question,
    'reading': (g, level) => g.question(PretestSkill.reading, level),
  };
  for (final screen in _screens) {
    testWidgets('warm-up games fit without scrolling on $screen', (
      tester,
    ) async {
      tester.view.physicalSize = screen;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final MapEntry(key: name, value: make) in games.entries) {
        for (var level = 1; level <= maxSkillLevel; level++) {
          for (var seed = 0; seed < 4; seed++) {
            final question = make(
              PretestGenerator.fromJson(_vocabulary, Random(seed)),
              level,
            );
            await tester.pumpWidget(
              RepositoryProvider<AudioService>(
                create: (_) => const SilentAudioService(),
                child: MaterialApp(
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: QuestionGame(
                    key: UniqueKey(),
                    round: _OneQuestion(question),
                    steps: 5,
                    onClose: () {},
                    onFinished: () async {},
                    doneClip: 'none',
                    done: (_) => const SizedBox(),
                  ),
                ),
              ),
            );
            await tester.pump(const Duration(milliseconds: 300));
            final what = '$name level $level (seed $seed)';
            expect(tester.takeException(), isNull, reason: what);
            for (final state in tester.stateList<ScrollableState>(
              find.byType(Scrollable),
            )) {
              expect(
                state.position.maxScrollExtent,
                0,
                reason: '$what scrolls',
              );
            }
            // Every picture stays on screen, as big as a finger.
            final view = tester.getRect(find.byType(QuestionView));
            expect(view.top, greaterThanOrEqualTo(0), reason: what);
            expect(view.bottom, lessThanOrEqualTo(screen.height), reason: what);
            for (final card in tester.widgetList<Card>(find.byType(Card))) {
              // As drawn, after any shrinking to fit.
              final size = tester.getRect(find.byWidget(card)).size;
              expect(
                size.shortestSide,
                greaterThanOrEqualTo(64),
                reason: '$what: answer too small',
              );
            }
          }
        }
      }
    });
  }
}
