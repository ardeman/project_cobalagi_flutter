import 'pretest_generator.dart';
import 'pretest_question.dart';
import 'question_round.dart';

/// The adaptive warm-up game: each skill starts at level 1 and goes up a
/// level after a right answer, until the top level. After a wrong answer the
/// child gets [secondChances] more questions at the same level per skill, so
/// one stray tap doesn't place them too low; the next wrong answer ends the
/// skill.
final class PretestSession implements QuestionRound {
  PretestSession(this._generator, {required this.secondChances}) {
    _current = _generator.question(_skills.first, 1);
    _chancesLeft = secondChances;
  }

  /// Extra questions per skill after a wrong answer (pretest.json).
  final int secondChances;
  var _chancesLeft = 0;

  static const _skills = PretestSkill.values;

  final PretestGenerator _generator;
  final _levels = <PretestSkill, int>{};
  var _skillIndex = 0;
  var _level = 1;
  var _asked = 1;
  PretestQuestion? _current;

  /// The question to show, or null once finished.
  @override
  PretestQuestion? get current => _current;

  @override
  bool get isFinished => _current == null;

  @override
  int get questionsAsked => _asked;

  /// Highest level answered right per skill (0 if none); complete once
  /// [isFinished].
  Map<PretestSkill, int> get levels => {
    for (final skill in _skills) skill: _levels[skill] ?? 0,
  };

  /// Progress from 0 to 1, by skills finished.
  @override
  double get progress => _skillIndex / _skills.length;

  /// Records [option] and returns whether it was right.
  @override
  bool answer(int option) {
    final question = _current;
    if (question == null) throw StateError('the pretest is finished');
    final right = option == question.correct;
    if (right) _levels[question.skill!] = _level;
    if (right && _level < maxSkillLevel) {
      _level++;
    } else if (!right && _chancesLeft > 0) {
      // Another question at the same level.
      _chancesLeft--;
    } else {
      _skillIndex++;
      _level = 1;
      _chancesLeft = secondChances;
    }
    if (_skillIndex == _skills.length) {
      _current = null;
      return right;
    }
    _current = _generator.question(_skills[_skillIndex], _level);
    _asked++;
    return right;
  }
}
