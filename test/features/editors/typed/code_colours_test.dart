import 'package:cobalagi/features/editors/blocks/data/block.dart';
import 'package:cobalagi/features/editors/blocks/view/block_tile.dart';
import 'package:cobalagi/features/editors/typed/view/typed_code_editor.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

Color? colourOf(List<TextSpan> spans, String word) =>
    spans.firstWhere((s) => s.text!.contains(word)).style?.color;

Color shade(BlockType type) =>
    Color.lerp(type.color, const Color(0xFF000000), 0.18)!;

void main() {
  test('commands take their block colours; comments are grey', () {
    final spans = colouredCode(
      'repeat(3) {\n  move();\n  turn_left();\n  turn_right(); // here\n}\n'
      'steps = 2;\nmove(steps);\nuntil_flag {\n}\nstar();\n',
    );
    expect(spans.map((s) => s.text).join(), contains('turn_left();'));
    expect(colourOf(spans, 'repeat'), shade(BlockType.repeat));
    expect(colourOf(spans, 'turn_left'), shade(BlockType.turnLeft));
    expect(colourOf(spans, 'turn_right'), shade(BlockType.turnRight));
    expect(colourOf(spans, 'until_flag'), shade(BlockType.untilGoal));
    expect(colourOf(spans, 'star'), shade(BlockType.star));
    expect(colourOf(spans, 'move(steps)'), shade(BlockType.moveSteps));
    expect(colourOf(spans, '// here'), const Color(0xFF7A8A8A));
    // Plain move() is forward-green, not the Step Box colour.
    final plain = colouredCode('move();');
    expect(colourOf(plain, 'move'), shade(BlockType.forward));
    // Punctuation and numbers keep the editor's own colour.
    expect(colourOf(colouredCode('repeat(3)'), '(3)'), isNull);
  });

  test('the text is never changed, only coloured', () {
    const code = 'repeat(2) {\n  move(); // go\n}';
    expect(colouredCode(code).map((s) => s.text).join(), code);
    expect(colouredCode(''), isEmpty);
  });
}
