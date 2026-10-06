import 'package:flutter/material.dart';

import '../../../app/l10n/app_localizations.dart';

/// Display name of a skill-map concept; unknown ids show as-is.
String conceptName(AppLocalizations l10n, String id) => switch (id) {
  'directions' => l10n.conceptDirections,
  'sequencing' => l10n.conceptSequencing,
  'loops' => l10n.conceptLoops,
  'functions' => l10n.conceptFunctions,
  'conditions' => l10n.conceptConditions,
  'variables' => l10n.conceptVariables,
  _ => id,
};

IconData conceptIcon(String id) => switch (id) {
  'directions' => Icons.explore_rounded,
  'sequencing' => Icons.route_rounded,
  'loops' => Icons.repeat_rounded,
  'functions' => Icons.star_rounded,
  'conditions' => Icons.visibility_rounded,
  'variables' => Icons.inventory_2_rounded,
  _ => Icons.terrain_rounded,
};

Color conceptColor(String id) => switch (id) {
  'directions' => const Color(0xFF29B6F6),
  'sequencing' => const Color(0xFF66BB6A),
  'loops' => const Color(0xFFAB47BC),
  'functions' => const Color(0xFFEC407A),
  'conditions' => const Color(0xFF00897B),
  'variables' => const Color(0xFFEF6C00),
  _ => const Color(0xFF8D6E63),
};
