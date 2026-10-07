import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cobalagi/core/widgets/glass_surface.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/sound_effects.dart';
import '../../../core/audio/voice_clips.dart';
import '../../../core/feedback/cheers.dart';
import '../../../core/responsive/window_class.dart';
import '../../../engine/generator/solver.dart';
import '../../../engine/interpreter/run_event.dart';
import '../../../engine/program/instruction.dart';
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
import '../../learning/cubit/learning_cubit.dart';
import '../../learning/view/concepts.dart';
import '../cubit/play_cubit.dart';
import 'world/world_game.dart';

/// One puzzle: the world, the editor and run controls. [onFinished] records
/// the result and may return what the learning loop decided; replays return
/// null.
class PlayView extends StatefulWidget {
  const PlayView({
    super.key,
    required this.exercise,
    required this.skipAfterRuns,
    required this.homePath,
    required this.onFinished,
    required this.onNext,
    this.showHowTo = false,
    this.allowCode = false,
  });

  final Exercise exercise;

  /// Offers the Code tab beside the blocks: for children who read, or when
  /// a parent turns it on. Otherwise only picture blocks show.
  final bool allowCode;

  /// For a child who hasn't solved a puzzle yet: a hand shows how to add a
  /// block, then the Go button pulses, until the first run.
  final bool showHowTo;
  final int skipAfterRuns;
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
  final _clock = Stopwatch()..start();
  var _hints = 0;
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _sayGoal());
  }

  /// Missing where a play view stands alone, as in some tests.
  late final PlayClock? _playClock = context.read<PlayClock?>();

  @override
  void dispose() {
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

  Future<void> _finish({required bool succeeded}) async {
    if (_finishing) return;
    _finishing = true;
    _clock.stop();
    final plan = widget.exercise.plan;
    final decision = await widget.onFinished(
      ExerciseResult(
        conceptId: plan.conceptId,
        levelId: _level.id,
        mode: plan.mode,
        difficulty: plan.difficulty,
        succeeded: succeeded,
        runs: _play.state.runs,
        hintsUsed: _hints,
        duration: _clock.elapsed,
      ),
    );
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
    final solution = solve(_level);
    if (solution == null) return;
    setState(() => _hints++);
    final font = Theme.of(context).textTheme.titleLarge?.fontFamily;
    // First the route as the level's own blocks, in their colours. Asked
    // again on islands with a loop block: the shape that repeats, and the
    // loop block that does it. Then the two take turns.
    final pattern = _hints.isEven
        ? patternHintMarks(_level, solution, labelFont: font)
        : null;
    _game.showHint(pattern ?? hintMarks(_level, solution, labelFont: font));
    // Pre-readers hear what the pattern means.
    if (pattern != null) _say(VoiceClips.hintPattern);
  }

  void _onPlayChanged(BuildContext context, PlayState state) {
    _game.apply(state);
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
          BlocListener<BlocksCubit, Object>(
            listener: (_, _) {
              final play = _play.state;
              if (play.phase != PlayPhase.editing || play.issues.isNotEmpty) {
                _play.reset();
              }
            },
          ),
        ],
        child: Scaffold(
          // Phones pad inside their glass bars instead, so the page can
          // scroll under the bars from edge to edge.
          body: SafeArea(
            child: WindowClassBuilder(
              builder: (context, windowClass) {
                final compact = windowClass == WindowClass.compact;
                // Phones held sideways: wide enough for two columns, too short
                // for the tablet's big blocks and fixed editor.
                final short =
                    !compact && MediaQuery.sizeOf(context).height < 500;
                // Small blocks, an icon editor switch and a page that scrolls.
                final tight = compact || short;
                // Tall screens (phones, tablets held upright) stack the world
                // over the editor in one scrolling page.
                final screen = MediaQuery.sizeOf(context);
                final stacked = compact || screen.height > screen.width * 1.15;
                final topBar = _TopBar(
                  plan: widget.exercise.plan,
                  goal: _goal(_level).$1(AppLocalizations.of(context)),
                  onListen: _sayGoal,
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
                                !_finished && play.phase != PlayPhase.running
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
                        if (_level.palette.contains(InstructionKind.setSteps))
                          Padding(
                            padding: tight
                                ? const EdgeInsets.fromLTRB(8, 8, 0, 8)
                                : const EdgeInsets.fromLTRB(8, 8, 8, 0),
                            child: _StepBoxValue(compact: tight),
                          ),
                        Expanded(child: GameWidget(game: _game)),
                      ],
                    ),
                  ),
                );
                // Feedback replaces the controls, so it never hides the
                // world, and the controls aren't usable meanwhile anyway.
                final controls =
                    _feedbackCard(context) ??
                    _RunControls(
                      onHint: _finished ? null : _showHint,
                      hintsUsed: _hints,
                      howTo: widget.showHowTo,
                      compact: tight,
                      codeMode: _codeMode,
                    );
                Widget editorFor({required bool fit}) =>
                    BlocBuilder<PlayCubit, PlayState>(
                      builder: (context, play) {
                        final enabled =
                            !_finished && play.phase != PlayPhase.running;
                        return _codeMode
                            ? TypedCodeEditor(
                                enabled: enabled,
                                activeBlockId: play.activeBlockId,
                                fitContent: fit,
                              )
                            : BlockEditor(
                                palette: _level.palette,
                                blockSize: tight ? 56.0 : 72.0,
                                activeBlockId: play.activeBlockId,
                                issueBlockIds: {
                                  for (final issue in play.issues)
                                    ?issue.blockId,
                                },
                                enabled: enabled,
                                showTips: !tight,
                                fitContent: fit,
                                showHowTo: widget.showHowTo && play.runs == 0,
                              );
                      },
                    );
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
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            child: controls,
                          ),
                    builder: (context, insets) => LayoutBuilder(
                      builder: (context, box) => SingleChildScrollView(
                        controller: _page,
                        padding:
                            insets + const EdgeInsets.symmetric(horizontal: 16),
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
                                    (box.maxHeight - insets.vertical) * 0.75,
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
                              controls,
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
                            controls,
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
      return _FeedbackCard(
        badge: decision is Review && !_solved
            ? const Icon(
                Icons.diamond_rounded,
                size: 44,
                color: Color(0xFF26C6DA),
              )
            : CheerBadge(cheer: cheer, size: 44),
        title: cheer.text,
        message: replay ? null : _decisionMessage(l10n, decision),
        actions: [
          FilledButton.icon(
            onPressed: widget.onNext,
            icon: Icon(
              replay ? Icons.grid_view_rounded : Icons.arrow_forward_rounded,
            ),
            label: Text(replay ? l10n.backToIsland : l10n.nextLevel),
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
          if (play.runs >= widget.skipAfterRuns)
            OutlinedButton.icon(
              onPressed: () => _finish(succeeded: false),
              icon: const Icon(Icons.shuffle_rounded),
              label: Text(l10n.skipPuzzle),
            ),
          FilledButton.icon(
            onPressed: _play.reset,
            icon: const Icon(Icons.replay_rounded),
            label: Text(l10n.tryAgain),
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
    required this.homePath,
    this.compact = false,
    this.editorSwitch,
  });

  final ExercisePlan plan;
  final String goal;
  final VoidCallback onListen;
  final String homePath;

  /// Phones show the island's emblem without its name, to make room for
  /// [editorSwitch].
  final bool compact;
  final Widget? editorSwitch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        IconButton.filledTonal(
          tooltip: l10n.home,
          onPressed: () => context.go(homePath),
          icon: const Icon(Icons.home_rounded),
        ),
        const SizedBox(width: 16),
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
                label: Text(
                  l10n.bonusAdventure,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
        if (editorSwitch case final editorSwitch?) ...[
          editorSwitch,
          const SizedBox(width: 8),
        ],
        IconButton.filledTonal(
          tooltip: '${l10n.listenAgain}: $goal',
          onPressed: onListen,
          icon: const Icon(Icons.volume_up_rounded),
        ),
      ],
    );
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
      if (iconOnly) {
        return Tooltip(
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
        );
      }
      return OutlinedButton.icon(
        style: style,
        onPressed: onPressed,
        icon: icon,
        label: Text(label),
      );
    }

    if (iconOnly) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [button(false), const SizedBox(width: 4), button(true)],
      );
    }
    return Row(
      children: [
        Expanded(child: button(false)),
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
  });

  final Widget badge;
  final String title;
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
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium,
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
    this.hintsUsed = 0,
    this.howTo = false,
    this.compact = false,
    this.codeMode = false,
  });

  final VoidCallback? onHint;

  /// Hints asked for so far; the bulb pulses until the first one.
  final int hintsUsed;

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

    final gap = compact ? 8.0 : 16.0;
    final onGo = canGo && !(running && !play.stepping)
        ? () => context.read<PlayCubit>().run(program!)
        : null;
    return LayoutBuilder(
      builder: (context, box) {
        // Small phones: Go keeps only its play picture, so all four
        // buttons fit at full tap size.
        final iconOnly = box.maxWidth < 340;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Pulse(
              active: howTo && hasBlocks && play.runs == 0 && !running,
              child: iconOnly
                  ? Tooltip(
                      message: l10n.run,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
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
            SizedBox(width: gap),
            IconButton.filledTonal(
              tooltip: l10n.step,
              onPressed: canGo && (!running || (play.stepping && !play.playing))
                  ? () => context.read<PlayCubit>().step(program!)
                  : null,
              icon: const Icon(Icons.skip_next_rounded),
            ),
            SizedBox(width: gap),
            IconButton.filledTonal(
              tooltip: l10n.reset,
              onPressed: play.phase == PlayPhase.editing
                  ? null
                  : context.read<PlayCubit>().reset,
              icon: const Icon(Icons.replay_rounded),
            ),
            SizedBox(width: gap),
            // After two runs that didn't reach the flag, the bulb pulses so
            // a child who is stuck notices it, until they ask for a hint.
            _Pulse(
              active:
                  !running &&
                  onHint != null &&
                  hintsUsed == 0 &&
                  play.runs >= 2 &&
                  play.phase != PlayPhase.succeeded,
              child: IconButton.filledTonal(
                tooltip: l10n.hint,
                onPressed: running ? null : onHint,
                icon: const Icon(Icons.lightbulb_rounded),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Gently grows and shrinks [child] while [active], to point it out.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    _update();
  }

  @override
  void didUpdateWidget(_Pulse old) {
    super.didUpdateWidget(old);
    _update();
  }

  void _update() {
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: Tween(
      begin: 1.0,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
    child: widget.child,
  );
}
