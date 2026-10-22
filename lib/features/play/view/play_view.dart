import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cobalagi/core/gamepad/gamepad_shortcut.dart';
import 'package:cobalagi/core/gamepad/pad_input.dart';
import 'package:cobalagi/core/widgets/glass_surface.dart';
import 'package:cobalagi/core/widgets/paint_transition.dart';
import 'package:cobalagi/core/widgets/coach_tour.dart';

import '../../../app/l10n/app_localizations.dart';
import 'board_dots.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/sound_effects.dart';
import '../../../core/audio/voice_clips.dart';
import '../../../core/feedback/cheers.dart';
import '../../../core/responsive/fold.dart';
import '../../../core/responsive/window_class.dart';
import '../../../core/settings/hint_arrows_cubit.dart';
import '../../../engine/generator/off_track.dart';
import '../../../engine/generator/solver.dart';
import '../../../engine/interpreter/run_event.dart';
import '../../../engine/program/instruction.dart';
import '../../../engine/program/program.dart';
import 'package:cobalagi/core/widgets/glass_frame.dart';
import 'package:cobalagi/features/editors/typed/cubit/typed_code_cubit.dart';
import 'package:cobalagi/features/play/view/hint_marks.dart';
import 'package:cobalagi/features/play_time/data/play_clock.dart';
import 'package:cobalagi/features/editors/typed/data/typed_program.dart';
import 'package:cobalagi/features/editors/typed/view/typed_code_editor.dart';
import '../../../engine/world/level.dart';
import '../../../learning/exercise_result.dart';
import '../../../learning/learning_engine.dart';
import '../../editors/blocks/cubit/blocks_cubit.dart';
import '../../editors/blocks/data/block.dart';
import '../../editors/blocks/view/block_editor.dart';
import '../../editors/blocks/view/block_tile.dart';
import '../../learning/cubit/learning_cubit.dart';
import '../../learning/view/concepts.dart';
import '../cubit/play_cubit.dart';
import 'puzzle_stars.dart';
import 'world/world_game.dart';

/// One puzzle: the world, the editor and run controls. [onFinished] records
/// the result and may return what the learning loop decided; replays return
/// null.
class PlayView extends StatefulWidget {
  const PlayView({
    super.key,
    required this.exercise,
    required this.hintAfterRuns,
    required this.hintPulseAfterTries,
    required this.starsFor,
    required this.homePath,
    required this.onFinished,
    required this.onNext,
    this.showHowTo = false,
    this.allowCode = false,
    this.showTour = false,
    this.onTourDone,
  });

  /// Opens with Koba showing what each part of the screen does; "?" on the
  /// world shows it again. [onTourDone] remembers it was seen.
  final bool showTour;
  final VoidCallback? onTourDone;

  final Exercise exercise;

  /// Offers the Code tab beside the blocks: for children who read, or when
  /// a parent turns it on. Otherwise only picture blocks show.
  final bool allowCode;

  /// For a child who hasn't solved a puzzle yet: a hand shows how to add a
  /// block, then the Go button pulses, until the first run.
  final bool showHowTo;

  /// Runs before the hint bulb works: a child tries first.
  final int hintAfterRuns;

  /// More tries, with the bulb on and unused, before it pulses.
  final int hintPulseAfterTries;

  /// The stars (0 to 3) a finished puzzle earns, shown on its card.
  final int Function(ExerciseResult result) starsFor;
  final String homePath;
  final Future<Decision?> Function(ExerciseResult result) onFinished;

  /// After the exercise: the next puzzle, or back to the island for a replay.
  final VoidCallback onNext;

  @override
  State<PlayView> createState() => _PlayViewState();
}

int _count(BlockProgram program) =>
    compileBlocks(program.main, star: program.star).blockCount;

class _PlayViewState extends State<PlayView> {
  /// The controls' slot beside the editor: a 64 dp row of buttons, or a
  /// one-line feedback card (64 dp button plus 12 dp padding top and
  /// bottom).
  static const _controlSlotHeight = 88.0;

  late final _level = widget.exercise.level;
  late final _blocks = BlocksCubit(
    maxBlocks: _level.maxBlocks,
    start: _level.starter,
  );
  late final _play = PlayCubit(_level);
  late final _typed = TypedCodeCubit(_level);
  final _page = ScrollController();
  var _codeMode = false;
  var _codeSeeded = false;
  late final _game = WorldGame(
    level: _level,
    onEventShown: _play.eventShown,
    onSound: context.read<AudioService>().playEffect,
  );

  /// The guided tour is showing (see [PlayView.showTour]).
  late var _touring = widget.showTour;
  final _tour = _TourKeys();

  /// What the tour says about a palette block, and its voice clip.
  static (String, String) _blockTour(AppLocalizations l10n, BlockType type) =>
      switch (type) {
        BlockType.forward => (
          l10n.tourBlockForward,
          VoiceClips.tourBlockForward,
        ),
        BlockType.turnLeft => (
          l10n.tourBlockTurnLeft,
          VoiceClips.tourBlockTurnLeft,
        ),
        BlockType.turnRight => (
          l10n.tourBlockTurnRight,
          VoiceClips.tourBlockTurnRight,
        ),
        BlockType.repeat => (l10n.tourBlockRepeat, VoiceClips.tourBlockRepeat),
        BlockType.setSteps => (
          l10n.tourBlockSetSteps,
          VoiceClips.tourBlockSetSteps,
        ),
        BlockType.moveSteps => (
          l10n.tourBlockMoveSteps,
          VoiceClips.tourBlockMoveSteps,
        ),
        BlockType.ifPathClear => (
          l10n.tourBlockIfPathClear,
          VoiceClips.tourBlockIfPathClear,
        ),
        BlockType.ifElse => (l10n.tourBlockIfElse, VoiceClips.tourBlockIfElse),
        BlockType.untilGoal => (
          l10n.tourBlockUntilGoal,
          VoiceClips.tourBlockUntilGoal,
        ),
        BlockType.star => (l10n.tourBlockStar, VoiceClips.tourBlockStar),
      };

