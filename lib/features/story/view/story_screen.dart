import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:cobalagi/features/learning/cubit/learning_cubit.dart';
import 'package:cobalagi/features/profiles/cubit/profiles_cubit.dart';
import 'package:cobalagi/features/profiles/view/profile_avatar.dart';
import 'package:cobalagi/features/story/data/story_scene.dart';
import 'package:cobalagi/features/story/view/arrival_scenes.dart';
import 'package:cobalagi/features/story/view/ending_scenes.dart';
import 'package:cobalagi/features/story/view/intro_scene.dart';
import 'package:cobalagi/features/story/view/story_player.dart';
import 'package:cobalagi/learning/learner_state.dart';
import 'package:cobalagi/learning/story.dart';

/// Plays a scene of the Star fuel story, then goes back to the map. The map
/// opens each scene once per child, and its movie button opens the story
/// shelf (`StoryShelfScreen`), which plays any scene the child has reached
/// again ([replay]).
class StoryScreen extends StatelessWidget {
  const StoryScreen({
    super.key,
    required this.profileId,
    required this.scene,
    this.replay = false,
  });

  final int profileId;

  /// A key of [scenes].
  final String scene;

  /// Played again from the story shelf: it saves nothing and goes back to
  /// the shelf.
  final bool replay;

  /// The route names of the scenes the child has reached, in story order:
  /// the intro, then each planet's (the "new planet" scene that announced
  /// it, its arrival, and the ending its stars completed).
  ///
  /// A planet counts as reached once its arrival or demo played, and also
  /// when the child is past it on the map: the warm-up or a parent may have
  /// started them further on, so they never saw the planets before.
  static List<String> reached(LearnerState learner) {
    final seen = learner.tutorialsSeen;
    final current = arrivalScenes.keys.toList().indexOf(learner.currentConcept);
    final names = ['intro'];
    var sawEnding = false;
    var i = 0;
    for (final MapEntry(:key, :value) in arrivalScenes.entries) {
      if (seen.contains(Story.newPlanet(key))) names.add('new-planet-$key');
      if (i++ < current || seen.contains(value.id) || seen.contains(key)) {
        names.add('arrival-$key');
      }
      if (seen.contains(Story.fullTank(key))) {
        names.add(sawEnding ? 'full-again-$key' : 'ending-$key');
        sawEnding = true;
      }
    }
    return names;
  }

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
    final back = replay ? '/child/$profileId/stories' : '/child/$profileId';
    final story = scenes[scene];
    if (story == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go(back));
      return const Scaffold();
    }
    final profile = context.read<ProfilesCubit>().state.byId(profileId);
    return StoryPlayer(
      scene: story,
      emblem: profile == null ? null : avatarEmblem(profile.avatar),
      onDone: () {
        if (!replay) context.read<LearningCubit>().markTutorialSeen(story.id);
        context.go(back);
      },
    );
  }
}
