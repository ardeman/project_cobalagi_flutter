import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cobalagi/core/responsive/fold.dart';
import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/app/theme/app_theme.dart';
import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/core/gamepad/gamepad_shortcut.dart';
import 'package:cobalagi/core/gamepad/pad_input.dart';
import 'package:cobalagi/core/widgets/glass_surface.dart';
import 'package:cobalagi/features/story/data/story_art.dart';
import 'package:cobalagi/features/story/data/story_scene.dart';

/// Plays a [StoryScene] of the Star fuel story: its pictures fill the screen
/// while each beat's voice speaks and its words show underneath. The child
/// only watches; Skip (B) leaves at any time, and at the end "Watch again"
/// and "Let's play!" fade in where the words were, so nothing moves.
///
/// With reduced motion each beat shows still, as it ends, for as long as it
/// speaks.
class StoryPlayer extends StatefulWidget {
  const StoryPlayer({
    super.key,
    required this.scene,
    required this.onDone,
    this.emblem,
  });

  final StoryScene scene;
  final VoidCallback onDone;

  /// The commander's emblem on the ship's hull ([StoryArt.emblem]).
  final (IconData, Color)? emblem;

  @override
  State<StoryPlayer> createState() => _StoryPlayerState();
}

class _StoryPlayerState extends State<StoryPlayer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _frame = ValueNotifier(const StoryFrame(beat: 0, t: 0, time: 0));
  late final AudioService _audio = context.read<AudioService>();
  StoryArt? _art;

  var _beat = 0;
  var _beatStart = Duration.zero;
  var _now = Duration.zero;

  /// How far the beat was on the last frame, for its sound effects.
  var _lastT = -1.0;
  var _voiceDone = false;
  var _finished = false;
  var _still = false;

  /// Bumped on every start and line, so a voice that ends late is ignored.
  var _line = 0;

  List<StoryBeat> get _beats => widget.scene.beats;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    StoryArt.load().then(
      (art) {
        if (mounted) setState(() => _art = art.withEmblem(widget.emblem));
      },
      // Without its pictures the scene still speaks.
      onError: (Object _) {},
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _start();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void dispose() {
    _line++;
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  /// Plays the scene from the beginning.
  void _start() {
    _ticker.stop();
    _now = Duration.zero;
    setState(() => _finished = false);
    _enter(0);
    _ticker.start();
  }

  void _enter(int beat) {
    setState(() => _beat = beat);
    _beatStart = _now;
    _lastT = -1;
    _speak();
  }

  /// Says the beat's line (again, from ☰); the beat goes on once it ends.
  void _speak() {
    final line = ++_line;
    _voiceDone = false;
    _audio
        .playVoice(
          _beats[_beat].clip,
          languageCode: Localizations.localeOf(context).languageCode,
        )
        .then((_) => _audio.whenIdle())
        .then((_) {
          if (line == _line) _voiceDone = true;
        });
  }

  void _tick(Duration elapsed) {
    _now = elapsed;
    final beat = _beats[_beat];
    final played = elapsed - _beatStart;
    final t = _still
        ? 1.0
        : (played.inMicroseconds / beat.length.inMicroseconds).clamp(0.0, 1.0);
    if (!_still) {
      for (final (at, effect) in beat.effects) {
        if (_lastT < at && t >= at) _audio.playEffect(effect);
      }
    }
    _lastT = t;
    _frame.value = StoryFrame(
      beat: _beat,
      t: t,
      time: elapsed.inMicroseconds / Duration.microsecondsPerSecond,
    );
    if (played < beat.length || !_voiceDone) return;
    if (_beat + 1 < _beats.length) {
      _enter(_beat + 1);
    } else {
      // The last picture stays; nothing moves while the child decides.
      _ticker.stop();
      setState(() => _finished = true);
    }
  }

  // Space is dark: the words and buttons are made for night, like the map's.
  @override
  Widget build(BuildContext context) => Theme(
    data: AppTheme.dark(),
    child: Builder(builder: _build),
  );

  Widget _build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final top = Row(
      children: [
        const Icon(Icons.theaters_rounded, color: Color(0xFFFFC83D), size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            l10n.storyTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        // Skip keeps its place when it goes, so the title doesn't move.
        Visibility(
          visible: !_finished,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          child: GamepadShortcut(
            button: PadButton.b,
            onPressed: _finished ? null : widget.onDone,
            child: TextButton(
              onPressed: widget.onDone,
              child: Text(l10n.tutorialSkip),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GamepadShortcut(
          button: PadButton.menu,
          onPressed: _speak,
          child: IconButton.filledTonal(
            tooltip: l10n.listenAgain,
            onPressed: _speak,
            icon: const Icon(Icons.volume_up_rounded),
          ),
        ),
      ],
    );
    final words = GlassSurface(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Text(
        _beats[_beat].words(l10n),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
    final endButtons = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GamepadShortcut(
            button: PadButton.view,
            onPressed: _finished ? _start : null,
            child: OutlinedButton.icon(
              onPressed: _start,
              icon: const Icon(Icons.replay_rounded),
              label: Text(l10n.tutorialWatchAgain),
            ),
          ),
          const SizedBox(width: 12),
          GamepadShortcut(
            button: PadButton.x,
            onPressed: _finished ? widget.onDone : null,
            child: FilledButton.icon(
              onPressed: widget.onDone,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(l10n.tutorialLetsPlay),
            ),
          ),
        ],
      ),
    );
    const fade = Duration(milliseconds: 250);
    final bottom = Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: double.infinity,
          // Half folded, the flat half has room to spare and is narrow:
          // three lines of words at full size.
          height: FoldHalves.of(context) == null
              ? _wordsHeight
              : _wordsHeight * 1.5,
        ),
        // The words wrap to the width there is (one half of a half-folded
        // phone, a narrow phone), and shrink only if they still don't fit.
        Positioned.fill(
          child: AnimatedOpacity(
            opacity: _finished ? 0 : 1,
            duration: fade,
            child: LayoutBuilder(
              builder: (context, box) => Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: box.maxWidth),
                    child: words,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !_finished,
            child: AnimatedOpacity(
              opacity: _finished ? 1 : 0,
              duration: fade,
              child: Center(child: endButtons),
            ),
          ),
        ),
      ],
    );
    final safe = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    // Half folded, the scene plays behind the fold, with the sky across
    // both halves, and the words and buttons lie flat in front of it.
    final halves = FoldHalves.of(context);
    final view = halves?.view;
    final controls = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [top, const Spacer(), bottom]),
    );
    // Light time and signal over the night sky.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _sky.first,
        body: Stack(
          children: [
            // The child watches: the scene takes no taps.
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: StoryScenePainter(
                    scene: widget.scene,
                    frame: _frame,
                    art: _art,
                    stage: view == null
                        ? EdgeInsets.fromLTRB(
                            safe.left + 16,
                            safe.top + 16 + 64,
                            safe.right + 16,
                            safe.bottom + 16 + _wordsHeight,
                          )
                        : EdgeInsets.fromLTRB(
                            max(view.left, safe.left) + 16,
                            max(view.top, safe.top) + 16,
                            max(size.width - view.right, safe.right) + 16,
                            max(size.height - view.bottom, safe.bottom) + 16,
                          ),
                    controls: halves == null
                        ? null
                        : _rowsRoom(halves, size, safe),
                  ),
                ),
              ),
            ),
            if (halves == null)
              SafeArea(child: controls)
            else
              FoldSplit(
                halves: halves,
                view: const SizedBox(),
                controls: SafeArea(child: controls),
              ),
          ],
        ),
      ),
    );
  }

  /// Room for the words, and for the end buttons in their place.
  static const _wordsHeight = 88.0;

  /// Half folded, the room in front of the fold between the title row and
  /// the words, where an arrival's program row goes.
  static Rect _rowsRoom(FoldHalves halves, Size size, EdgeInsets safe) {
    final c = halves.controls;
    return Rect.fromLTRB(
      c.left + (c.left <= 0 ? safe.left : 0) + 16,
      c.top + (c.top <= 0 ? safe.top : 0) + 16 + 64,
      c.right - (c.right >= size.width ? safe.right : 0) - 16,
      c.bottom -
          (c.bottom >= size.height ? safe.bottom : 0) -
          16 -
          _wordsHeight * 1.5,
    );
  }
}

