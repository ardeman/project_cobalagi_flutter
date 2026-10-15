/// The controller buttons the app uses. Labels follow the Steam Deck and
/// Xbox pads ([PadButton.label]).
enum PadButton {
  /// Presses the highlighted control.
  a('A'),

  /// Goes back.
  b('B'),
  x('X'),
  y('Y'),
  leftBumper('L1'),
  rightBumper('R1'),

  /// The menu (start) button, ☰ on the Steam Deck.
  menu('☰'),

  /// The view (select) button, ⧉ on the Steam Deck.
  view('⧉');

  const PadButton(this.label);

  /// What the button says on the controller, shown on the matching control.
  final String label;
}

enum PadDirection { up, down, left, right }

/// One thing the child did on the controller.
sealed class PadCommand {
  const PadCommand();
}

/// A push of the d-pad or the left stick: the highlight jumps that way.
final class PadMove extends PadCommand {
  const PadMove(this.direction);

  final PadDirection direction;

  @override
  bool operator ==(Object other) =>
      other is PadMove && other.direction == direction;

  @override
  int get hashCode => direction.hashCode;

  @override
  String toString() => 'PadMove($direction)';
}

/// A button pushed down (releasing it does nothing).
final class PadPress extends PadCommand {
  const PadPress(this.button);

  final PadButton button;

  @override
  bool operator ==(Object other) => other is PadPress && other.button == button;

  @override
  int get hashCode => button.hashCode;

  @override
  String toString() => 'PadPress($button)';
}

/// Turns raw controller input into [PadCommand]s: one command per push, so a
/// held button or stick never races through the screen.
class PadInput {
  /// How far the stick must lean to count as a push, and how far back it
  /// must come before the next one; the gap stops a wobble from repeating.
  static const pushAt = 0.6;
  static const releaseAt = 0.3;

  final _down = <Object>{};
  double _x = 0;
  double _y = 0;
  PadDirection? _stick;

  /// A button changed; [down] is true while it is held.
  PadCommand? button(PadButton button, {required bool down}) =>
      _edge(button, down) ? PadPress(button) : null;

  /// A d-pad direction changed.
  PadCommand? dpad(PadDirection direction, {required bool down}) =>
      _edge(direction, down) ? PadMove(direction) : null;

  /// The left stick moved; [y] is positive up, as the controller reports it.
  PadCommand? stick({double? x, double? y}) {
    _x = x ?? _x;
    _y = y ?? _y;
    final lean = _x.abs() > _y.abs() ? _x.abs() : _y.abs();
    if (_stick != null) {
      if (lean < releaseAt) _stick = null;
      return null;
    }
    if (lean < pushAt) return null;
    _stick = _x.abs() > _y.abs()
        ? (_x > 0 ? PadDirection.right : PadDirection.left)
        : (_y > 0 ? PadDirection.up : PadDirection.down);
    return PadMove(_stick!);
  }

  /// True only when [key] goes down, not while it stays down.
  bool _edge(Object key, bool down) {
    if (!down) {
      _down.remove(key);
      return false;
    }
    return _down.add(key);
  }
}
