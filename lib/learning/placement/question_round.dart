import 'pretest_question.dart';

/// A run of picture questions the child answers one at a time: the
/// placement warm-up game, or a round of one Warm-up island game.
abstract interface class QuestionRound {
  /// The question to show, or null once finished.
  PretestQuestion? get current;

  bool get isFinished;

  /// Questions shown so far, including the current one.
  int get questionsAsked;

  /// Progress from 0 to 1.
  double get progress;

  /// Records [option] and returns whether it was right.
  bool answer(int option);
}
