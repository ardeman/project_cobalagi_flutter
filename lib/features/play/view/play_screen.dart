import 'package:cobalagi/core/responsive/fold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../learning/learning_engine.dart';
import '../../../learning/story.dart';
import '../../learning/cubit/learning_cubit.dart';
import '../../play_time/cubit/break_reminder_cubit.dart';
import '../../profiles/cubit/profiles_cubit.dart';
import '../../profiles/view/profile_avatar.dart';
import '../../play_time/data/play_clock.dart';
import '../../play_time/view/break_screen.dart';
import '../../story/view/arrival_scenes.dart';
import '../../story/view/story_player.dart';
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

  /// Demos and arrival scenes watched (or skipped) in this session, before
  /// the save lands.
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
      return const FoldHalf(
        child: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    if (_onBreak) {
      return FoldHalf(
        child: BreakScreen(onContinue: () => setState(() => _onBreak = false)),
      );
    }
    final exercise = _exercise ??= learning.nextExercise();
    final concept = exercise.plan.conceptId;
    // The first visit to an island starts with its arrival scene of the
    // Star fuel story, then its "Watch me!" demo.
    final arrival = arrivalScenes[concept];
    if (arrival != null &&
        !_watched.contains(arrival.id) &&
        Story.arrivalDue(
          learning.state.learner!,
          concept,
          exercise.plan.mode,
        )) {
      final profile = context.read<ProfilesCubit>().state.byId(
        widget.profileId,
      );
      return StoryPlayer(
        key: ValueKey(arrival.id),
        scene: arrival,
        emblem: profile == null ? null : avatarEmblem(profile.avatar),
        onDone: () {
          setState(() => _watched.add(arrival.id));
          learning.markTutorialSeen(arrival.id);
        },
      );
    }
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
      hintAfterRuns: learning.engine.config.hintAfterRuns,
      hintPulseAfterTries: learning.engine.config.hintPulseAfterTries,
      starsFor: (result) => result.stars(learning.engine.config),
      homePath: '/child/${widget.profileId}',
      onFinished: learning.record,
      onNext: () {
        // The island is complete: the map (which celebrates a new island).
        // Otherwise back to the puzzle's island, where "Continue the
        // adventure" serves the next one.
        final decision = learning.state.lastDecision;
        context.go(
          learning.state.islandToCelebrate != null ||
                  decision is Advance ||
                  decision is MapComplete
              ? '/child/${widget.profileId}'
              : '/child/${widget.profileId}/island/$concept',
        );
      },
      // Readers (from the warm-up game, or a parent's choice) can type code.
      allowCode: learning.state.learner!.placement?.readsWords ?? false,
      showTour: learning.tourDue(LearningCubit.playTour),
      onTourDone: () => learning.markTutorialSeen(LearningCubit.playTour),
      // Until the child has solved a first puzzle.
      showHowTo: learning.state.learner!.progress.values.every(
        (p) => p.solvedLessons.isEmpty && p.scores.every((s) => s == 0),
      ),
    );
  }
}
