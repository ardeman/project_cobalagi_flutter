import '../placement/pretest_generator.dart';
import '../placement/pretest_question.dart';
import '../placement/question_round.dart';

/// Island id of the Warm-up island on the map. It is not a coding concept:
/// it holds the picture games, always open and outside the learning path.
const warmUpIsland = 'warmup';

/// A picture game on the Warm-up island. New games go here, with a question
/// type, a prompt and a picture; `assets/config/warm_up.json` lists the ones
/// the island shows, in order.
enum WarmUpGame {
  counting,
  colors,
  shapes,
  patterns,
  sides,
  steps;

  /// A question of this game at [level] (1 to [maxSkillLevel]).
  PretestQuestion question(PretestGenerator generator, int level) =>
      switch (this) {
        counting => generator.question(PretestSkill.counting, level),
        colors => generator.colorQuestion(level),
        shapes => generator.shapeQuestion(level),
        patterns => generator.question(PretestSkill.pattern, level),
        sides => generator.question(PretestSkill.direction, level),
        steps => generator.question(PretestSkill.sequencing, level),
      };
}

/// The Warm-up island's settings, from `assets/config/warm_up.json`.
final class WarmUpConfig {
  const WarmUpConfig({required this.roundLength, required this.games});

  factory WarmUpConfig.fromJson(Map<String, Object?> json) => WarmUpConfig(
    roundLength: json['roundLength']! as int,
    games: [
      for (final name in (json['games']! as List).cast<String>())
        WarmUpGame.values.byName(name),
    ],
  );

  /// Questions in one round of a game.
  final int roundLength;

  /// The games on the island, in order.
  final List<WarmUpGame> games;

  /// The island's stars: the average best level over its games, rounded
  /// down, so three stars mean every game reached the top level.
  int islandStars(Map<String, int> best) => games.isEmpty
      ? 0
      : games.map((g) => best[g.name] ?? 0).reduce((a, b) => a + b) ~/
            games.length;

  /// Games played with at least one right answer.
  int gamesPlayed(Map<String, int> best) =>
      games.where((g) => (best[g.name] ?? 0) > 0).length;
}

/// One round of a Warm-up island game. It starts at the child's best level
/// so far, goes up a level after a right answer and down one after a wrong
/// one, so it stays fun for a three-year-old and for a reader alike.
final class WarmUpRound implements QuestionRound {
  WarmUpRound({
    required this.game,
    required PretestGenerator generator,
    required this.length,
    this.best = 0,
  }) : _generator = generator,
       _level = best.clamp(1, maxSkillLevel) {
    _current = game.question(_generator, _level);
  }

  final WarmUpGame game;
  final int length;
  final PretestGenerator _generator;
  int _level;
  var _answered = 0;
  PretestQuestion? _current;

  /// Highest level answered right, including earlier rounds.
  int best;

  /// Right answers in this round.
  var rightAnswers = 0;

  @override
  PretestQuestion? get current => _current;

  @override
  bool get isFinished => _current == null;

  @override
  int get questionsAsked => _answered + (isFinished ? 0 : 1);

  @override
  double get progress => _answered / length;

  @override
  bool answer(int option) {
    final question = _current;
    if (question == null) throw StateError('the round is finished');
    final right = option == question.correct;
    _answered++;
    if (right) {
      rightAnswers++;
      if (_level > best) best = _level;
      if (_level < maxSkillLevel) _level++;
    } else if (_level > 1) {
      _level--;
    }
    _current = _answered == length ? null : game.question(_generator, _level);
    return right;
  }
}
