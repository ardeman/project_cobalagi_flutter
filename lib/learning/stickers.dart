import 'learner_state.dart';
import 'placement/pretest_question.dart';
import 'warm_up/warm_up.dart';

/// One sticker in a child's sticker book.
final class Sticker {
  const Sticker({
    required this.id,
    required this.earned,
    this.game,
    this.gold = false,
  });

  /// An island's concept id, or `warmup-<game>` for a Warm-up game.
  final String id;

  /// The Warm-up game, or null for a coding island.
  final WarmUpGame? game;

  final bool earned;

  /// A coding island with three stars on every lesson. (A Warm-up game's
  /// sticker already takes three stars, so it has nothing more to collect.)
  final bool gold;

  /// The id [newStickers] uses once this sticker has turned gold.
  String get goldId => '$id:gold';
}

/// The sticker book: one sticker per coding island, earned when all its
/// lessons are solved and gold at three stars on each, and one per Warm-up
/// game, earned at three stars.
/// Worked out from progress, so nothing extra is stored but which stickers
/// the child has already seen.
List<Sticker> stickerBook(
  LearnerState state, {
  required List<String> islands,
  required Map<String, List<String>> lessons,
  required List<WarmUpGame> games,
}) => [
  for (final island in islands)
    if ((lessons[island] ?? const <String>[]) case final ids
        when ids.isNotEmpty)
      Sticker(
        id: island,
        earned: ids.every(
          (id) => state.progress[island]?.solvedLessons.contains(id) ?? false,
        ),
        gold: ids.every(
          (id) => (state.progress[island]?.starsOf(id) ?? 0) >= 3,
        ),
      )
    else
      Sticker(id: island, earned: false),
  for (final game in games)
    Sticker(
      id: 'warmup-${game.name}',
      game: game,
      earned: (state.warmUp[game.name] ?? 0) >= maxSkillLevel,
    ),
];

/// Earned stickers the child hasn't seen in the book yet, and stickers
/// that turned gold since (as [Sticker.goldId]).
Set<String> newStickers(LearnerState state, List<Sticker> book) => {
  for (final s in book) ...[
    if (s.earned && !state.stickersSeen.contains(s.id)) s.id,
    if (s.gold && !state.stickersSeen.contains(s.goldId)) s.goldId,
  ],
};
