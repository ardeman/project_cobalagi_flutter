import 'package:flutter/material.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../learning/warm_up/warm_up.dart';

/// Display name of a skill-map concept; unknown ids show as-is.
String conceptName(AppLocalizations l10n, String id) => switch (id) {
  'directions' => l10n.conceptDirections,
  'sequencing' => l10n.conceptSequencing,
  'loops' => l10n.conceptLoops,
  'functions' => l10n.conceptFunctions,
  'conditions' => l10n.conceptConditions,
  'variables' => l10n.conceptVariables,
  'debugging' => l10n.conceptDebugging,
  'until' => l10n.conceptUntil,
  warmUpIsland => l10n.conceptWarmUp,
  _ => id,
};

IconData conceptIcon(String id) => switch (id) {
  'directions' => Icons.explore_rounded,
  'sequencing' => Icons.route_rounded,
  'loops' => Icons.repeat_rounded,
  'functions' => Icons.star_rounded,
  'conditions' => Icons.visibility_rounded,
  'variables' => Icons.inventory_2_rounded,
  'debugging' => Icons.build_rounded,
  'until' => Icons.sports_score_rounded,
  warmUpIsland => Icons.sports_esports_rounded,
  _ => Icons.terrain_rounded,
};

Color conceptColor(String id) => switch (id) {
  'directions' => const Color(0xFF29B6F6),
  'sequencing' => const Color(0xFF66BB6A),
  'loops' => const Color(0xFFAB47BC),
  'functions' => const Color(0xFFEC407A),
  'conditions' => const Color(0xFF00897B),
  'variables' => const Color(0xFFEF6C00),
  'debugging' => const Color(0xFF5C6BC0),
  'until' => const Color(0xFF7CB342),
  warmUpIsland => const Color(0xFFFF7A59),
  _ => const Color(0xFF8D6E63),
};
