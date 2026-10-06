import 'package:flutter/material.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../learning/learner_state.dart';
import '../../learning/data/curriculum_repository.dart';
import '../../learning/data/parent_placement.dart';
import '../../learning/view/concepts.dart';
import '../../profiles/data/profile.dart';
import 'package:cobalagi/core/widgets/glass_popups.dart';

/// Lets a parent pick a child's starting island or replay the warm-up game.
Future<void> showPlacementDialog(
  BuildContext context, {
  required Profile profile,
  required ParentPlacement placement,
}) async {
  final learner = await placement.load(profile.id);
  if (!context.mounted) return;
  await showGlassDialog<void>(
    context: context,
    builder: (_) => _PlacementDialog(
      profile: profile,
      learner: learner,
      placement: placement,
    ),
  );
}

/// One line describing where a child is now on the skill map.
String placementSummary(
  AppLocalizations l10n,
  Curriculum curriculum,
  LearnerState? learner,
) {
  final placement = learner?.placement;
  if (learner == null || placement == null) return l10n.placementNotYet;
  final line = l10n.placementNowAt(conceptName(l10n, learner.currentConcept));
  return placement.byParent ? '$line (${l10n.setByParent})' : line;
}

class _PlacementDialog extends StatefulWidget {
  const _PlacementDialog({
    required this.profile,
    required this.learner,
    required this.placement,
  });

  final Profile profile;
  final LearnerState learner;
  final ParentPlacement placement;

  @override
  State<_PlacementDialog> createState() => _PlacementDialogState();
}

class _PlacementDialogState extends State<_PlacementDialog> {
  late String _start = widget.learner.currentConcept;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final concepts = widget.placement.curriculum.engine.graph.concepts;
    return AlertDialog(
      title: Text(widget.profile.nickname),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.startingIsland,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            RadioGroup<String>(
              groupValue: _start,
              onChanged: (value) => setState(() => _start = value!),
              child: Column(
                children: [
                  for (final concept in concepts)
                    RadioListTile<String>(
                      value: concept.id,
                      title: Text(conceptName(l10n, concept.id)),
                      secondary: Icon(
                        conceptIcon(concept.id),
                        color: conceptColor(concept.id),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                await widget.placement.retakePretest(widget.profile.id);
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.sports_esports_rounded),
              label: Text(l10n.retakePretest),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () async {
            await widget.placement.setStart(widget.profile.id, _start);
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