  void _endTour() {
    if (!_touring) return;
    setState(() => _touring = false);
    widget.onTourDone?.call();
    _sayGoal();
  }

  List<CoachStep> _tourSteps(AppLocalizations l10n) => [
    CoachStep(
      target: _tour.palette,
      text: l10n.tourPalette,
      clip: VoiceClips.tourPalette,
    ),
    // Then each block this puzzle offers, in the palette's order.
    for (final type in BlockType.values)
      if (_level.palette.contains(type.kind))
        CoachStep(
          target: _tour.blocks[type]!,
          text: _blockTour(l10n, type).$1,
          clip: _blockTour(l10n, type).$2,
        ),
    CoachStep(
      target: _tour.program,
      text: l10n.tourProgram,
      clip: VoiceClips.tourProgram,
    ),
    CoachStep(target: _tour.go, text: l10n.tourGo, clip: VoiceClips.tourGo),
    CoachStep(
      target: _tour.step,
      text: l10n.tourStep,
      clip: VoiceClips.tourStep,
    ),
    CoachStep(
      target: _tour.reset,
      text: l10n.tourReset,
      clip: VoiceClips.tourReset,
    ),
    CoachStep(
      target: _tour.hint,
      text: l10n.tourHint,
      clip: VoiceClips.tourHint,
    ),
    CoachStep(
      target: _tour.turn,
      text: l10n.tourFollow,
      clip: VoiceClips.tourFollow,
    ),
    if (_level.moreBoards.isNotEmpty)
      CoachStep(
        target: _tour.boards,
        text: l10n.tourBoards,
        clip: VoiceClips.tourBoards,
      ),
    CoachStep(
      target: _tour.listen,
      text: l10n.tourListen,
      clip: VoiceClips.tourListen,
    ),
  ];

  /// The dots for a level's maps: which one is in view and which ones the
  /// last run solved. While editing, tapping one shows that map.
  Widget _boardDots() => BlocBuilder<PlayCubit, PlayState>(
    builder: (context, play) => BoardDots(
      key: _touring ? _tour.boards : null,
      count: _level.boards.length,
      shown: play.board,
      solved: switch (play.phase) {
        PlayPhase.editing => 0,
        PlayPhase.succeeded => _level.boards.length,
        _ => play.board,
      },
      stopped: play.phase == PlayPhase.failed,
      onPick: _finished || play.phase == PlayPhase.running
          ? null
          : (board) {
              if (play.phase != PlayPhase.editing) _play.reset();
              _play.peek(board);
            },
    ),
  );

  /// Turns the map a quarter turn clockwise; four taps bring it back.
  void _turnMap() =>
      setState(() => _game.quarterTurns = (_game.quarterTurns + 1) % 4);

  final _clock = Stopwatch()..start();
  var _hints = 0;

  /// The block that walked into a rock on the last run, marked until the
  /// child changes the program or runs again.
  /// Blocks wearing the orange "look here" ring (see [BlockEditor.lookHere]).
  Set<String> _lookHere = const {};

  /// Whether [_lookHere] came from the hint rather than a bump.
  var _lookHereFromHint = false;

  /// The hint the bulb showed last (see [_showHint]); -1 before the first.
  var _hintStep = -1;

  /// The route hint is showing, and asking again shows the pattern.
  /// Whether the bulb has a repeating pattern to show on this level.
  /// Never on a level with several boards: one board's repeating shape
  /// doesn't solve the others.
  late final _hasPattern = switch (solve(_level)) {
    final solution? when _level.moreBoards.isEmpty =>
      patternHintMarks(_level, solution) != null,
    _ => false,
  };
  var _finishing = false;
  final _cheers = CheerPicker();

  /// The cheer for the current card, picked when the card appears.
  Cheer? _cheer;

  /// Set once the exercise is recorded; the card then offers the next one.
  var _finished = false;

  /// What the learning loop decided; null for a replay.
  Decision? _decision;
  var _solved = false;

