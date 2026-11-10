import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/voice_clips.dart';
import '../../../core/gamepad/gamepad_shortcut.dart';
import '../../../core/gamepad/pad_input.dart';
import '../../../core/responsive/fold.dart';
import '../../../core/widgets/coach_tour.dart';
import '../../../core/widgets/focus_tap.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../../core/widgets/glass_surface.dart';
import '../../../engine/examples/example.dart';
import '../../../engine/world/level.dart';
import '../../learning/view/concepts.dart';
import '../cubit/sorting_cubit.dart';
import 'example_picture.dart';

/// The lesson's sorting screen: pictures go in the safe bin or the other
/// one, then Koba labels new pictures from those examples. [onDone] opens
/// the puzzle, which uses the same examples.
class SortingScreen extends StatefulWidget {
  const SortingScreen({
    super.key,
    required this.level,
    required this.homePath,
    required this.onDone,
    this.showTour = false,
    this.onTourDone,
  });

  final Level level;
  final String homePath;
  final VoidCallback onDone;
  final bool showTour;
  final VoidCallback? onTourDone;

  @override
  State<SortingScreen> createState() => _SortingScreenState();
}

class _SortingScreenState extends State<SortingScreen> {
  late final SortingCubit _sorting = SortingCubit(widget.level);
  late var _touring = widget.showTour;
  final _pictureKey = GlobalKey();
  final _safeKey = GlobalKey();
  final _notKey = GlobalKey();

  @override
  void dispose() {
    _sorting.close();
    super.dispose();
  }

