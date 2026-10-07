import 'learner_state.dart';
import 'placement/pretest_question.dart';
import 'warm_up/warm_up.dart';

/// One sticker in a child's sticker book.
final class Sticker {
  const Sticker({required this.id, required this.earned, this.game});

  /// An island's concept id, or `warmup-<game>` for a Warm-up game.
  final String id;

  /// The Warm-up game, or null for a coding island.
  final WarmUpGame? game;

  final bool earned;
}

/// The sticker book: one sticker per coding island, earned when all its
/// lessons are solved, and one per Warm-up game, earned at three stars.
/// Worked out from progress, so nothing extra is stored but which stickers
/// the child has already seen.
List<Sticker> stickerBook(
  LearnerState state, {
  required List<String> islands,
  required Map<String, List<String>> lessons,
  required List<WarmUpGame> games,
}) => [
  for (final island in islands)
    Sticker(
      id: island,
      earned: switch (lessons[island]) {
        final ids? when ids.isNotEmpty => ids.every(
          (id) => state.progress[island]?.solvedLessons.contains(id) ?? false,
        ),
        _ => false,
      },
    ),
  for (final game in games)
    Sticker(
      id: 'warmup-${game.name}',
      game: game,
      earned: (state.warmUp[game.name] ?? 0) >= maxSkillLevel,
    ),
];

/// Earned stickers the child hasn't seen in the book yet.
Set<String> newStickers(LearnerState state, List<Sticker> book) => {
  for (final s in book)
    if (s.earned && !state.stickersSeen.contains(s.id)) s.id,
};
