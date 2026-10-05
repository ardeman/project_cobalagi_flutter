import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/responsive/window_class.dart';
import '../../../engine/interpreter/run_event.dart';
import '../../../engine/world/level.dart';
import '../../editors/icon_blocks/cubit/icon_blocks_cubit.dart';
import '../../editors/icon_blocks/view/icon_block_editor.dart';
import '../cubit/play_cubit.dart';
import '../data/level_repository.dart';
import 'world/world_game.dart';

class PlayScreen extends StatelessWidget {
  const PlayScreen({
    super.key,
    required this.profileId,
    required this.levelIndex,
  });

  final int profileId;
  final int levelIndex;

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: context.read<LevelRepository>().loadAll(),
    builder: (context, snapshot) {
      final levels = snapshot.data;
      if (levels == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final index = levelIndex.clamp(0, levels.length - 1);
      return _PlayView(
        key: ValueKey(levels[index].id),
        level: levels[index],
        number: index + 1,
        isLast: index == levels.length - 1,
        homePath: '/child/$profileId',
        nextPath: '/child/$profileId/level/${index + 1}',
      );
    },
  );
}

class _PlayView extends StatefulWidget {
  const _PlayView({
    super.key,
    required this.level,
    required this.number,
    required this.isLast,
    required this.homePath,
    required this.nextPath,
  });

  final Level level;
  final int number;
  final bool isLast;
  final String homePath;
  final String nextPath;

  @override
  State<_PlayView> createState() => _PlayViewState();
}

class _PlayViewState extends State<_PlayView> {
  late final _blocks = IconBlocksCubit(maxBlocks: widget.level.maxBlocks);
  late final _play = PlayCubit(widget.level);
  late final _game = WorldGame(
    level: widget.level,
    onEventShown: _play.eventShown,
  );

  @override
  void dispose() {
    _blocks.close();
    _play.close();
    super.dispose();
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
                final blockSize = compact ? 56.0 : 72.0;
                final world = Column(
                  children: [
                    _TopBar(number: widget.number, homePath: widget.homePath),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _WorldPanel(
                        game: _game,
                        isLast: widget.isLast,
                        homePath: widget.homePath,
                        nextPath: widget.nextPath,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _RunControls(),
                  ],
                );
                final editor = BlocBuilder<PlayCubit, PlayState>(
                  builder: (context, play) => IconBlockEditor(
                    palette: widget.level.palette,
                    blockSize: blockSize,
                    activeBlockId: play.activeBlockId,
                    issueBlockIds: {
                      for (final issue in play.issues) ?issue.blockId,
                    },
                    enabled: play.phase != PlayPhase.running,
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
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.number, required this.homePath});

  final int number;
  final String homePath;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton.filledTonal(
        tooltip: AppLocalizations.of(context).home,
        onPressed: () => context.go(homePath),
        icon: const Icon(Icons.home_rounded),
      ),
      const SizedBox(width: 16),
      Text(
        AppLocalizations.of(context).levelNumber(number),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    ],
  );
}

class _WorldPanel extends StatelessWidget {
  const _WorldPanel({
    required this.game,
    required this.isLast,
    required this.homePath,
    required this.nextPath,
  });

  final WorldGame game;
  final bool isLast;
  final String homePath;
  final String nextPath;

  @override
  Widget build(BuildContext context) {
    final play = context.watch<PlayCubit>().state;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(game: game),
          if (play.phase == PlayPhase.succeeded)
            _FeedbackCard(
              icon: Icons.star_rounded,
              iconColor: const Color(0xFFFFC83D),
              title: AppLocalizations.of(context).successTitle,
              message: isLast
                  ? AppLocalizations.of(context).allLevelsDone
                  : null,
              actions: [
                OutlinedButton.icon(
                  onPressed: context.read<PlayCubit>().reset,
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(AppLocalizations.of(context).playAgain),
                ),
                FilledButton.icon(
                  onPressed: () => context.go(isLast ? homePath : nextPath),
                  icon: Icon(
                    isLast ? Icons.home_rounded : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    isLast
                        ? AppLocalizations.of(context).home
                        : AppLocalizations.of(context).nextLevel,
                  ),
                ),
              ],
            )
          else if (play.phase == PlayPhase.failed)
            _FeedbackCard(
              icon: Icons.refresh_rounded,
              iconColor: Theme.of(context).colorScheme.primary,
              title: AppLocalizations.of(context).tryAgain,
              message: _failureMessage(
                AppLocalizations.of(context),
                play.result!.outcome,
              ),
              actions: [
                FilledButton.icon(
                  onPressed: context.read<PlayCubit>().reset,
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(AppLocalizations.of(context).tryAgain),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static String? _failureMessage(AppLocalizations l10n, RunOutcome outcome) =>
      switch (outcome) {
        RunOutcome.bumped => l10n.feedbackBumped,
        RunOutcome.stoppedShort => l10n.feedbackStoppedShort,
        RunOutcome.missedStars => l10n.feedbackMissedStars,
        RunOutcome.tooManySteps => l10n.feedbackTooManySteps,
        RunOutcome.success => null,
      };
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
              Column(
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
              ...actions,
            ],
          ),
        ),
      ),
    ),
  );
}

class _RunControls extends StatelessWidget {
  const _RunControls();

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
      ],
    );
  }
}
