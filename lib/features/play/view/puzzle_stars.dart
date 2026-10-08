import 'package:flutter/material.dart';

import '../../../app/l10n/app_localizations.dart';

/// A puzzle's stars: three, of which [stars] are filled gold.
class PuzzleStars extends StatelessWidget {
  const PuzzleStars({
    super.key,
    required this.stars,
    required this.size,
    this.emptyColor,
  });

  final int stars;
  final double size;

  /// The outline of an unearned star; a soft gold by default.
  final Color? emptyColor;

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).starsEarned(stars),
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Icon(
            i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i < stars
                ? const Color(0xFFFFC83D)
                : (emptyColor ?? const Color(0x99FFC83D)),
          ),
      ],
    ),
  );
}
