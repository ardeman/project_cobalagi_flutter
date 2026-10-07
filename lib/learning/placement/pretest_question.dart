import '../../engine/program/instruction.dart';
import '../../engine/world/direction.dart';
import '../../engine/world/level.dart';

/// Pre-skills the warm-up game checks. Each is scored 0 (not yet) to 3.
enum PretestSkill { reading, counting, direction, pattern, sequencing }

const maxSkillLevel = 3;

/// A picture: an object id from the vocabulary, optionally in a color.
final class Picture {
  const Picture(this.object, [this.color]);

  final String object;
  final String? color;

  @override
  bool operator ==(Object other) =>
      other is Picture && other.object == object && other.color == color;

  @override
  int get hashCode => Object.hash(object, color);
}

enum Side { left, right }

/// One picture-based question. The child answers by tapping an option;
/// [correct] is the index of the right one. Words are ids, rendered in the
/// child's language by the view.
sealed class PretestQuestion {
  const PretestQuestion({required this.level, required this.correct});

  final int level;
  final int correct;

  /// The warm-up skill this question checks; null for questions only the
  /// Warm-up island asks, such as colours and shapes.
  PretestSkill? get skill;

  int get optionCount;
}

/// Shows written words; the child picks the matching picture.
final class ReadingQuestion extends PretestQuestion {
  const ReadingQuestion({
    required super.level,
    required super.correct,
    required this.words,
    required this.options,
  });

  /// What is written: an object, plus a color word at the top level.
  final Picture words;
  final List<Picture> options;

  @override
  PretestSkill get skill => PretestSkill.reading;

  @override
  int get optionCount => options.length;
}

/// Shows [count] pictures; the child picks the number.
final class CountingQuestion extends PretestQuestion {
  const CountingQuestion({
    required super.level,
    required super.correct,
    required this.object,
    required this.count,
    required this.options,
  });

  final String object;
  final int count;
  final List<int> options;

  @override
  PretestSkill get skill => PretestSkill.counting;

  @override
  int get optionCount => options.length;
}

/// "Tap the star on the left": two pictures, one on each side.
final class SideQuestion extends PretestQuestion {
  const SideQuestion({
    required super.level,
    required super.correct,
    required this.target,
  });

  final Side target;

  /// Option 0 is the left picture, option 1 the right one.
  @override
  int get optionCount => 2;

  @override
  PretestSkill get skill => PretestSkill.direction;
}

/// "The bird turns right. Where does it look now?"
final class TurnQuestion extends PretestQuestion {
  const TurnQuestion({
    required super.level,
    required super.correct,
    required this.facing,
    required this.turn,
    required this.options,
  });

  final Direction facing;
  final Side turn;
  final List<Direction> options;

  @override
  PretestSkill get skill => PretestSkill.direction;

  @override
  int get optionCount => options.length;
}

/// A repeating row of shapes with the next one missing.
final class PatternQuestion extends PretestQuestion {
  const PatternQuestion({
    required super.level,
    required super.correct,
    required this.sequence,
    required this.options,
  });

  /// Shapes are pictures too: the object is a shape id.
  final List<Picture> sequence;
  final List<Picture> options;

  @override
  PretestSkill get skill => PretestSkill.pattern;

  @override
  int get optionCount => options.length;
}

/// A tiny map; the child picks the row of steps that reaches the flag.
final class SequencingQuestion extends PretestQuestion {
  const SequencingQuestion({
    required super.level,
    required super.correct,
    required this.map,
    required this.options,
  });

  final Level map;
  final List<List<InstructionKind>> options;

  @override
  PretestSkill get skill => PretestSkill.sequencing;

  @override
  int get optionCount => options.length;
}

/// "Tap the red one!": the same kind of picture in different colours.
final class ColorQuestion extends PretestQuestion {
  const ColorQuestion({
    required super.level,
    required super.correct,
    required this.color,
    required this.options,
  });

  /// The colour id to find.
  final String color;
  final List<Picture> options;

  @override
  PretestSkill? get skill => null;

  @override
  int get optionCount => options.length;
}

/// "Tap the circle!": shapes, where the colours don't give it away.
final class ShapeQuestion extends PretestQuestion {
  const ShapeQuestion({
    required super.level,
    required super.correct,
    required this.shape,
    required this.options,
  });

  /// The shape id to find, one of `patternShapes`.
  final String shape;
  final List<Picture> options;

  @override
  PretestSkill? get skill => null;

  @override
  int get optionCount => options.length;
}
