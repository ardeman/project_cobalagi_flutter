import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/sound_effects.dart';
import '../../../core/audio/voice_clips.dart';
import '../../../core/responsive/window_class.dart';
import '../../../core/widgets/glass_surface.dart';
import '../../editors/blocks/cubit/blocks_cubit.dart';
import '../../editors/blocks/data/block.dart';
import '../../editors/blocks/view/block_editor.dart';
import '../../learning/view/concepts.dart';
import '../../play/cubit/play_cubit.dart';
import '../../play/view/world/world_game.dart';
import '../data/tutorial.dart';

/// An island's "Watch me!" demo: a voice explains the idea while a hand
/// places the blocks and presses Go, in the real editor and world. The
/// child only watches; [onDone] continues to the puzzles.
class TutorialView extends StatefulWidget {
  const TutorialView({
    super.key,
    required this.tutorial,
    required this.onDone,
    this.doneLabel,
  });

  final Tutorial tutorial;
  final VoidCallback onDone;

  /// The finishing button's label; "Let's play!" by default.
  final String? doneLabel;

  @override
  State<TutorialView> createState() => _TutorialViewState();
}

class _TutorialViewState extends State<TutorialView> {
  late var _blocks = _newBlocks();
  late var _play = PlayCubit(widget.tutorial.level);
  late var _game = _newGame();
  StreamSubscription<PlayState>? _mirror;

  /// The palette block the hand points at, and whether it is on Go.
  BlockType? _pointAt;
  var _pressingGo = false;
  var _finished = false;
  var _started = false;

  /// Bumped on every replay, so a running script stops when replaced.
  var _run = 0;

  /// Pauses between steps, slow enough for a young child to follow.
  static const _beat = Duration(milliseconds: 750);

  BlocksCubit _newBlocks() => BlocksCubit(
    maxBlocks: widget.tutorial.level.maxBlocks,
    start: widget.tutorial.level.starter,
  );

  WorldGame _newGame() => WorldGame(
    level: widget.tutorial.level,
    onEventShown: () => _play.eventShown(),
    onSound: context.read<AudioService>().playEffect,
  );

  @override
  void initState() {
    super.initState();
    _mirror = _play.stream.listen(_game.apply);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _run++;
    _mirror?.cancel();
    _blocks.close();
    _play.close();
    super.dispose();
  }

  late final AudioService _audio = context.read<AudioService>();

  void _say() => _audio.playVoice(
    VoiceClips.tutorial(widget.tutorial.concept),
    languageCode: Localizations.localeOf(context).languageCode,
  );

  /// Starts (or restarts) the demo from the beginning.
  Future<void> _start() async {
    final run = ++_run;
    if (_started) {
      // A fresh editor and world for "Watch again".
      _mirror?.cancel();
      final oldBlocks = _blocks;
      final oldPlay = _play;
      setState(() {
        _blocks = _newBlocks();
        _play = PlayCubit(widget.tutorial.level);
        _game = _newGame();
        _finished = false;
        _pointAt = null;
        _pressingGo = false;
      });
      _mirror = _play.stream.listen(_game.apply);
      oldBlocks.close();
      oldPlay.close();
    }
    _started = true;
    bool alive() => mounted && run == _run;
    _say();
    await Future<void>.delayed(_beat * 2);
    for (final action in widget.tutorial.actions) {
      if (!alive()) return;
      if (action is PressGo) {
        setState(() => _pressingGo = true);
        await Future<void>.delayed(_beat);
        if (!alive()) return;
        setState(() => _pressingGo = false);
        _play.run(_blocks.program);
        final play = _play;
        // Ends quietly too if the child leaves mid-run and it closes.
        await play.stream.firstWhere(
          (s) => s.phase != PlayPhase.running,
          orElse: () => play.state,
        );
        await Future<void>.delayed(_beat * 2);
        if (!alive()) return;
        // After a run that went off course, start the world over.
        if (_play.state.phase == PlayPhase.failed) _play.reset();
        continue;
      }
      setState(() => _pointAt = action.pointsAt);
      await Future<void>.delayed(_beat);
      if (!alive()) return;
      applyTutorialAction(_blocks, action);
      if (action is AddBlock || action is TapPalette) {
        _audio.playEffect(SoundEffect.drop);
      }
      setState(() => _pointAt = null);
      await Future<void>.delayed(_beat);
    }
    if (alive()) setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final concept = widget.tutorial.concept;
    final top = Row(
      children: [
        Icon(conceptIcon(concept), color: conceptColor(concept), size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '${l10n.tutorialTitle} ${conceptName(l10n, concept)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        IconButton.filledTonal(
          tooltip: l10n.listenAgain,
          onPressed: _say,
          icon: const Icon(Icons.volume_up_rounded),
        ),
      ],
    );
    final world = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: GameWidget(key: ValueKey(_game), game: _game),
    );
    // The demo's Go is only for show: it fades once the demo is over, so it
    // doesn't look like a button to press, and keeps its place.
    final go = AnimatedOpacity(
      opacity: _finished ? 0 : 1,
      duration: const Duration(milliseconds: 250),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedScale(
            scale: _pressingGo ? 0.92 : 1,
            duration: const Duration(milliseconds: 150),
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow_rounded, size: 40),
              label: Text(l10n.run),
            ),
          ),
          if (_pressingGo)
            const Positioned(
              right: -6,
              bottom: -22,
              child: Icon(
                Icons.touch_app_rounded,
                size: 48,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
              ),
            ),
        ],
      ),
    );
    Widget editorFor({required bool fit}) => BlocProvider.value(
      value: _blocks,
      child: BlocBuilder<BlocksCubit, BlockProgram>(
        builder: (context, _) => BlockEditor(
          palette: widget.tutorial.level.palette,
          blockSize: 56,
          enabled: true,
          showTips: false,
          fitContent: fit,
          pointAt: _pointAt,
        ),
      ),
    );
    final editor = editorFor(fit: false);
    // The end buttons always take their room, hidden while the demo plays
    // (with Skip over them), so nothing moves when they appear.
    final buttons = Stack(
      alignment: Alignment.center,
      children: [
        // Keeps their size only: not tappable or read out while hidden.
        Visibility(
          visible: _finished,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: _start,
                icon: const Icon(Icons.replay_rounded),
                label: Text(l10n.tutorialWatchAgain),
              ),
              FilledButton.icon(
                onPressed: widget.onDone,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(widget.doneLabel ?? l10n.tutorialLetsPlay),
              ),
            ],
          ),
        ),
        if (!_finished)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.onDone,
              child: Text(l10n.tutorialSkip),
            ),
          ),
      ],
    );
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: WindowClassBuilder(
            builder: (context, windowClass) {
              // The child watches: taps on the demo itself do nothing.
              final demo = IgnorePointer(
                child: windowClass == WindowClass.compact
                    ? Column(
                        children: [
                          Expanded(flex: 2, child: world),
                          const SizedBox(height: 12),
                          // Phones: the blocks get more room and scroll.
                          Expanded(
                            flex: 3,
                            child: SingleChildScrollView(
                              child: editorFor(fit: true),
                            ),
                          ),
                          const SizedBox(height: 12),
                          go,
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                Expanded(child: world),
                                const SizedBox(height: 12),
                                go,
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: GlassSurface(
                              padding: const EdgeInsets.all(12),
                              child: editor,
                            ),
                          ),
                        ],
                      ),
              );
              return Column(
                children: [
                  top,
                  const SizedBox(height: 12),
                  Expanded(child: demo),
                  const SizedBox(height: 12),
                  buttons,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
