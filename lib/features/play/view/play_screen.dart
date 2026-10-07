import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../learning/cubit/learning_cubit.dart';
import '../../play_time/cubit/break_reminder_cubit.dart';
import '../../play_time/data/play_clock.dart';
import '../../play_time/view/break_screen.dart';
import '../../tutorial/view/tutorial_view.dart';
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

  /// Demos watched (or skipped) in this session, before the save lands.
  final _watched = <String>{};

  /// The parent's break reminder is due: a break comes before the next
  /// puzzle. Checked on arrival and between puzzles, never mid-puzzle.
  late var _onBreak = _breakDue();

  bool _breakDue() =>
      context.read<PlayClock>().isDue(context.read<BreakReminderCubit>().state);

  @override
  Widget build(BuildContext context) {
    final learning = context.watch<LearningCubit>();
    if (learning.state.learner == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_onBreak) {
      return BreakScreen(onContinue: () => setState(() => _onBreak = false));
    }
    final exercise = _exercise ??= learning.nextExercise();
    // The first visit to an island starts with its "Watch me!" demo.
    final concept = exercise.plan.conceptId;
    final tutorial = learning.curriculum.tutorials[concept];
    if (tutorial != null &&
        !_watched.contains(concept) &&
        !learning.state.learner!.tutorialsSeen.contains(concept)) {
      return TutorialView(
        key: ValueKey('tutorial-$concept'),
        tutorial: tutorial,
        onDone: () {
          setState(() => _watched.add(concept));
          learning.markTutorialSeen(concept);
        },
      );
    }
    return PlayView(
      key: ValueKey(exercise.key),
      exercise: exercise,
      skipAfterRuns: learning.engine.config.offerSkipAfterRuns,
      homePath: '/child/${widget.profileId}',
      onFinished: learning.record,
      onNext: () => setState(() {
        _exercise = null;
        _onBreak = _breakDue();
      }),
      // Readers (from the warm-up game, or a parent's choice) can type code.
      allowCode: learning.state.learner!.placement?.readsWords ?? false,
      // Until the child has solved a first puzzle.
      showHowTo: learning.state.learner!.progress.values.every(
        (p) => p.solvedLessons.isEmpty && p.scores.every((s) => s == 0),
      ),
    );
  }
}
