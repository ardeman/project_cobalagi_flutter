import 'dart:ui';

import 'package:cobalagi/features/play/view/world/ink.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('solid shapes get a navy outline, see-through shadows none', () async {
    const bounds = Rect.fromLTWH(0, 0, 1, 1);
    final image = inkedPiece(
      (canvas) => canvas
        // A solid square on the left, a soft shadow on the right.
        ..drawRect(
          const Rect.fromLTWH(0.1, 0.3, 0.3, 0.4),
          Paint()..color = const Color(0xFFFFFFFF),
        )
        ..drawRect(
          const Rect.fromLTWH(0.6, 0.3, 0.3, 0.4),
          Paint()..color = const Color(0x33000000),
        ),
      bounds: bounds,
      width: 0.05,
      pixelsPerUnit: 100,
    );
    final bytes = (await image.toByteData())!;
    Color at(int x, int y) {
      final i = (y * image.width + x) * 4;
      return Color.fromARGB(
        bytes.getUint8(i + 3),
        bytes.getUint8(i),
        bytes.getUint8(i + 1),
        bytes.getUint8(i + 2),
      );
    }

    // Just left of the square: the outline, in ink.
    expect(at(7, 50), ink);
    // Inside the square: the square itself.
    expect(at(25, 50), const Color(0xFFFFFFFF));
    // Just left of the shadow: nothing.
    expect(at(57, 50).a, 0);
    image.dispose();
  });
}