  @override
  void initState() {
    super.initState();
    // Puzzle time counts toward the parent's break reminder.
    _playClock?.start();
    // Koba watches the child's finger or the mouse anywhere on the screen.
    GestureBinding.instance.pointerRouter.addGlobalRoute(_pointed);
    // With the tour, the goal is said once it is over.
    if (!_touring) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sayGoal());
    }
  }

  void _pointed(PointerEvent event) {
    if (event is PointerDownEvent ||
        event is PointerMoveEvent ||
        event is PointerHoverEvent) {
      _game.lookAt(event.position);
    }
  }

  /// Missing where a play view stands alone, as in some tests.
  late final PlayClock? _playClock = context.read<PlayClock?>();

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_pointed);
    _playClock?.stop();
    _blocks.close();
    _typed.close();
    _page.dispose();
    _play.close();
    super.dispose();
  }

  void _say(String clip, {bool queue = false}) {
    if (!mounted) return;
    context.read<AudioService>().playVoice(
      clip,
      languageCode: Localizations.localeOf(context).languageCode,
      queue: queue,
    );
  }

  void _sayGoal() {
    _say(_goal(_level).$2);
    if (widget.showHowTo) _say(VoiceClips.playHowTo, queue: true);
  }

  /// Stars the finished puzzle earned.
  var _stars = 0;

  Future<void> _finish({required bool succeeded}) async {
    if (_finishing) return;
    _finishing = true;
    _clock.stop();
    final plan = widget.exercise.plan;
    final result = ExerciseResult(
      conceptId: plan.conceptId,
      levelId: _level.id,
      mode: plan.mode,
      difficulty: plan.difficulty,
      succeeded: succeeded,
      runs: _play.state.runs,
      hintsUsed: _hints,
      duration: _clock.elapsed,
    );
    _stars = widget.starsFor(result);
    final decision = await widget.onFinished(result);
    if (mounted) {
      if (decision != null) _say(_decisionClip(decision), queue: true);
      setState(() {
        _finished = true;
        _decision = decision;
        _solved = succeeded;
        _cheer = _cheers.next(
          AppLocalizations.of(context),
          succeeded ? CheerMood.celebrate : CheerMood.encourage,
        );
      });
    }
  }

  void _showHint() {
    if (_play.state.phase != PlayPhase.editing) _play.reset();
    // On a level with several boards, the hint is about the board in view.
    final board = _play.state.shownBoard;
    final solution = solve(board);
    if (solution == null) return;
    setState(() => _hints++);
    final font = Theme.of(context).textTheme.titleLarge?.fontFamily;
    final pattern = _hasPattern
        ? patternHintMarks(board, solution, labelFont: font)
        : null;
    final program = _codeMode ? _typed.state.program : _blocks.program;
    final offTrack = _offTrack(board, program);
    // One hint per press, building up, then round again: the route as the
    // level's own blocks, in their colours; on islands with a loop block,
    // the shape that repeats and the loop block that does it; then every
    // one of the child's own blocks that takes Koba no closer to the finish,
    // wearing the bump's "look here" ring (in code, the first one's line is
    // marked). A program that is right so far has no block to ring.
    final steps = _hintSteps(
      hasPattern: pattern != null,
      hasRing: offTrack.isNotEmpty,
    );
    _hintStep = (_hintStep + 1) % steps.length;
    final step = steps[_hintStep];
    final trail = hintTrail(board, solution);
    final followRoad = context.read<HintArrowsCubit?>()?.state ?? true;
    switch (step) {
      case _Hint.route:
        _game.showHint(
          hintMarks(
            board,
            solution,
            labelFont: font,
            lookFirst: _level.moreBoards.isNotEmpty,
          ),
          trail: trail,
          followRoad: followRoad,
        );
      case _Hint.pattern:
        _game.showHint(pattern!, trail: trail, followRoad: followRoad);
      case _Hint.ring:
        setState(() {
          _lookHere = offTrack.toSet();
          _lookHereFromHint = true;
        });
    }
    // After the route, Koba says the bulb has more to show, if the pattern
    // comes next (the bulb's badge shows it too). Pre-readers hear what the
    // pattern and the ring mean.
    final next = steps[(_hintStep + 1) % steps.length];
    switch (step) {
      case _Hint.route when next == _Hint.pattern:
        _say(VoiceClips.hintAgain);
      case _Hint.route:
        break;
      case _Hint.pattern:
        _say(VoiceClips.hintPattern);
      case _Hint.ring:
        _say(
          offTrack.length > 1
              ? VoiceClips.hintLookHereMany
              : VoiceClips.hintLookHere,
        );
    }
  }

  void _onPlayChanged(BuildContext context, PlayState state) {
    _game.apply(state);
    if (state.phase == PlayPhase.running && _lookHere.isNotEmpty) {
      setState(() => _lookHere = const {});
    }
    if (state.bumpedBlockId case final id?) {
      setState(() {
        _lookHere = {id};
        _lookHereFromHint = false;
      });
    }
    final mood = switch (state.phase) {
      PlayPhase.succeeded => CheerMood.celebrate,
      PlayPhase.failed => CheerMood.encourage,
      _ => null,
    };
    if (mood == null) return;
    final cheer = _cheers.next(AppLocalizations.of(context), mood);
    setState(() => _cheer = cheer);
    // Success: a cheer, then the decision. Failure: what went wrong.
    _say(switch (state.result!.outcome) {
      RunOutcome.success => cheer.clip,
      // An earlier map worked, so the blocks counted rather than looked.
      _ when state.board > 0 => VoiceClips.feedbackOtherBoard,
      RunOutcome.bumped => VoiceClips.feedbackBumped,
      RunOutcome.stoppedShort => VoiceClips.feedbackStoppedShort,
      RunOutcome.missedStars => VoiceClips.feedbackMissedStars,
      RunOutcome.tooManySteps => VoiceClips.feedbackTooManySteps,
    });
    if (state.phase == PlayPhase.succeeded) _finish(succeeded: true);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _blocks),
        BlocProvider.value(value: _play),
        BlocProvider.value(value: _typed),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<PlayCubit, PlayState>(listener: _onPlayChanged),
          // Go or Step on a phone brings the world back into view.
          BlocListener<PlayCubit, PlayState>(
            listenWhen: (before, after) =>
                after.phase == PlayPhase.running &&
                before.phase != PlayPhase.running,
            listener: (_, _) {
              if (_page.hasClients && _page.offset > 0) {
                _page.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            },
          ),
          BlocListener<TypedCodeCubit, TypedCodeState>(
            listener: (_, _) {
              if (_lookHere.isNotEmpty) setState(() => _lookHere = const {});
              if (_play.state.phase != PlayPhase.editing) _play.reset();
            },
          ),
          // Editing the program after a run puts the world back at the start.
          // A click when a block lands in the program.
          BlocListener<BlocksCubit, BlockProgram>(
            listenWhen: (before, after) => _count(after) > _count(before),
            listener: (_, _) {
              context.read<AudioService>().playEffect(SoundEffect.drop);
              // A light tick, so the drop feels solid; Android leaves it out
              // when the device's touch vibration is off.
              HapticFeedback.selectionClick();
            },
          ),
          // A changed program clears the bumped mark; picking a block to
          // fix keeps it.
          BlocListener<BlocksCubit, BlockProgram>(
            listenWhen: (before, after) =>
                _lookHere.isNotEmpty &&
                (!identical(before.main, after.main) ||
                    !identical(before.star, after.star)),
            listener: (_, _) => setState(() => _lookHere = const {}),
          ),
          BlocListener<BlocksCubit, Object>(
            listener: (_, _) {
              final play = _play.state;
              if (play.phase != PlayPhase.editing || play.issues.isNotEmpty) {
                _play.reset();
              }
            },
          ),
        ],
        child: Stack(
          children: [
            Scaffold(
              // Phones pad inside their glass bars instead, so the page can
              // scroll under the bars from edge to edge. A half-folded phone
              // pads each half on its own ([FoldSplit]).
              body: _MaybeSafeArea(
                safe: FoldHalves.of(context) == null,
                child: WindowClassBuilder(
                  builder: (context, windowClass) {
                    final halves = FoldHalves.of(context);
                    final compact = windowClass == WindowClass.compact;
                    // Phones held sideways: wide enough for two columns, too short
                    // for the tablet's big blocks and fixed editor.
                    final short =
                        !compact && MediaQuery.sizeOf(context).height < 500;
                    // Small blocks, an icon editor switch and a page that scrolls.
                    // Each half of a half-folded phone is a closed phone's.
                    final tight = compact || short || halves != null;
                    // Tall screens (phones, tablets held upright) stack the world
                    // over the editor in one scrolling page.
                    final screen = MediaQuery.sizeOf(context);
                    final stacked =
                        compact || screen.height > screen.width * 1.15;
                    final topBar = _TopBar(
                      plan: widget.exercise.plan,
                      goal: _goal(_level).$1(AppLocalizations.of(context)),
                      onListen: _sayGoal,
                      listenKey: _touring ? _tour.listen : null,
                      homePath: widget.homePath,
                      compact: tight,
                      // Phones keep the editor switch up here, so the world
                      // keeps its height.
                      editorSwitch: widget.allowCode && (tight || stacked)
                          ? BlocBuilder<PlayCubit, PlayState>(
                              builder: (context, play) => _EditorSwitch(
                                codeMode: _codeMode,
                                iconOnly: true,
                                onPick:
                                    !_finished &&
                                        play.phase != PlayPhase.running
                                    ? _pickEditor
                                    : null,
                              ),
                            )
                          : null,
                    );
                    final panel = ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      // The Step Box sits beside or above the world, never over
                      // it, so it never hides a cell.
                      child: ColoredBox(
                        color: _game.backgroundColor(),
                        child: Flex(
                          direction: tight ? Axis.horizontal : Axis.vertical,
                          children: [
                            if (_level.palette.contains(
                              InstructionKind.setSteps,
                            ))
                              Padding(
                                padding: tight
                                    ? const EdgeInsets.fromLTRB(8, 8, 0, 8)
                                    : const EdgeInsets.fromLTRB(8, 8, 8, 0),
                                child: _StepBoxValue(compact: tight),
                              ),
                            Expanded(
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    // The world takes no input but a touch
                                    // on Koba, just for fun, so the
                                    // controller's highlight skips it.
                                    child: ExcludeFocus(
                                      child: Listener(
                                        onPointerDown: (event) =>
                                            _game.touch(event.position),
                                        child: GameWidget(game: _game),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GamepadShortcut(
                                      button: PadButton.y,
                                      onPressed: _turnMap,
                                      // Inside the world's edge.
                                      badgeOnLeft: true,
                                      child: _TurnMapButton(
                                        key: _touring ? _tour.turn : null,
                                        quarterTurns: _game.quarterTurns,
                                        onPressed: _turnMap,
                                      ),
                                    ),
                                  ),
                                  if (_level.moreBoards.isNotEmpty)
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: Center(child: _boardDots()),
                                    ),
                                  // Solved: nothing left to explain.
                                  if (!_finished)
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: GamepadShortcut(
                                        button: PadButton.view,
                                        onPressed: _touring
                                            ? null
                                            : () => setState(
                                                () => _touring = true,
                                              ),
                                        child: IconButton.filledTonal(
                                          tooltip: AppLocalizations.of(
                                            context,
                                          ).tourHelp,
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.white
                                                .withValues(alpha: 0.85),
                                            foregroundColor: const Color(
                                              0xFF263238,
                                            ),
                                          ),
                                          onPressed: _touring
                                              ? null
                                              : () => setState(
                                                  () => _touring = true,
                                                ),
                                          icon: const Icon(
                                            Icons.question_mark_rounded,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                    // Feedback replaces the controls, so it never hides the
                    // world, and the controls aren't usable meanwhile anyway.
                    final feedback = _feedbackCard(context);
                    final controls =
                        feedback ??
                        _RunControls(
                          onHint: _finished ? null : _showHint,
                          hintAfterRuns: widget.hintAfterRuns,
                          hintPulseAfterTries: widget.hintPulseAfterTries,
                          hintsUsed: _hints,
                          hintStep: _hintStep,
                          hasPattern: _hasPattern,
                          tour: _touring ? _tour : null,
                          howTo: widget.showHowTo,
                          compact: tight,
                          codeMode: _codeMode,
                        );
                    // Beside the editor, the world takes what the controls
                    // leave. Their slot keeps one height, with room for a
                    // one-line card, so the world never resizes when the card
                    // comes and goes; a taller card grows up over the gap.
                    final controlSlot = SizedBox(
                      height: _controlSlotHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          if (feedback == null)
                            controls
                          else
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Center(child: feedback),
                            ),
                        ],
                      ),
                    );
                    Widget editorFor({
                      required bool fit,
                    }) => BlocBuilder<PlayCubit, PlayState>(
                      builder: (context, play) {
                        final enabled =
                            !_finished && play.phase != PlayPhase.running;
                        return _codeMode
                            ? TypedCodeEditor(
                                enabled: enabled,
                                // Code marks the bumped command like the
                                // running one.
                                activeBlockId:
                                    play.activeBlockId ?? _lookHere.firstOrNull,
                                fitContent: fit,
                              )
                            : BlockEditor(
                                palette: _level.palette,
                                blockSize: tight ? 56.0 : 72.0,
                                activeBlockId: play.activeBlockId,
                                activeCallId: play.activeCallId,
                                lookHere: _lookHere,
                                fromHint: _lookHereFromHint,
                                paletteKey: _touring ? _tour.palette : null,
                                programKey: _touring ? _tour.program : null,
                                blockKeys: _touring ? _tour.blocks : const {},
                                issueBlockIds: {
                                  for (final issue in play.issues)
                                    ?issue.blockId,
                                },
                                enabled: enabled,
                                showTips: !tight,
                                fitContent: fit,
                                showHowTo:
                                    widget.showHowTo &&
                                    play.runs == 0 &&
                                    !_touring,
                              );
                      },
                    );
                    if (halves != null) {
                      // Half folded: the world stands up behind the fold and
                      // the blocks and Go lie flat in front of it. The top
                      // bar rides above the world, far from the fold, so
                      // the program has room for a repeat.
                      return FoldSplit(
                        halves: halves,
                        view: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                topBar,
                                const SizedBox(height: 12),
                                Expanded(child: panel),
                              ],
                            ),
                          ),
                        ),
                        controls: SafeArea(
                          child: Padding(
                            // Held like a book, the half reaches the top
                            // of the screen; on a table it starts at the
                            // fold's clearance.
                            padding: EdgeInsets.fromLTRB(
                              16,
                              halves.controls.top <= 0 ? 16 : 0,
                              16,
                              8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: editorFor(fit: false)),
                                controlSlot,
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    // Typing code on a phone: the code gets the room. The tree
                    // keeps its shape, so the code field keeps the keyboard.
                    final typing = tight && _codeMode && keyboardOpen;
                    if (stacked) {
                      // Phones: the world and the editor scroll as one page
                      // under a glass top bar and glass controls at the bottom.
                      return GlassFrame(
                        top: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          child: topBar,
                        ),
                        bottom: typing
                            ? null
                            : Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  16,
                                ),
                                child: controls,
                              ),
                        builder: (context, insets) => LayoutBuilder(
                          builder: (context, box) => SingleChildScrollView(
                            controller: _page,
                            padding:
                                insets +
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Hidden, not removed, while typing: the world
                                // keeps running and comes back as it was.
                                Offstage(
                                  offstage: typing,
                                  child: SizedBox(
                                    // Large, with the editor peeking below.
                                    height: max(
                                      0,
                                      min(
                                        (box.maxHeight - insets.vertical) *
                                            0.75,
                                        box.maxWidth - 32,
                                      ),
                                    ),
                                    child: panel,
                                  ),
                                ),
                                SizedBox(height: typing ? 0 : 12),
                                editorFor(fit: true),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    if (short) {
                      // Sideways phones: world and Go on the left; the editor
                      // scrolls on its own on the right.
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  topBar,
                                  const SizedBox(height: 12),
                                  Expanded(child: panel),
                                  const SizedBox(height: 12),
                                  controlSlot,
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: SingleChildScrollView(
                                child: editorFor(fit: true),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                topBar,
                                const SizedBox(height: 12),
                                Expanded(child: panel),
                                const SizedBox(height: 12),
                                controlSlot,
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                if (widget.allowCode)
                                  BlocBuilder<PlayCubit, PlayState>(
                                    builder: (context, play) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: _EditorSwitch(
                                        codeMode: _codeMode,
                                        onPick:
                                            !_finished &&
                                                play.phase != PlayPhase.running
                                            ? _pickEditor
                                            : null,
                                      ),
                                    ),
                                  ),
                                Expanded(child: editorFor(fit: false)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_touring)
              CoachTour(
                steps: _tourSteps(AppLocalizations.of(context)),
                onDone: _endTour,
              ),
          ],
        ),
      ),
    );
  }

  void _pickEditor(bool code) {
    if (_codeMode == code) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (code && !_codeSeeded) {
      _typed.edit(formatCode(_blocks.program));
      _codeSeeded = true;
    }
    _play.reset();
    setState(() => _codeMode = code);
  }

  /// The card after a run or a finished exercise, or null while editing.
  Widget? _feedbackCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final play = context.watch<PlayCubit>().state;
    if (_finished) {
      final cheer = _cheer!;
      final decision = _decision;
      final replay = decision == null;
      // Back to the puzzle's island, or to the map once the island is
      // complete (a new island opened, or every island is explored).
      final toMap = decision is Advance || decision is MapComplete;
      return _FeedbackCard(
        badge: decision is Review && !_solved
            ? const Icon(
                Icons.diamond_rounded,
                size: 44,
                color: Color(0xFF26C6DA),
              )
            : CheerBadge(cheer: cheer, size: 44),
        title: cheer.text,
        stars: _solved ? _stars : null,
        message: replay ? null : _decisionMessage(l10n, decision),
        actions: [
          // A controller's highlight starts here, so A carries on.
          FilledButton.icon(
            autofocus: true,
            onPressed: widget.onNext,
            icon: Icon(toMap ? Icons.map_rounded : Icons.grid_view_rounded),
            label: Text(toMap ? l10n.toMap : l10n.backToIsland),
          ),
        ],
      );
    }
    if (play.phase == PlayPhase.failed) {
      final cheer = _cheer!;
      return _FeedbackCard(
        badge: CheerBadge(cheer: cheer, size: 44),
        title: cheer.text,
        message: _failureMessage(l10n, play.result!.outcome),
        actions: [
          // B closes the card, like a pop-up.
          GamepadShortcut(
            button: PadButton.b,
            onPressed: _play.reset,
            child: FilledButton.icon(
              onPressed: _play.reset,
              icon: const Icon(Icons.replay_rounded),
              label: Text(l10n.tryAgain),
            ),
          ),
        ],
      );
    }
    return null;
  }

  /// The spoken goal of a level: its words and its voice clip.
  static (String Function(AppLocalizations), String) _goal(Level level) =>
      level.starter != null
      ? ((l) => l.playGoalDebugging, VoiceClips.playGoalDebugging)
      : level.palette.contains(InstructionKind.ifElse)
      ? ((l) => l.playGoalOtherwise, VoiceClips.playGoalOtherwise)
      : level.palette.contains(InstructionKind.untilGoal)
      ? ((l) => l.playGoalUntil, VoiceClips.playGoalUntil)
      : level.palette.contains(InstructionKind.setSteps)
      ? ((l) => l.playGoalVariables, VoiceClips.playGoalVariables)
      : level.palette.contains(InstructionKind.ifPathClear)
      ? ((l) => l.playGoalConditions, VoiceClips.playGoalConditions)
      : level.palette.contains(InstructionKind.call)
      ? ((l) => l.playGoalFunctions, VoiceClips.playGoalFunctions)
      : level.palette.contains(InstructionKind.repeat)
      ? ((l) => l.playGoalLoops, VoiceClips.playGoalLoops)
      : level.stars.isNotEmpty
      ? ((l) => l.playGoalStars, VoiceClips.playGoalStars)
      : ((l) => l.playGoal, VoiceClips.playGoal);

  static String _decisionClip(Decision decision) => switch (decision) {
    Advance() => VoiceClips.decisionAdvance,
    Practice() => VoiceClips.decisionPractice,
    Review() => VoiceClips.decisionReview,
    ReturnFromReview() => VoiceClips.decisionReturn,
    MapComplete() => VoiceClips.decisionMapComplete,
  };

  static String _decisionMessage(AppLocalizations l10n, Decision decision) =>
      switch (decision) {
        Advance() => l10n.decisionAdvance,
        Practice() => l10n.decisionPractice,
        Review() => '${l10n.bonusAdventure} ${l10n.decisionReview}',
        ReturnFromReview() => l10n.decisionReturn,
        MapComplete() => l10n.decisionMapComplete,
      };

  static String? _failureMessage(AppLocalizations l10n, RunOutcome outcome) =>
      switch (outcome) {
        RunOutcome.bumped => l10n.feedbackBumped,
        RunOutcome.stoppedShort => l10n.feedbackStoppedShort,
        RunOutcome.missedStars => l10n.feedbackMissedStars,
        RunOutcome.tooManySteps => l10n.feedbackTooManySteps,
        RunOutcome.success => null,
      };
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.plan,
    required this.goal,
    required this.onListen,
    this.listenKey,
    required this.homePath,
    this.compact = false,
    this.editorSwitch,
  });

  final ExercisePlan plan;
  final String goal;
  final VoidCallback onListen;
  final Key? listenKey;
  final String homePath;

  /// Phones show the island's emblem without its name, to make room for
  /// [editorSwitch].
  final bool compact;
  final Widget? editorSwitch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, box) =>
          Row(children: _children(context, l10n, box.maxWidth)),
    );
  }

  List<Widget> _children(
    BuildContext context,
    AppLocalizations l10n,
    double width,
  ) {
    // Narrow phones (under about 360 dp) with the Code switch drop the
    // emblem, so the buttons keep full tap size; the goal is still spoken.
    final emblem = !compact || editorSwitch == null || width >= 324;
    return [
      GamepadShortcut(
        button: PadButton.b,
        onPressed: () => context.go(homePath),
        child: IconButton.filledTonal(
          tooltip: l10n.home,
          onPressed: () => context.go(homePath),
          icon: const Icon(Icons.home_rounded),
        ),
      ),
      SizedBox(width: compact ? 8 : 16),
      if (emblem) ...[
        Tooltip(
          message: conceptName(l10n, plan.conceptId),
          child: Icon(
            conceptIcon(plan.conceptId),
            color: conceptColor(plan.conceptId),
            size: 36,
            semanticLabel: compact ? conceptName(l10n, plan.conceptId) : null,
          ),
        ),
        const SizedBox(width: 8),
      ],
      if (compact)
        const Spacer()
      else
        Expanded(
          child: Text(
            conceptName(l10n, plan.conceptId),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      if (plan.mode == ExerciseMode.review) ...[
        const SizedBox(width: 8),
        if (compact)
          Tooltip(
            message: l10n.bonusAdventure,
            child: Icon(
              Icons.diamond_rounded,
              color: const Color(0xFF26C6DA),
              size: 32,
              semanticLabel: l10n.bonusAdventure,
            ),
          )
        else
          Flexible(
            child: Chip(
              avatar: const Icon(
                Icons.diamond_rounded,
                color: Color(0xFF26C6DA),
              ),
              label: Text(l10n.bonusAdventure, overflow: TextOverflow.ellipsis),
            ),
          ),
        const SizedBox(width: 8),
      ],
      if (editorSwitch case final editorSwitch?) ...[
        editorSwitch,
        const SizedBox(width: 8),
      ],
      GamepadShortcut(
        button: PadButton.menu,
        onPressed: onListen,
        child: IconButton.filledTonal(
          key: listenKey,
          tooltip: '${l10n.listenAgain}: $goal',
          onPressed: onListen,
          icon: const Icon(Icons.volume_up_rounded),
        ),
      ),
    ];
  }
}

/// Switches between the block editor and typed code. Phones show only the
/// icons, with the words as tooltips.
class _EditorSwitch extends StatelessWidget {
  const _EditorSwitch({
    required this.codeMode,
    required this.onPick,
    this.iconOnly = false,
  });

  final bool codeMode;
  final ValueChanged<bool>? onPick;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    Widget button(bool code) {
      final icon = Icon(code ? Icons.code_rounded : Icons.view_module_rounded);
      final label = code ? l.editorCode : l.editorBlocks;
      final style = OutlinedButton.styleFrom(
        minimumSize: const Size(64, 64),
        padding: iconOnly ? EdgeInsets.zero : null,
        backgroundColor: codeMode == code ? scheme.primaryContainer : null,
      );
      final onPressed = onPick == null ? null : () => onPick!(code);
      // R3 (pressing the right stick) switches to the other one: its badge
      // sits on the one not open. Only readers see the switch.
      Widget pad(Widget child) => GamepadShortcut(
        button: PadButton.rightStick,
        onPressed: codeMode == code ? null : onPressed,
        child: child,
      );
      if (iconOnly) {
        return pad(
          Tooltip(
            message: label,
            child: Semantics(
              selected: codeMode == code,
              label: label,
              excludeSemantics: true,
              button: true,
              child: OutlinedButton(
                style: style,
                onPressed: onPressed,
                child: icon,
              ),
            ),
          ),
        );
      }
      return pad(
        OutlinedButton.icon(
          style: style,
          onPressed: onPressed,
          icon: icon,
          label: Text(label),
        ),
      );
    }

    if (iconOnly) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [button(false), const SizedBox(width: 8), button(true)],
      );
    }
    return Row(
      children: [
        Expanded(child: button(false)),
        const SizedBox(width: 12),
        Expanded(child: button(true)),
      ],
    );
  }
}