const _sky = [Color(0xFF1A1F4E), Color(0xFF2B2468), Color(0xFF3B2A78)];

/// The same few stars on every frame, as fractions of the screen.
final _stars = () {
  final random = Random(7);
  return [
    for (var i = 0; i < 90; i++)
      (
        Offset(random.nextDouble(), random.nextDouble()),
        0.6 + random.nextDouble() * 1.6,
        random.nextDouble() * 2 * pi,
      ),
  ];
}();

/// Paints a moment of a scene over the night sky; [StoryPlayer] plays it and
/// the story shelf shows each scene still.
class StoryScenePainter extends CustomPainter {
  StoryScenePainter({
    required this.scene,
    required this.frame,
    required this.art,
    required this.stage,
    this.controls,
  }) : super(repaint: frame);

  final StoryScene scene;
  final ValueListenable<StoryFrame> frame;
  final StoryArt? art;

  /// Kept clear of the title row and the words.
  final EdgeInsets stage;

  /// Half folded: the room in front of the fold, between the title row and
  /// the words ([StoryScene.paintSplit]).
  final Rect? controls;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final f = frame.value;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _sky,
        ).createShader(rect),
    );
    final star = Paint()..color = const Color(0xFFE6E9FF);
    for (final (at, radius, phase) in _stars) {
      star.color = const Color(
        0xFFE6E9FF,
      ).withValues(alpha: 0.35 + 0.3 * sin(f.time * 1.5 + phase));
      canvas.drawCircle(
        Offset(at.dx * size.width, at.dy * size.height),
        radius,
        star,
      );
    }
    var room = stage.deflateRect(rect);
    if (room.isEmpty) room = rect;
    final controls = this.controls;
    if (controls == null || controls.isEmpty) {
      scene.paint(canvas, room, f, art);
    } else {
      scene.paintSplit(canvas, room, controls, f, art);
    }
  }

  @override
  bool shouldRepaint(StoryScenePainter old) =>
      old.scene != scene ||
      old.art != art ||
      old.stage != stage ||
      old.controls != controls;
}
