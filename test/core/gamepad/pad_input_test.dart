import 'package:cobalagi/core/gamepad/pad_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a held button presses once', () {
    final input = PadInput();
    expect(input.button(PadButton.a, down: true), const PadPress(PadButton.a));
    expect(input.button(PadButton.a, down: true), isNull);
    expect(input.button(PadButton.a, down: false), isNull);
    expect(input.button(PadButton.a, down: true), const PadPress(PadButton.a));
  });

  test('the d-pad moves once per push', () {
    final input = PadInput();
    expect(
      input.dpad(PadDirection.left, down: true),
      const PadMove(PadDirection.left),
    );
    expect(input.dpad(PadDirection.left, down: true), isNull);
    input.dpad(PadDirection.left, down: false);
    expect(
      input.dpad(PadDirection.left, down: true),
      const PadMove(PadDirection.left),
    );
  });

  test('the stick moves once per lean, the way it leans most', () {
    final input = PadInput();
    expect(input.stick(x: 0.4), isNull, reason: 'a small lean');
    expect(input.stick(y: 0.9), const PadMove(PadDirection.up));
    // Still leaning, or wobbling between the thresholds: no repeat.
    expect(input.stick(y: 1), isNull);
    expect(input.stick(x: 0, y: 0.5), isNull);
    expect(input.stick(y: 0.7), isNull);
    // Back near the middle, then a push down.
    expect(input.stick(y: 0.1), isNull);
    expect(input.stick(y: -0.8), const PadMove(PadDirection.down));
    input.stick(y: 0);
    expect(input.stick(x: 0.8, y: 0.3), const PadMove(PadDirection.right));
    input.stick(x: 0, y: 0);
    expect(input.stick(x: -0.7), const PadMove(PadDirection.left));
  });
}
