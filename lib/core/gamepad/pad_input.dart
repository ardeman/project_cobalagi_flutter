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

  /// Pressing the left stick down.
  leftStick('L3'),

  /// Pressing the right stick down.
  rightStick('R3'),

  /// Held to carry a block; letting go puts it down ([PadRelease]).
  rightTrigger('R2'),

  /// The menu (start) button, ☰ on the Steam Deck: listen again.
  menu('☰'),

  /// The view (select) button, ⧉ on the Steam Deck: the screen's tour.
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

/// The left stick's lean while R2 is held: it drags a block freely, like a
/// mouse, instead of stepping it. [x] and [y] run from -1 to 1, [y]
/// positive down the screen; both 0 when the stick rests.
final class PadAim extends PadCommand {
  const PadAim(this.x, this.y);

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      other is PadAim && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'PadAim($x, $y)';
}

/// A held button let go. Reported only for buttons that are held on
/// purpose ([PadInput.held]).
final class PadRelease extends PadCommand {
  const PadRelease(this.button);

  final PadButton button;

  @override
  bool operator ==(Object other) =>
      other is PadRelease && other.button == button;

  @override
  int get hashCode => button.hashCode;

  @override
  String toString() => 'PadRelease($button)';
}

/// The right stick leaned to scroll: [speed] from -1 (up) to 1 (down), 0
/// when it is back in the middle. Scrolling goes on while it leans.
final class PadScroll extends PadCommand {
  const PadScroll(this.speed);

  final double speed;

  @override
  bool operator ==(Object other) => other is PadScroll && other.speed == speed;

  @override
  int get hashCode => speed.hashCode;

  @override
  String toString() => 'PadScroll($speed)';
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

  /// Below this lean the right stick rests, so a worn stick doesn't drift.
  static const scrollFrom = 0.25;

  double _scroll = 0;

  /// The right stick moved up or down; [y] is positive up. Reports only
  /// changes, as a speed with the resting zone taken out.
  PadCommand? scrollStick(double y) {
    final lean = y.abs() < scrollFrom
        ? 0.0
        : -y.sign * (y.abs() - scrollFrom) / (1 - scrollFrom);
    if ((lean - _scroll).abs() < 0.05 && (lean == 0) == (_scroll == 0)) {
      return null;
    }
    _scroll = lean;
    return PadScroll(lean);
  }

  /// Buttons held on purpose, which also report letting go.
  static const held = {PadButton.rightTrigger};

  /// A button changed; [down] is true while it is held.
  PadCommand? button(PadButton button, {required bool down}) {
    if (!down && held.contains(button) && _down.contains(button)) {
      _down.remove(button);
      return PadRelease(button);
    }
    return _edge(button, down) ? PadPress(button) : null;
  }

  /// A trigger moved, from 0 (resting) to 1 (pressed all the way): pressed
  /// past half way, let go below a third, so a light finger doesn't drop a
  /// carried block.
  PadCommand? trigger(PadButton trigger, double value) {
    final down = _down.contains(trigger);
    if (!down && value > 0.5) return button(trigger, down: true);
    if (down && value < 0.33) return button(trigger, down: false);
    return null;
  }

  /// A d-pad direction changed.
  PadCommand? dpad(PadDirection direction, {required bool down}) =>
      _edge(direction, down) ? PadMove(direction) : null;

  /// Below this the stick rests while aiming.
  static const aimFrom = 0.15;

  double _aimX = 0;
  double _aimY = 0;

  /// The left stick moved; [y] is positive up, as the controller reports it.
  /// With R2 held it aims ([PadAim]); otherwise each push moves ([PadMove]).
  PadCommand? stick({double? x, double? y}) {
    _x = x ?? _x;
    _y = y ?? _y;
    final lean = _x.abs() > _y.abs() ? _x.abs() : _y.abs();
    if (_down.contains(PadButton.rightTrigger)) {
      // A lean used for aiming isn't a push once R2 is let go.
      _stick = lean < releaseAt ? null : (_stick ?? PadDirection.up);
      double rest(double v) => v.abs() < aimFrom
          ? 0
          : ((v.abs() - aimFrom) / (1 - aimFrom) * v.sign * 20).round() / 20;
      final aimX = rest(_x);
      final aimY = rest(-_y);
      if (aimX == _aimX && aimY == _aimY) return null;
      _aimX = aimX;
      _aimY = aimY;
      return PadAim(aimX, aimY);
    }
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
