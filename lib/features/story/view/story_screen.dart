import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:cobalagi/features/learning/cubit/learning_cubit.dart';
import 'package:cobalagi/features/story/data/story_scene.dart';
import 'package:cobalagi/features/story/view/arrival_scenes.dart';
import 'package:cobalagi/features/story/view/ending_scenes.dart';
import 'package:cobalagi/features/story/view/intro_scene.dart';
import 'package:cobalagi/features/story/view/story_player.dart';
import 'package:cobalagi/learning/learner_state.dart';
import 'package:cobalagi/learning/story.dart';

/// Plays a scene of the Star fuel story, then goes back to the map. The map
/// opens it once per child, and its book button plays it again.
class StoryScreen extends StatelessWidget {
  const StoryScreen({super.key, required this.profileId, required this.scene});

  final int profileId;

  /// A key of [scenes].
  final String scene;

  /// The scenes by their route name (`/child/<id>/story/<name>`): the
  /// intro, each planet's arrival (`arrival-<concept>`), and the endings and
  /// the new planet scene for each planet that can be the last one
  /// (`ending-`, `full-again-` and `new-planet-<concept>`).
  static final scenes = <String, StoryScene>{
    'intro': const IntroScene(),
    for (final MapEntry(:key, :value) in arrivalScenes.entries) ...{
      'arrival-$key': value,
      'ending-$key': EndingScene(key),
      'full-again-$key': FullAgainScene(key),
      'new-planet-$key': NewPlanetScene(key),
    },
  };

  /// The route name of the scene the map plays on its own, if one is due:
  /// the intro, then the new planet scene after an update, then the ending
  /// once the child has just finished the last planet ([mapComplete]).
  static String? dueOnMap(
    LearnerState learner,
    String lastPlanet, {
    required bool mapComplete,
  }) {
    if (Story.introDue(learner)) return 'intro';
    if (Story.newPlanetDue(learner, lastPlanet)) {
      return 'new-planet-$lastPlanet';
    }
    if (!mapComplete) return null;
    return switch (Story.endingDue(learner, lastPlanet)) {
      Ending.whole => 'ending-$lastPlanet',
      Ending.fullAgain => 'full-again-$lastPlanet',
      null => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final map = '/child/$profileId';
    final story = scenes[scene];
    if (story == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go(map));
      return const Scaffold();
    }
    return StoryPlayer(
      scene: story,
      onDone: () {
        context.read<LearningCubit>().markTutorialSeen(story.id);
        context.go(map);
      },
    );
  }
}
