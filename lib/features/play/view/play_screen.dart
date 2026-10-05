import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/responsive/window_class.dart';
import '../../../engine/generator/solver.dart';
import '../../../engine/interpreter/interpreter.dart';
import '../../../engine/interpreter/run_event.dart';
import '../../../learning/exercise_result.dart';
import '../../../learning/learning_engine.dart';
import '../../editors/icon_blocks/cubit/icon_blocks_cubit.dart';
import '../../editors/icon_blocks/view/icon_block_editor.dart';
import '../../learning/cubit/learning_cubit.dart';
import '../../learning/view/concepts.dart';
import '../cubit/play_cubit.dart';
import 'world/world_game.dart';

/// Serves exercises from the learning loop, one after another.
class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key, required this.profileId});

  final int profileId;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  Exercise? _exercise;

  @override
  Widget build(BuildContext context) {
    final learning = context.watch<LearningCubit>();
    if (learning.state.learner == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final exercise = _exercise ??= learning.nextExercise();
    return _PlayView(
      key: ValueKey(exercise.key),
      exercise: exercise,
      skipAfterRuns: learning.engine.config.offerSkipAfterRuns,
      homePath: '/child/${widget.profileId}',
      onFinished: learning.record,
      onNext: () => setState(() => _exercise = learning.nextExercise()),
    );
  }
}

class _PlayView extends StatefulWidget {
  const _PlayView({
    super.key,
    required this.exercise,
    required this.skipAfterRuns,
    required this.homePath,
    required this.onFinished,
    required this.onNext,
  });

  final Exercise exercise;
  final int skipAfterRuns;
  final String homePath;
  final Future<Decision> Function(ExerciseResult result) onFinished;
  final VoidCallback onNext;

  @override
  State<_PlayView> createState() => _PlayViewState();
}

class _PlayViewState extends State<_PlayView> {
  late final _level = widget.exercise.level;
  late final _blocks = IconBlocksCubit(maxBlocks: _level.maxBlocks);
  late final _play = PlayCubit(_level);
  late final _game = WorldGame(level: _level, onEventShown: _play.eventShown);
  final _clock = Stopwatch()..start();
  var _hints = 0;
  var _finishing = false;

  /// Set once the exercise is recorded; the card then offers the next one.
  Decision? _decision;
  var _solved = false;

