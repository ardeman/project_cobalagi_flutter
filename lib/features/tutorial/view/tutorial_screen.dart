import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../learning/cubit/learning_cubit.dart';
import 'tutorial_view.dart';

/// Watches an island's demo again, from the island's "Watch how" button.
class TutorialScreen extends StatelessWidget {
  const TutorialScreen({
    super.key,
    required this.profileId,
    required this.conceptId,
  });

  final int profileId;
  final String conceptId;

  @override
  Widget build(BuildContext context) {
    final learning = context.watch<LearningCubit>();
    final tutorial = learning.curriculum.tutorials[conceptId];
    final island = '/child/$profileId/island/$conceptId';
    if (tutorial == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go(island));
      return const Scaffold();
    }
    return TutorialView(
      tutorial: tutorial,
      doneLabel: AppLocalizations.of(context).backToIsland,
      onDone: () {
        learning.markTutorialSeen(conceptId);
        context.go(island);
      },
    );
  }
}
