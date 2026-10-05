import 'pretest_generator.dart';
import 'pretest_question.dart';

/// The adaptive warm-up game: each skill starts at level 1, goes up a level
/// after a right answer and stops after a wrong one or at the top level. That
/// is 5 to 15 questions in all.
final class PretestSession {
  PretestSession(this._generator) {
    _current = _generator.question(_skills.first, 1);
  }

  static const _skills = PretestSkill.values;

  final PretestGenerator _generator;
  final _levels = <PretestSkill, int>{};
  var _skillIndex = 0;
  var _level = 1;
  var _asked = 1;
  PretestQuestion? _current;

  /// The question to show, or null once finished.
  PretestQuestion? get current => _current;

  bool get isFinished => _current == null;

  int get questionsAsked => _asked;

  /// Highest level answered right per skill (0 if none); complete once
  /// [isFinished].
  Map<PretestSkill, int> get levels => {
    for (final skill in _skills) skill: _levels[skill] ?? 0,
  };

  /// Progress from 0 to 1, by skills finished.
  double get progress => _skillIndex / _skills.length;

  /// Records [option] and returns whether it was right.
  bool answer(int option) {
    final question = _current;
    if (question == null) throw StateError('the pretest is finished');
    final right = option == question.correct;
    if (right) _levels[question.skill] = _level;
    if (right && _level < maxSkillLevel) {
      _level++;
    } else {
      _skillIndex++;
      _level = 1;
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