/// The number saved in the Step Box: a wide banner above the world, or a
/// narrow box beside it on phones.
class _StepBoxValue extends StatelessWidget {
  const _StepBoxValue({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final value = context.select<PlayCubit, String>(
      (cubit) => cubit.state.storedSteps?.toString() ?? '—',
    );
    final text = Theme.of(context).textTheme;
    if (!compact) {
      return GlassSurface(
        padding: const EdgeInsets.all(8),
        child: Text(
          l.stepBoxValue(value),
          textAlign: TextAlign.center,
          style: text.titleMedium,
        ),
      );
    }
    return Semantics(
      label: l.stepBoxValue(value),
      excludeSemantics: true,
      child: GlassSurface(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              conceptIcon('variables'),
              color: conceptColor('variables'),
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(value, style: text.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.badge,
    required this.title,
    required this.message,
    required this.actions,
    this.stars,
  });

  final Widget badge;
  final String title;

  /// Stars earned (of 3), beside the title after a solved puzzle.
  final int? stars;
  final String? message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => GlassSurface(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          // Badge and words centre as one group; the glyph sits inside its
          // box, so a small gap keeps them visually together.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              badge,
              const SizedBox(width: 12),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          if (stars case final earned?) ...[
                            const SizedBox(width: 12),
                            PuzzleStars(stars: earned, size: 30),
                          ],
                        ],
                      ),
                      if (message != null)
                        Text(
                          message!,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ...actions,
        ],
      ),
    ),
  );
}

