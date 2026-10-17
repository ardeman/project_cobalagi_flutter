import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cobalagi/core/character/koba_head.dart';
import 'package:cobalagi/core/gamepad/gamepad_capture.dart';
import 'package:cobalagi/core/gamepad/gamepad_shortcut.dart';
import 'package:cobalagi/core/gamepad/pad_input.dart';

import '../../app/l10n/app_localizations.dart';
import '../audio/audio_service.dart';

/// One stop on a [CoachTour]: the control it points at, what Koba says
/// about it, and the voice clip that says it.
final class CoachStep {
  const CoachStep({
    required this.target,
    required this.text,
    required this.clip,
  });

  final GlobalKey target;
  final String text;

  /// A clip id from `VoiceClips`, so children who can't read hear it.
  final String clip;
}

/// A short guided tour over a screen: the screen dims, one control at a
/// time shows through a lit window, and Koba explains it in a bubble, out
/// loud. "Next" (or a tap anywhere) moves on; steps whose control isn't on
/// the screen are skipped. Place it over the screen, e.g. as the last
/// child of a full-screen [Stack].
class CoachTour extends StatefulWidget {
  const CoachTour({super.key, required this.steps, required this.onDone});

  final List<CoachStep> steps;

  /// After the last step, or Skip.
  final VoidCallback onDone;

  @override
  State<CoachTour> createState() => _CoachTourState();
}

class _CoachTourState extends State<CoachTour> {
  var _index = -1;
  Rect? _hole;

  /// No step after this one has its control on the screen.
  var _last = false;

  /// Where the child last touched, for a moment, for Koba to look at.
  Offset? _finger;
  Timer? _fingerGone;

  @override
  void dispose() {
    _fingerGone?.cancel();
    super.dispose();
  }

  void _touched(PointerEvent event) {
    _fingerGone?.cancel();
    _fingerGone = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _finger = null);
    });
    setState(() => _finger = event.position);
  }

  /// The middle of the control being explained, on the screen.
  Offset? _targetCentre() {
    final box = widget.steps[_index].target.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  @override
  void initState() {
    super.initState();
    // Controls are laid out after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _next());
  }

  /// The target's place on the screen, or null when it isn't showing.
  Rect? _rectOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    final self = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    if (self is! RenderBox || !self.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: self);
    return topLeft & box.size;
  }

  Future<void> _next() async {
    if (!mounted) return;
    for (var i = _index + 1; i < widget.steps.length; i++) {
      // On a phone the control may be further down the page: bring it in.
      final target = widget.steps[i].target.currentContext;
      if (target == null || !target.mounted) continue;
      await Scrollable.ensureVisible(
        target,
        alignment: 0.5,
        duration: const Duration(milliseconds: 250),
      );
      if (!mounted) return;
      final rect = _rectOf(widget.steps[i].target);
      if (rect == null) continue;
      setState(() {
        _index = i;
        _hole = rect;
        _last = !widget.steps.skip(i + 1).any((s) {
          final later = s.target.currentContext;
          return later != null && later.mounted;
        });
      });
      context.read<AudioService>().playVoice(
        widget.steps[i].clip,
        languageCode: Localizations.localeOf(context).languageCode,
      );
      return;
    }
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final hole = _hole;
    if (_index < 0 || hole == null) {
      // Until the first control is found: block taps, show nothing yet.
      return const Positioned.fill(child: AbsorbPointer());
    }
    // The control may have moved (a rotated phone): follow it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final now = _rectOf(widget.steps[_index].target);
      if (now != null && now != _hole) setState(() => _hole = now);
    });
    final l10n = AppLocalizations.of(context);
    final step = widget.steps[_index];
    final window = hole.inflate(10);
    return Positioned.fill(
      // With a controller, the bubble's buttons have their own: X (like Go)
      // or A goes on, B skips, the speaker's button listens again.
      child: GamepadCapture(
        onBack: widget.onDone,
        onConfirm: _next,
        // Koba looks at the control it explains, or where the child touches.
        child: Listener(
          onPointerDown: _touched,
          onPointerMove: _touched,
          child: LayoutBuilder(
            builder: (context, box) {
              final screen = box.biggest;
              // The bubble goes below the control if it fits, else above it,
              // else (a tall control) over the control's lower part.
              const room = 170.0;
              final spaceBelow = screen.height - window.bottom - 12;
              final spaceAbove = window.top - 12;
              final below = spaceBelow >= room || spaceBelow >= spaceAbove;
              final inside = spaceBelow < room && spaceAbove < room;
              final width = min(420.0, screen.width - 32);
              final left = (window.center.dx - width / 2)
                  .clamp(16.0, max(16.0, screen.width - width - 16))
                  .toDouble();
              return Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _next,
                      child: CustomPaint(painter: _Dim(window)),
                    ),
                  ),
                  Positioned(
                    left: left,
                    width: width,
                    top: inside
                        ? null
                        : below
                        ? window.bottom + 12
                        : null,
                    bottom: inside
                        ? max(16, screen.height - window.bottom + 16)
                        : below
                        ? null
                        : screen.height - window.top + 12,
                    child: _Bubble(
                      key: ValueKey(_index),
                      text: step.text,
                      lookAt: _finger ?? _targetCentre(),
                      next: _last ? l10n.tourDone : l10n.tourNext,
                      skip: l10n.tutorialSkip,
                      onNext: _next,
                      onSkip: widget.onDone,
                      onListen: () => context.read<AudioService>().playVoice(
                        step.clip,
                        languageCode: Localizations.localeOf(
                          context,
                        ).languageCode,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The dimmed screen with a lit, ringed window over the control.
class _Dim extends CustomPainter {
  const _Dim(this.window);

  final Rect window;

  @override
  void paint(Canvas canvas, Size size) {
    final hole = RRect.fromRectAndRadius(window, const Radius.circular(20));
    canvas
      ..drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(Offset.zero & size),
          Path()..addRRect(hole),
        ),
        Paint()..color = const Color(0xA6000000),
      )
      ..drawRRect(
        hole,
        Paint()
          ..color = const Color(0xFFFFC83D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
  }

  @override
  bool shouldRepaint(_Dim old) => old.window != window;
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    super.key,
    required this.text,
    required this.lookAt,
    required this.next,
    required this.skip,
    required this.onNext,
    required this.onSkip,
    required this.onListen,
  });

  final String text;
  final Offset? lookAt;
  final String next;
  final String skip;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      // Opaque, with a soft shadow outside (never elevation).
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Koba, who explains.
                  KobaHead(size: 56, lookAt: lookAt),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(text, style: theme.textTheme.titleMedium),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // One line when there is room; stacked on the right if not.
              OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                overflowAlignment: OverflowBarAlignment.end,
                overflowSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GamepadShortcut(
                        button: PadButton.menu,
                        onPressed: onListen,
                        child: IconButton.filledTonal(
                          tooltip: AppLocalizations.of(context).listenAgain,
                          onPressed: onListen,
                          icon: const Icon(Icons.volume_up_rounded),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Skipping is the quiet choice.
                      GamepadShortcut(
                        button: PadButton.b,
                        onPressed: onSkip,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(64, 64),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            textStyle: theme.textTheme.labelLarge,
                          ),
                          onPressed: onSkip,
                          child: Text(skip),
                        ),
                      ),
                    ],
                  ),
                  GamepadShortcut(
                    button: PadButton.x,
                    onPressed: onNext,
                    child: FilledButton.icon(
                      autofocus: true,
                      onPressed: onNext,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(next),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
