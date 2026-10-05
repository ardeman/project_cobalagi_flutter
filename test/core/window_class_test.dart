import 'package:cobalagi/core/responsive/window_class.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps widths to Material 3 window classes', () {
    expect(WindowClass.fromWidth(400), WindowClass.compact);
    expect(WindowClass.fromWidth(600), WindowClass.medium);
    expect(WindowClass.fromWidth(839), WindowClass.medium);
    expect(WindowClass.fromWidth(840), WindowClass.expanded);
    expect(WindowClass.fromWidth(2560), WindowClass.expanded);
  });
}