class _RunControls extends StatelessWidget {
  const _RunControls({
    required this.onHint,
    required this.hintAfterRuns,
    required this.hintPulseAfterTries,
    this.hintsUsed = 0,
    this.hintStep = -1,
    this.hasPattern = false,
    this.tour,
    this.howTo = false,
    this.compact = false,
    this.codeMode = false,
  });

  final VoidCallback? onHint;

  /// The bulb stays off until the child has tried this many times (Go or
  /// Step with blocks placed, even if the blocks still need fixing).
  final int hintAfterRuns;

  /// More tries, with the bulb on and unused, before it pulses.
  final int hintPulseAfterTries;

  /// Hints asked for so far; the bulb pulses until the first one.
  final int hintsUsed;

  /// The hint the bulb showed last, and whether the level has a pattern to
  /// show: together with the child's program, what the bulb shows next,
  /// which its badge and tooltip tell.
  final int hintStep;
  final bool hasPattern;

  /// Marks the buttons while the guided tour shows.
  final _TourKeys? tour;

  /// The compact row's width besides Go's word: its icon and padding, the
  /// other three buttons and the gaps.
  static const _labelledGoRest = 300.0;

  /// Narrow screens (phones): tighter spacing so all four buttons fit.
  final bool compact;
  final bool codeMode;

