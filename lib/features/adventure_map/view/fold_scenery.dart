import 'package:flutter/material.dart';

import 'package:cobalagi/core/character/koba_head.dart';
import 'package:cobalagi/features/adventure_map/view/space_map.dart';
import 'package:cobalagi/features/learning/cubit/learning_cubit.dart';
import 'package:cobalagi/features/profiles/cubit/profiles_cubit.dart';
import 'package:cobalagi/features/profiles/view/profile_avatar.dart';
import 'package:cobalagi/learning/story.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the half of a half-folded phone that stands up shows on screens
/// that keep everything in the flat half (`FoldHalf`): a window onto space
/// with [concept]'s planet in it and Koba's ship landed on it, as on the
/// map, or Koba looking around when there is no planet.
class FoldScenery extends StatelessWidget {
  const FoldScenery({super.key, this.concept, this.profileId});

  final String? concept;

  /// Whose ship lands on the planet (its tank and emblem).
  final int? profileId;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: Stack(
      fit: StackFit.expand,
      children: [
        const SpaceSky(),
        LayoutBuilder(
          builder: (context, box) {
            final side =
                box.biggest.shortestSide * (this.concept == null ? 0.7 : 0.95);
            final concept = this.concept;
            return Center(
              child: SizedBox.square(
                dimension: side,
                child: concept == null
                    ? KobaHead.follow(size: side * 0.8)
                    : _Landed(concept: concept, profileId: profileId),
              ),
            );
          },
        ),
      ],
    ),
  );
}

/// [concept]'s planet with the ship as the map shows it to this child.
class _Landed extends StatelessWidget {
  const _Landed({required this.concept, required this.profileId});

  final String concept;
  final int? profileId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<LearningCubit>();
    final learner = cubit.state.learner;
    final profile = profileId == null
        ? null
        : context.watch<ProfilesCubit>().state.byId(profileId!);
    final graph = cubit.engine.graph;
    return LandedPlanet(
      concept: concept,
      fill: learner == null
          ? 0
          : Story.tankFill(
              finished: graph.indexOf(learner.currentConcept),
              planets: graph.concepts.length,
            ),
      emblem: profile == null ? null : avatarEmblem(profile.avatar),
    );
  }
}
