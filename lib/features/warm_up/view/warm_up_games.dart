import 'package:flutter/material.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../learning/warm_up/warm_up.dart';

/// A Warm-up island game's name, picture and colour.
extension WarmUpGameLook on WarmUpGame {
  String label(AppLocalizations l10n) => switch (this) {
    WarmUpGame.counting => l10n.warmUpCounting,
    WarmUpGame.colors => l10n.warmUpColors,
    WarmUpGame.shapes => l10n.warmUpShapes,
    WarmUpGame.patterns => l10n.warmUpPatterns,
    WarmUpGame.sides => l10n.warmUpSides,
    WarmUpGame.steps => l10n.warmUpSteps,
  };

  IconData get icon => switch (this) {
    WarmUpGame.counting => Icons.looks_3_rounded,
    WarmUpGame.colors => Icons.palette_rounded,
    WarmUpGame.shapes => Icons.category_rounded,
    WarmUpGame.patterns => Icons.auto_awesome_motion_rounded,
    WarmUpGame.sides => Icons.swap_horiz_rounded,
    WarmUpGame.steps => Icons.directions_walk_rounded,
  };

  Color get color => switch (this) {
    WarmUpGame.counting => const Color(0xFF29B6F6),
    WarmUpGame.colors => const Color(0xFFEC407A),
    WarmUpGame.shapes => const Color(0xFF66BB6A),
    WarmUpGame.patterns => const Color(0xFFAB47BC),
    WarmUpGame.sides => const Color(0xFFFFA726),
    WarmUpGame.steps => const Color(0xFF26A69A),
  };
}