  /// Pulse the Go button until the first run, once there's a block.
  final bool howTo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final play = context.watch<PlayCubit>().state;
    final blocks = context.watch<BlocksCubit>();
    final typed = context.watch<TypedCodeCubit>().state;
    final program = codeMode ? typed.program : blocks.program;
    final hasBlocks = codeMode ? typed.canRun : !blocks.state.isEmpty;
    final running = play.phase == PlayPhase.running;
    final canGo = hasBlocks && (play.phase == PlayPhase.editing || running);
    // What the bulb shows next, as [_PlayViewState._showHint] goes round.
    final available = onHint != null && !running && play.tries >= hintAfterRuns;
    final steps = _hintSteps(
      hasPattern: hasPattern,
      hasRing: available && _offTrack(play.level, program).isNotEmpty,
    );
    final next = steps[(hintStep + 1) % steps.length];

    final gap = compact ? 8.0 : 16.0;
    final onGo = canGo && !(running && !play.stepping)
        ? () => context.read<PlayCubit>().run(program!)
        : null;
    return LayoutBuilder(
      builder: (context, box) {
        // Small phones: Go keeps only its play picture when its word
        // doesn't fit, so all four buttons keep full tap size. Words differ
        // by language ("Jalan!" is twice as wide as "Go!"), so measure it.
        final label = TextPainter(
          text: TextSpan(
            text: l10n.run,
            style: Theme.of(
              context,
            ).filledButtonTheme.style?.textStyle?.resolve({}),
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        final iconOnly = box.maxWidth < _labelledGoRest + label.width;
        label.dispose();
        // The unused hint calls out a few tries after it turns on.
        final calling =
            !running &&
            onHint != null &&
            hintsUsed == 0 &&
            play.tries >= hintAfterRuns + hintPulseAfterTries &&
            play.phase != PlayPhase.succeeded;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Pulse(
              key: tour?.go,
              active: howTo && hasBlocks && play.runs == 0 && !running,
              child: GamepadShortcut(
                button: PadButton.x,
                onPressed: onGo,
                child: iconOnly
                    ? Tooltip(
                        message: l10n.run,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onPressed: onGo,
                          child: Icon(
                            Icons.play_arrow_rounded,
                            size: 40,
                            semanticLabel: l10n.run,
                          ),
                        ),
                      )
                    : FilledButton.icon(
                        style: compact
                            ? FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                              )
                            : null,
                        onPressed: onGo,
                        icon: const Icon(Icons.play_arrow_rounded, size: 40),
                        label: Text(l10n.run),
                      ),
              ),
            ),
            SizedBox(width: gap),
            IconButton.filledTonal(
              key: tour?.step,
              tooltip: l10n.step,
              onPressed: canGo && (!running || (play.stepping && !play.playing))
                  ? () => context.read<PlayCubit>().step(program!)
                  : null,
              icon: const Icon(Icons.skip_next_rounded),
            ),
            SizedBox(width: gap),
            IconButton.filledTonal(
              key: tour?.reset,
              tooltip: l10n.reset,
              onPressed: play.phase == PlayPhase.editing
                  ? null
                  : context.read<PlayCubit>().reset,
              icon: const Icon(Icons.replay_rounded),
            ),
            SizedBox(width: gap),
            // A few tries after the bulb turns on, if still unused, it
            // pulses so a child who is stuck notices it, until they ask.
            _Pulse(
              glow: true,
              active: calling,
              // While it calls, the bulb lights up: amber, like a lamp on.
              child: _HintBadge(
                key: tour?.hint,
                next: available ? next : null,
                child: GamepadShortcut(
                  button: PadButton.leftStick,
                  onPressed: available ? onHint : null,
                  badgeOnLeft: true,
                  child: IconButton.filledTonal(
                    tooltip: switch (next) {
                      _Hint.route => l10n.hint,
                      _Hint.pattern => l10n.hintNextPattern,
                      _Hint.ring => l10n.hintNextRing,
                    },
                    style: calling
                        ? IconButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC83D),
                            foregroundColor: const Color(0xFF3E2723),
                          )
                        : null,
                    onPressed: available ? onHint : null,
                    icon: const Icon(Icons.lightbulb_rounded),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The parts of the screen the guided tour points at.
final class _TourKeys {
  final palette = GlobalKey();
  final program = GlobalKey();
  final go = GlobalKey();
  final step = GlobalKey();
  final reset = GlobalKey();
  final hint = GlobalKey();
  final turn = GlobalKey();
  final boards = GlobalKey();
  final listen = GlobalKey();
  final blocks = {for (final type in BlockType.values) type: GlobalKey()};
}

/// Turns the map a quarter turn each tap. Its arrow shows how far the map
/// is turned; away from the start it lights up, so a child sees why the
/// map looks different.
class _TurnMapButton extends StatelessWidget {
  const _TurnMapButton({
    super.key,
    required this.quarterTurns,
    required this.onPressed,
  });

  final int quarterTurns;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final turned = quarterTurns != 0;
    return Semantics(
      value: '${quarterTurns * 90}°',
      child: IconButton.filledTonal(
        tooltip: AppLocalizations.of(context).turnMap,
        style: IconButton.styleFrom(
          backgroundColor: turned
              ? const Color(0xFFFFC83D)
              : Colors.white.withValues(alpha: 0.85),
          foregroundColor: const Color(0xFF263238),
        ),
        onPressed: onPressed,
        icon: const Icon(Icons.rotate_right_rounded),
      ),
    );
  }
}

/// A small badge on the hint bulb showing what it shows next: the way (a
/// route sign), the blocks that repeat (the loop block's sign), or which
/// block to change (an orange ring, like the one it puts on the block).
class _HintBadge extends StatelessWidget {
  const _HintBadge({super.key, required this.next, required this.child});

  /// Null while the bulb can't be used: no badge.
  final _Hint? next;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (next ?? _Hint.route) {
      _Hint.route => (Icons.route_rounded, BlockType.forward.color),
      _Hint.pattern => (Icons.repeat_rounded, BlockType.repeat.color),
      _Hint.ring => (Icons.adjust_rounded, const Color(0xFFFB8C00)),
    };
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -6,
          top: -6,
          child: IgnorePointer(
            child: AnimatedScale(
              scale: next != null ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(icon, size: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Grows and shrinks [child] while [active], to point it out. With [glow]
/// (the hint bulb) it pulses bigger and golden rings ripple out from it, so
/// a child can't miss it; when the system asks for less motion, a steady
/// golden ring shows instead.
class _Pulse extends StatefulWidget {
  const _Pulse({
    super.key,
    required this.active,
    required this.child,
    this.glow = false,
  });

  final bool active;
  final bool glow;
  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with TickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  /// The rings' outward travel, 0 → 1 and again.
  late final _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  var _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
    _update();
  }

  @override
  void didUpdateWidget(_Pulse old) {
    super.didUpdateWidget(old);
    _update();
  }

  void _update() {
    final moving = widget.active && !_still;
    if (moving && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
      if (widget.glow) _ripple.repeat();
    } else if (!moving) {
      _controller
        ..stop()
        ..value = 0;
      _ripple
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    _ripple.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pulse = PaintTransition(
      animation: _curve,
      transform: PaintTransition.scaleUpTo(widget.glow ? 1.22 : 1.12),
      child: widget.child,
    );
    if (!widget.glow) return pulse;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Painted alone (repaint: the ripple), never rebuilding the screen.
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _Ripple(_ripple, active: widget.active, still: _still),
            ),
          ),
        ),
        pulse,
      ],
    );
  }
}

/// Golden rings rippling out from the hint bulb, two at a time.
class _Ripple extends CustomPainter {
  _Ripple(this.travel, {required this.active, required this.still})
    : super(repaint: travel);

  final Animation<double> travel;
  final bool active;
  final bool still;

  static const _gold = Color(0xFFFFB300);

  @override
  void paint(Canvas canvas, Size size) {
    if (!active) return;
    final centre = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    if (still) {
      canvas.drawCircle(
        centre,
        radius + 6,
        Paint()
          ..color = _gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      );
      return;
    }
    for (final phase in [0.0, 0.5]) {
      final t = (travel.value + phase) % 1;
      canvas.drawCircle(
        centre,
        radius * (1 + 0.8 * t),
        Paint()
          ..color = _gold.withValues(alpha: 0.85 * (1 - t))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7 * (1 - t) + 1,
      );
    }
  }

  @override
  bool shouldRepaint(_Ripple old) =>
      old.active != active || old.still != still || old.travel != travel;
}

/// The hints the bulb has, in the order it shows them, one per press.
List<_Hint> _hintSteps({required bool hasPattern, required bool hasRing}) => [
  _Hint.route,
  if (hasPattern) _Hint.pattern,
  if (hasRing) _Hint.ring,
];

/// The child's blocks to change: compared with the closest right answer of
/// the same shape when built around a loop, otherwise judged step by step.
List<String> _offTrack(Level level, Program? program) => program == null
    ? const []
    : loopShapeMistakes(level, program) ?? offTrackBlocks(level, program);

/// What the hint bulb shows, one per press, in this order.
enum _Hint {
  /// The route, as the level's own blocks on the map.
  route,

  /// The shape that repeats, and the loop block that does it.
  pattern,

  /// The child's own block to change, ringed.
  ring,
}

/// [SafeArea] around [child] when [safe]; off, but still in the tree, so
/// the screen below keeps its state when a phone half folds.
class _MaybeSafeArea extends StatelessWidget {
  const _MaybeSafeArea({required this.safe, required this.child});

  final bool safe;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      SafeArea(left: safe, top: safe, right: safe, bottom: safe, child: child);
}
