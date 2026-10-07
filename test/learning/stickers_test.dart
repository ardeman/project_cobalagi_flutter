import 'dart:convert';

import 'package:cobalagi/learning/learner_state.dart';
import 'package:cobalagi/learning/stickers.dart';
import 'package:cobalagi/learning/warm_up/warm_up.dart';
import 'package:flutter_test/flutter_test.dart';

const lessons = {
  'directions': ['d1', 'd2'],
  'loops': ['l1', 'l2'],
};

List<Sticker> book(LearnerState state) => stickerBook(
  state,
  islands: const ['directions', 'loops'],
  lessons: lessons,
  games: const [WarmUpGame.counting, WarmUpGame.colors],
);

void main() {
  const state = LearnerState(
    currentConcept: 'loops',
    progress: {
      'directions': ConceptProgress(difficulty: 1, solvedLessons: {'d1', 'd2'}),
      'loops': ConceptProgress(difficulty: 1, solvedLessons: {'l1'}),
    },
    warmUp: {'counting': 3, 'colors': 2},
  );

  test('an island earns its sticker when every lesson is solved', () {
    final stickers = {for (final s in book(state)) s.id: s.earned};
    expect(stickers['directions'], isTrue);
    expect(stickers['loops'], isFalse);
  });

  test('a Warm-up game earns its sticker at three stars', () {
    final stickers = {for (final s in book(state)) s.id: s.earned};
    expect(stickers['warmup-counting'], isTrue);
    expect(stickers['warmup-colors'], isFalse);
  });

  test('new stickers are earned ones not yet seen', () {
    expect(newStickers(state, book(state)), {'directions', 'warmup-counting'});
    final seen = state.copyWith(stickersSeen: {'directions'});
    expect(newStickers(seen, book(seen)), {'warmup-counting'});
  });

  test('seen stickers survive a save', () {
    final seen = state.copyWith(stickersSeen: {'directions'});
    final back = LearnerState.fromJson(
      jsonDecode(jsonEncode(seen.toJson())) as Map<String, Object?>,
    );
    expect(back.stickersSeen, {'directions'});
  });
}
