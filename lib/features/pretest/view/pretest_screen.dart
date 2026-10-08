import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/audio/voice_clips.dart';
import '../../../learning/placement/pretest_session.dart';
import '../../learning/cubit/learning_cubit.dart';
import 'question_game.dart';

/// The voice-led warm-up game that places a child on the map.
class PretestScreen extends StatefulWidget {
  const PretestScreen({super.key, required this.profileId});

  final int profileId;

  @override
  State<PretestScreen> createState() => _PretestScreenState();
}

class _PretestScreenState extends State<PretestScreen> {
  late final PretestSession _session = context
      .read<LearningCubit>()
      .startPretest();

  @override
  Widget build(BuildContext context) {
    void toMap() => context.go('/child/${widget.profileId}');
    return QuestionGame(
      round: _session,
      steps: _session.skills.length,
      onClose: toMap,
      onFinished: () =>
          context.read<LearningCubit>().completePretest(_session.levels),
      doneClip: VoiceClips.pretestDone,
      done: (_) => _Done(onGo: toMap),
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.onGo});

  final VoidCallback onGo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.emoji_events_rounded,
          // Smaller on short screens, so the button stays in view.
          size: min(160, MediaQuery.sizeOf(context).height * 0.22),
          color: const Color(0xFFFFC83D),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.pretestDone,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: onGo,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: Text(l10n.startAdventure),
        ),
      ],
    );
  }
}