  void _heard(String clip) {
    context.read<AudioService>().playVoice(
      clip,
      languageCode: Localizations.localeOf(context).languageCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider.value(
      value: _sorting,
      child: BlocListener<SortingCubit, SortingState>(
        listenWhen: (before, after) =>
            after.phase == SortingPhase.results &&
            before.phase != SortingPhase.results,
        listener: (context, state) {
          if (_touring) return;
          _heard(
            _sorting.guessesRight
                ? VoiceClips.sortKobaTries
                : VoiceClips.sortKobaWrong,
          );
        },
        child: FoldHalf(
          view: _BigPicture(level: widget.level),
          child: Scaffold(
            extendBodyBehindAppBar: true,
            appBar: GlassAppBar(
              leading: IconButton(
                tooltip: l10n.backToIsland,
                onPressed: () => context.go(widget.homePath),
                icon: const Icon(Icons.home_rounded),
              ),
              title: Text(conceptName(l10n, widget.level.concept)),
            ),
            body: Builder(
              builder: (context) {
                final pad = belowBars(context, const EdgeInsets.all(16));
                return Padding(
                  padding: pad,
                  child: Stack(
                    children: [
                      const _SortingBody(),
                      if (_touring)
                        CoachTour(
                          steps: [
                            CoachStep(
                              target: _pictureKey,
                              text: l10n.tourSortPicture,
                              clip: VoiceClips.tourSortPicture,
                            ),
                            CoachStep(
                              target: _safeKey,
                              text: l10n.tourSortSafe,
                              clip: VoiceClips.tourSortSafe,
                            ),
                            CoachStep(
                              target: _notKey,
                              text: l10n.tourSortNot,
                              clip: VoiceClips.tourSortNot,
                            ),
                          ],
                          onDone: () {
                            setState(() => _touring = false);
                            widget.onTourDone?.call();
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BigPicture extends StatelessWidget {
  const _BigPicture({required this.level});

  final Level level;

  @override
  Widget build(BuildContext context) {
    final sorting = context.watch<SortingCubit>();
    final index = sorting.state.selected ?? sorting.loose.firstOrNull;
    final thing = index == null
        ? level.asks[level.rounds[sorting.state.round].ask.first].thing
        : level.examples[index].thing;
    return Center(child: ExamplePicture(thing: thing, size: 180));
  }
}

class _SortingBody extends StatelessWidget {
  const _SortingBody();

  @override
  Widget build(BuildContext context) {
    final sorting = context.watch<SortingCubit>();
    final state = sorting.state;
    final level = sorting.level;
    final l10n = AppLocalizations.of(context);
    final ready = state.phase == SortingPhase.results && sorting.guessesRight;
    final more =
        state.phase == SortingPhase.results &&
        !sorting.guessesRight &&
        state.round + 1 < level.rounds.length;
    return LayoutBuilder(
      builder: (context, box) {
        final buttonH = math.min(72.0, box.maxHeight * 0.2);
        final rest = math.max(0.0, box.maxHeight - buttonH - 12);
        final picturesH = rest * 0.48;
        final binsH = rest - picturesH;
        return Column(
          children: [
            SizedBox(
              height: picturesH,
              child: state.phase == SortingPhase.results
                  ? _Asks(level: level, guesses: sorting.guesses)
                  : _Loose(level: level),
            ),
            SizedBox(
              height: binsH,
              child: Row(
                children: [
                  Expanded(
                    child: _Bin(
                      safe: true,
                      clip: VoiceClips.sortSafe,
                      words: l10n.sortSafe,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Bin(
                      safe: false,
                      clip: VoiceClips.sortNotSafe,
                      words: l10n.sortNotSafe,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: buttonH,
              child: ready
                  ? _GoButton(label: l10n.sortLetsGo, onPressed: _done)
                  : more
                  ? _GoButton(
                      label: l10n.sortMore,
                      onPressed: (_) => sorting.morePictures(),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  void _done(BuildContext context) {
    context.findAncestorStateOfType<_SortingScreenState>()!.widget.onDone();
  }
}

class _GoButton extends StatelessWidget {
  const _GoButton({required this.label, required this.onPressed});

  final String label;
  final void Function(BuildContext context) onPressed;

  @override
  Widget build(BuildContext context) => GamepadShortcut(
    button: PadButton.x,
    onPressed: () => onPressed(context),
    child: FilledButton(
      onPressed: () => onPressed(context),
      child: Text(label),
    ),
  );
}

class _Loose extends StatelessWidget {
  const _Loose({required this.level});

  final Level level;

  @override
  Widget build(BuildContext context) {
    final sorting = context.watch<SortingCubit>();
    final loose = sorting.loose;
    final pictureKey = context
        .findAncestorStateOfType<_SortingScreenState>()!
        ._pictureKey;
    return Row(
      children: [
        for (final (i, index) in loose.indexed)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: _Card(
                key: i == 0 ? pictureKey : null,
                thing: level.examples[index].thing,
                selected: sorting.state.selected == index,
                wobble: sorting.state.wobble == index,
                onTap: () => sorting.tap(index),
                onDrag: () => sorting.pick(index),
              ),
            ),
          ),
      ],
    );
  }
}

class _Asks extends StatelessWidget {
  const _Asks({required this.level, required this.guesses});

  final Level level;
  final List<bool?> guesses;

  @override
  Widget build(BuildContext context) {
    final sorting = context.watch<SortingCubit>();
    final round = level.rounds[sorting.state.round];
    return Row(
      children: [
        for (final (i, index) in round.ask.indexed)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: _AskCard(
                thing: level.asks[index].thing,
                guess: guesses[i],
                safe: level.asks[index].safe,
              ),
            ),
          ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    super.key,
    required this.thing,
    required this.selected,
    required this.wobble,
    required this.onTap,
    required this.onDrag,
  });

  final ExampleThing thing;
  final bool selected;
  final bool wobble;
  final VoidCallback onTap;
  final VoidCallback onDrag;

  @override
  Widget build(BuildContext context) {
    final picture = LayoutBuilder(
      builder: (context, box) {
        final side = math.min(box.maxWidth, box.maxHeight);
        return Center(
          child: ExamplePicture(thing: thing, size: side),
        );
      },
    );
    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? const Color(0xFF222244)
              : wobble
              ? const Color(0xFFEF6C00)
              : const Color(0x33222244),
          width: selected || wobble ? 4 : 2,
        ),
      ),
      child: picture,
    );
    final child = wobble ? _Wobble(child: card) : card;
    return Draggable<int>(
      data: 1,
      onDragStarted: onDrag,
      feedback: Material(
        color: Colors.transparent,
        child: ExamplePicture(thing: thing, size: 96),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: child),
      child: FocusTap(onTap: onTap, child: child),
    );
  }
}

class _AskCard extends StatelessWidget {
  const _AskCard({
    required this.thing,
    required this.guess,
    required this.safe,
  });

  final ExampleThing thing;
  final bool? guess;
  final bool safe;

  @override
  Widget build(BuildContext context) {
    final right = guess == safe;
    return Column(
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: right
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFEF6C00),
                width: 4,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, box) => Center(
                child: ExamplePicture(
                  thing: thing,
                  size: math.min(box.maxWidth, box.maxHeight),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Bin extends StatelessWidget {
  const _Bin({required this.safe, required this.clip, required this.words});

  final bool safe;
  final String clip;
  final String words;

  @override
  Widget build(BuildContext context) {
    final sorting = context.watch<SortingCubit>();
    final level = sorting.level;
    final state = sorting.state;
    final held = [
      for (final index in state.placed)
        if (level.examples[index].safe == safe) level.examples[index].thing,
    ];
    final screen = context.findAncestorStateOfType<_SortingScreenState>()!;
    final tint = safe ? const Color(0xFFC8E6C9) : const Color(0xFFFFE0B2);
    return DragTarget<int>(
      onAcceptWithDetails: (_) => sorting.place(safe),
      builder: (context, candidate, rejected) => FocusTap(
        onTap: () => sorting.place(safe),
        child: GlassSurface(
          key: safe ? screen._safeKey : screen._notKey,
          tint: candidate.isEmpty ? tint : const Color(0xFFFFF3C4),
          child: SizedBox.expand(
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        safe ? Icons.check_rounded : Icons.landscape_rounded,
                        size: 36,
                        color: safe
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFEF6C00),
                      ),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          for (final thing in held)
                            ExamplePicture(thing: thing, size: 36),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    tooltip: words,
                    onPressed: () => screen._heard(clip),
                    icon: const Icon(Icons.volume_up_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Wobble extends StatelessWidget {
  const _Wobble({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 600),
    builder: (_, t, child) => Transform.translate(
      offset: Offset(math.sin(t * math.pi * 6) * 10 * (1 - t), 0),
      child: child,
    ),
    child: child,
  );
}
