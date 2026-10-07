import 'package:flutter/widgets.dart';

/// How long a child has been playing puzzles since the last break: the
/// play screen [start]s it and [stop]s it, and it pauses on its own while
/// the app is in the background. Kept for the whole app session.
class PlayClock with WidgetsBindingObserver {
  PlayClock({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  var _played = Duration.zero;
  DateTime? _since;
  var _playing = false;
  var _foreground = true;

  /// Time spent on puzzles since the last [reset].
  Duration get played =>
      _played + (_since == null ? Duration.zero : _now().difference(_since!));

  /// Whether a break is due with a reminder after [minutes] (0: off).
  bool isDue(int minutes) =>
      minutes > 0 && played >= Duration(minutes: minutes);

  void start() {
    _playing = true;
    _update();
  }

  void stop() {
    _playing = false;
    _update();
  }

  /// After a break: counting starts again from zero.
  void reset() {
    _played = Duration.zero;
    _since = null;
    _update();
  }

  /// Follows the app going to the background and back.
  void attach() => WidgetsBinding.instance.addObserver(this);

  void detach() => WidgetsBinding.instance.removeObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _update();
  }

  void _update() {
    final counting = _playing && _foreground;
    if (counting && _since == null) {
      _since = _now();
    } else if (!counting && _since != null) {
      _played += _now().difference(_since!);
      _since = null;
    }
  }
}