  @override
  void dispose() {
    _blocks.close();
    _play.close();
    super.dispose();
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
      setState(() {
        _decision = decision;
        _solved = succeeded;
      });
    }
  }

  void _showHint() {
    if (_play.state.phase != PlayPhase.editing) _play.reset();
    final solution = solve(_level);
    if (solution == null) return;
    setState(() => _hints++);
    _game.showHint([
      _level.start,
      for (final event in runProgram(solution, _level).events)
        if (event is Moved) event.to,
    ]);
  }

  void _onPlayChanged(BuildContext context, PlayState state) {
    _game.apply(state);
    final clip = switch (state.phase) {
      PlayPhase.succeeded => 'success',
      PlayPhase.failed => 'try_again',
      _ => null,
    };
    if (clip != null) {
      context.read<AudioService>().playVoice(
        clip,
        languageCode: Localizations.localeOf(context).languageCode,
      );
    }
    if (state.phase == PlayPhase.succeeded) _finish(succeeded: true);
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: _blocks),
      BlocProvider.value(value: _play),
    ],
    child: MultiBlocListener(
      listeners: [
        BlocListener<PlayCubit, PlayState>(listener: _onPlayChanged),
        // Editing the program after a run puts the world back at the start.
        BlocListener<IconBlocksCubit, Object>(
          listener: (_, _) {
            final play = _play.state;
            if (play.phase != PlayPhase.editing || play.issues.isNotEmpty) {
              _play.reset();
            }
          },
        ),
      ],
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: WindowClassBuilder(
              builder: (context, windowClass) {
                final compact = windowClass == WindowClass.compact;
                final world = Column(
                  children: [
                    _TopBar(
                      plan: widget.exercise.plan,
                      homePath: widget.homePath,
                    ),
                    const SizedBox(height: 12),
                    Expanded(child: _worldPanel(context)),
                    const SizedBox(height: 12),
                    _RunControls(onHint: _decision == null ? _showHint : null),
                  ],
                );
                final editor = BlocBuilder<PlayCubit, PlayState>(
                  builder: (context, play) => IconBlockEditor(
                    palette: _level.palette,
                    blockSize: compact ? 56.0 : 72.0,
                    activeBlockId: play.activeBlockId,
                    issueBlockIds: {
                      for (final issue in play.issues) ?issue.blockId,
                    },
                    enabled:
                        _decision == null && play.phase != PlayPhase.running,
                  ),
                );
                return compact
                    ? Column(
                        children: [
                          Expanded(flex: 5, child: world),
                          const SizedBox(height: 16),
                          Expanded(flex: 4, child: editor),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(flex: 3, child: world),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: editor),
                        ],
                      );
              },
            ),
          ),
        ),
      ),
    ),
  );

  Widget _worldPanel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final play = context.watch<PlayCubit>().state;
    final Widget? card;
    if (_decision case final decision?) {
      card = _FeedbackCard(
        icon: _solved
            ? Icons.star_rounded
            : decision is Review
            ? Icons.diamond_rounded
            : Icons.thumb_up_rounded,
        iconColor: _solved ? const Color(0xFFFFC83D) : const Color(0xFF26C6DA),
        title: _solved ? l10n.successTitle : l10n.goodTry,
        message: _decisionMessage(l10n, decision),
        actions: [
          FilledButton.icon(
            onPressed: widget.onNext,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(l10n.nextLevel),
          ),
        ],
      );
    } else if (play.phase == PlayPhase.failed) {
      card = _FeedbackCard(
        icon: Icons.refresh_rounded,
        iconColor: Theme.of(context).colorScheme.primary,
        title: l10n.tryAgain,
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
    } else {
      card = null;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(game: _game),
          ?card,
        ],
      ),
    );
  }

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
  const _TopBar({required this.plan, required this.homePath});

  final ExercisePlan plan;
  final String homePath;

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
        Icon(
          conceptIcon(plan.conceptId),
          color: conceptColor(plan.conceptId),
          size: 36,
        ),
        const SizedBox(width: 8),
        Text(
          conceptName(l10n, plan.conceptId),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (plan.mode == ExerciseMode.review) ...[
          const SizedBox(width: 16),
          Chip(
            avatar: const Icon(Icons.diamond_rounded, color: Color(0xFF26C6DA)),
            label: Text(l10n.bonusAdventure),
          ),
        ],
      ],
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.actions,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomCenter,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Icon(icon, size: 56, color: iconColor),
              ConstrainedBox(
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
              ...actions,
            ],
          ),
        ),
      ),
    ),
  );
}

class _RunControls extends StatelessWidget {
  const _RunControls({required this.onHint});

  final VoidCallback? onHint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final play = context.watch<PlayCubit>().state;
    final blocks = context.watch<IconBlocksCubit>();
    final hasBlocks = blocks.state.isNotEmpty;
    final running = play.phase == PlayPhase.running;
    final canGo = hasBlocks && (play.phase == PlayPhase.editing || running);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: canGo && !(running && !play.stepping)
              ? () => context.read<PlayCubit>().run(blocks.program)
              : null,
          icon: const Icon(Icons.play_arrow_rounded, size: 40),
          label: Text(l10n.run),
        ),
        const SizedBox(width: 16),
        IconButton.filledTonal(
          tooltip: l10n.step,
          onPressed: canGo && (!running || (play.stepping && !play.playing))
              ? () => context.read<PlayCubit>().step(blocks.program)
              : null,
          icon: const Icon(Icons.skip_next_rounded),
        ),
        const SizedBox(width: 16),
        IconButton.filledTonal(
          tooltip: l10n.reset,
          onPressed: play.phase == PlayPhase.editing
              ? null
              : context.read<PlayCubit>().reset,
          icon: const Icon(Icons.replay_rounded),
        ),
        const SizedBox(width: 16),
        IconButton.filledTonal(
          tooltip: l10n.hint,
          onPressed: running ? null : onHint,
          icon: const Icon(Icons.lightbulb_rounded),
        ),
      ],
    );
  }
}
