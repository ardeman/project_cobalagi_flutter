import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../learning/cubit/learning_cubit.dart';
import 'play_view.dart';

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
    return PlayView(
      key: ValueKey(exercise.key),
      exercise: exercise,
      skipAfterRuns: learning.engine.config.offerSkipAfterRuns,
      homePath: '/child/${widget.profileId}',
      onFinished: learning.record,
      onNext: () => setState(() => _exercise = learning.nextExercise()),
    );
  }
}
