import 'pretest_generator.dart';
import 'pretest_question.dart';
import 'question_round.dart';

/// The first warm-up game, kept short: per skill it asks only the levels
/// placement looks at ([checkpoints], highest first) and stops at the first
/// right answer. After a wrong answer the child gets [secondChances] more
/// questions at the same level, so one stray tap doesn't place them too low;
/// then it tries the next lower checkpoint. Everything else (and practice to
/// three stars) is on the Warm-up island.
final class PretestSession implements QuestionRound {
  PretestSession(
    this._generator, {
    required this.secondChances,
    required Map<PretestSkill, List<int>> checkpoints,
  }) : _checkpoints = checkpoints,
       _skills = [
         for (final skill in PretestSkill.values)
           if (checkpoints[skill]?.isNotEmpty ?? false) skill,
       ] {
    _chancesLeft = secondChances;
    _current = _skills.isEmpty ? null : _ask();
  }

  /// Extra questions per skill after a wrong answer (pretest.json).
  final int secondChances;
  var _chancesLeft = 0;

  final PretestGenerator _generator;
  final Map<PretestSkill, List<int>> _checkpoints;
  final List<PretestSkill> _skills;
  final _levels = <PretestSkill, int>{};
  var _skillIndex = 0;
  var _checkpoint = 0;
  var _asked = 1;
  PretestQuestion? _current;

  /// The skills this warm-up checks, in order.
  List<PretestSkill> get skills => _skills;

  PretestQuestion _ask() => _generator.question(
    _skills[_skillIndex],
    _checkpoints[_skills[_skillIndex]]![_checkpoint],
  );

  @override
  PretestQuestion? get current => _current;

  @override
  bool get isFinished => _current == null;

  @override
  int get questionsAsked => _asked;

  /// Highest checkpoint answered right per skill (0 if none); complete once
  /// [isFinished].
  Map<PretestSkill, int> get levels => {
    for (final skill in PretestSkill.values) skill: _levels[skill] ?? 0,
  };

  /// Progress from 0 to 1, by skills finished.
  @override
  double get progress => _skills.isEmpty ? 1 : _skillIndex / _skills.length;

  /// Records [option] and returns whether it was right.
  @override
  bool answer(int option) {
    final question = _current;
    if (question == null) throw StateError('the pretest is finished');
    final right = option == question.correct;
    final levels = _checkpoints[_skills[_skillIndex]]!;
    if (right) {
      _levels[question.skill!] = question.level;
      _nextSkill();
    } else if (_chancesLeft > 0) {
      // Another question at the same level.
      _chancesLeft--;
    } else if (_checkpoint + 1 < levels.length) {
      _checkpoint++;
      _chancesLeft = secondChances;
    } else {
      _nextSkill();
    }
    if (_skillIndex == _skills.length) {
      _current = null;
      return right;
    }
    _current = _ask();
    _asked++;
    return right;
  }

  void _nextSkill() {
    _skillIndex++;
    _checkpoint = 0;
    _chancesLeft = secondChances;
  }
}
