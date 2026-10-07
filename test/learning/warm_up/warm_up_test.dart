import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cobalagi/core/audio/voice_clips.dart';
import 'package:cobalagi/learning/learner_state.dart';
import 'package:cobalagi/learning/placement/pretest_generator.dart';
import 'package:cobalagi/learning/placement/pretest_question.dart';
import 'package:cobalagi/learning/warm_up/warm_up.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;

final vocabulary =
    readJson('assets/config/pretest.json')['vocabulary']!
        as Map<String, Object?>;
final config = WarmUpConfig.fromJson(readJson('assets/config/warm_up.json'));

PretestGenerator generator(int seed) =>
    PretestGenerator.fromJson(vocabulary, Random(seed));

void main() {
  test('the island lists every game once', () {
    expect(config.games.toSet(), hasLength(config.games.length));
    expect(config.roundLength, greaterThan(0));
  });

  group('colour questions', () {
    for (var level = 1; level <= maxSkillLevel; level++) {
      test('level $level has one right answer and a voice clip', () {
        for (var seed = 0; seed < 30; seed++) {
          final q = generator(seed).colorQuestion(level);
          expect(q.optionCount, level + 1);
          expect(q.options[q.correct].color, q.color);
          expect(
            q.options.where((p) => p.color == q.color),
            hasLength(1),
            reason: 'only one picture has the colour',
          );
          expect(VoiceClips.warmUpColors, contains(q.color));
        }
      });
    }
  });

  group('shape questions', () {
    for (var level = 1; level <= maxSkillLevel; level++) {
      test('level $level has one right answer and a voice clip', () {
        for (var seed = 0; seed < 30; seed++) {
          final q = generator(seed).shapeQuestion(level);
          expect(q.optionCount, level + 1);
          expect(q.options[q.correct].object, q.shape);
          expect(q.options.where((p) => p.object == q.shape), hasLength(1));
          expect(VoiceClips.warmUpShapes, contains(q.shape));
        }
      });
    }
  });

  test('every game asks well-formed questions at every level', () {
    for (final game in WarmUpGame.values) {
      for (var level = 1; level <= maxSkillLevel; level++) {
        final q = game.question(generator(level), level);
        expect(q.correct, inInclusiveRange(0, q.optionCount - 1));
      }
    }
  });

  group('a round', () {
    WarmUpRound round({int best = 0}) => WarmUpRound(
      game: WarmUpGame.counting,
      generator: generator(1),
      length: 5,
      best: best,
    );

    test('has the configured number of questions', () {
      final r = round();
      var asked = 0;
      while (!r.isFinished) {
        r.answer(r.current!.correct);
        asked++;
      }
      expect(asked, 5);
      expect(r.progress, 1);
      expect(r.rightAnswers, 5);
    });

    test('goes up after a right answer and down after a wrong one', () {
      final r = round();
      expect(r.current!.level, 1);
      r.answer(r.current!.correct);
      expect(r.current!.level, 2);
      r.answer((r.current!.correct + 1) % r.current!.optionCount);
      expect(r.current!.level, 1);
      expect(r.best, 1, reason: "level 2 was not answered right");
    });

    test('starts at the best level so far', () {
      expect(round(best: 3).current!.level, 3);
    });
  });

  test('island stars are the average best level, rounded down', () {
    final all = {for (final g in config.games) g.name: 3};
    expect(config.islandStars(all), 3);
    expect(config.islandStars({}), 0);
    expect(config.gamesPlayed({'counting': 1}), 1);
  });

  test('best levels survive a save', () {
    const learner = LearnerState(
      currentConcept: 'directions',
      warmUp: {'colors': 2},
    );
    final back = LearnerState.fromJson(
      jsonDecode(jsonEncode(learner.toJson())) as Map<String, Object?>,
    );
    expect(back.warmUp, {'colors': 2});
  });
}
