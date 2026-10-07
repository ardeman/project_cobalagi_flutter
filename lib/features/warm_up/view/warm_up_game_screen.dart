import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/audio/voice_clips.dart';
import '../../../learning/placement/pretest_question.dart';
import '../../../learning/warm_up/warm_up.dart';
import '../../learning/cubit/learning_cubit.dart';
import '../../pretest/view/question_game.dart';

/// One round of a Warm-up island game, then "Play again" or back to the
/// island. Only the game's stars are saved; the coding path never changes.
class WarmUpGameScreen extends StatefulWidget {
  const WarmUpGameScreen({
    super.key,
    required this.profileId,
    required this.game,
  });

  final int profileId;
  final WarmUpGame game;

  @override
  State<WarmUpGameScreen> createState() => _WarmUpGameScreenState();
}

class _WarmUpGameScreenState extends State<WarmUpGameScreen> {
  /// Made once the child's progress has loaded.
  WarmUpRound? _round;

  WarmUpRound _newRound() =>
      context.read<LearningCubit>().startWarmUp(widget.game);

  @override
  Widget build(BuildContext context) {
    void toIsland() => context.go('/child/${widget.profileId}/warm-up');
    if (context.watch<LearningCubit>().state.learner == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final round = _round ??= _newRound();
    return QuestionGame(
      key: ObjectKey(round),
      round: round,
      steps: round.length,
      onClose: toIsland,
      onFinished: () => context.read<LearningCubit>().recordWarmUp(round),
      doneClip: VoiceClips.warmUpDone,
      done: (_) => _Done(
        stars: round.best,
        onAgain: () => setState(() => _round = _newRound()),
        onIsland: toIsland,
      ),
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({
    required this.stars,
    required this.onAgain,
    required this.onIsland,
  });

  final int stars;
  final VoidCallback onAgain;
  final VoidCallback onIsland;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = min(120.0, MediaQuery.sizeOf(context).height * 0.16);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < maxSkillLevel; i++)
              Icon(
                i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size,
                color: const Color(0xFFFFC83D),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l10n.warmUpDone,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 32),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            OutlinedButton.icon(
              onPressed: onIsland,
              icon: const Icon(Icons.grid_view_rounded),
              label: Text(l10n.backToIsland),
            ),
            FilledButton.icon(
              onPressed: onAgain,
              icon: const Icon(Icons.replay_rounded),
              label: Text(l10n.playAgain),
            ),
          ],
        ),
      ],
    );
  }
}
