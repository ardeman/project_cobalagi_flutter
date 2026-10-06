import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../learning/cubit/learning_cubit.dart';
import 'play_view.dart';

/// Plays a lesson again from its island. It never changes what comes next.
class ReplayScreen extends StatefulWidget {
  const ReplayScreen({
    super.key,
    required this.profileId,
    required this.levelId,
  });

  final int profileId;
  final String levelId;

  @override
  State<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends State<ReplayScreen> {
  Exercise? _exercise;

  @override
  Widget build(BuildContext context) {
    final learning = context.watch<LearningCubit>();
    if (learning.state.learner == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final exercise = _exercise ??= learning.replayExercise(widget.levelId);
    final mapPath = '/child/${widget.profileId}';
    if (exercise == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go(mapPath));
      return const Scaffold();
    }
    final islandPath = '$mapPath/island/${exercise.plan.conceptId}';
    return PlayView(
      key: ValueKey(exercise.key),
      exercise: exercise,
      skipAfterRuns: learning.engine.config.offerSkipAfterRuns,
      homePath: islandPath,
      onFinished: learning.recordReplay,
      onNext: () => context.go(islandPath),
    );
  }
}
