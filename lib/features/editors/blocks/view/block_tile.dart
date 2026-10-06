import 'package:flutter/material.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../data/block.dart';

extension BlockTypeStyle on BlockType {
  IconData get icon => switch (this) {
    BlockType.forward => Icons.arrow_upward_rounded,
    BlockType.turnLeft => Icons.turn_left_rounded,
    BlockType.turnRight => Icons.turn_right_rounded,
    BlockType.repeat => Icons.repeat_rounded,
    BlockType.setSteps => Icons.inventory_2_rounded,
    BlockType.moveSteps => Icons.forward_rounded,
    BlockType.star => Icons.star_rounded,
    BlockType.ifPathClear => Icons.visibility_rounded,
    BlockType.untilGoal => Icons.sports_score_rounded,
  };

  Color get color => switch (this) {
    BlockType.forward => const Color(0xFF43A047),
    BlockType.turnLeft => const Color(0xFF1E88E5),
    BlockType.turnRight => const Color(0xFFFB8C00),
    BlockType.repeat => const Color(0xFF8E24AA),
    BlockType.setSteps => const Color(0xFFFFB300),
    // The Step Box's gold, darker than "save steps", and far from the
    // orange of turning right.
    BlockType.moveSteps => const Color(0xFFC58A00),
    BlockType.star => const Color(0xFFD81B60),
    BlockType.ifPathClear => const Color(0xFF00897B),
    BlockType.untilGoal => const Color(0xFF7CB342),
  };

  /// Spoken by screen readers; pre-readers rely on the icon alone.
  String label(AppLocalizations l10n) => switch (this) {
    BlockType.forward => l10n.blockForward,
    BlockType.turnLeft => l10n.blockTurnLeft,
    BlockType.turnRight => l10n.blockTurnRight,
    BlockType.repeat => l10n.blockRepeat,
    BlockType.setSteps => l10n.blockSetSteps,
    BlockType.moveSteps => l10n.blockMoveSteps,
    BlockType.star => l10n.blockStar,
    BlockType.ifPathClear => l10n.blockIfPathClear,
    BlockType.untilGoal => l10n.blockUntilGoal,
  };
}

/// A block: a square picture. [highlighted] marks the block that is running;
/// [hasIssue] marks a block the child needs to fix.
class BlockTile extends StatelessWidget {
  const BlockTile({
    super.key,
    required this.type,
    required this.size,
    this.highlighted = false,
    this.hasIssue = false,
    this.stepValue,
  });

  final BlockType type;
  final double size;
  final bool highlighted;
  final bool hasIssue;

  /// On a placed "use steps" block: the Step Box number it will use, or
  /// "?" before one is saved. Shown in a bubble in the Step Box's colour.
  final String? stepValue;

  /// "Use steps" shows the Step Box with an arrow, so it is clearly the
  /// block that reads the saved number.
  Widget _picture() {
    if (type != BlockType.moveSteps) {
      return Icon(type.icon, color: Colors.white, size: size * 0.6);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inventory_2_rounded, color: Colors.white, size: size * 0.34),
        Icon(
          Icons.arrow_forward_rounded,
          color: Colors.white,
          size: size * 0.4,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tile = _tile();
    final value = stepValue;
    return Semantics(
      label: value == null
          ? type.label(AppLocalizations.of(context))
          : '${type.label(AppLocalizations.of(context))}: $value',
      button: true,
      child: value == null
          ? tile
          : Stack(
              clipBehavior: Clip.none,
              children: [
                tile,
                Positioned(
                  top: -size * 0.16,
                  right: -size * 0.16,
                  child: Container(
                    width: size * 0.46,
                    height: size * 0.46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: BlockType.setSteps.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: size * 0.28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _tile() => ExcludeSemantics(
    child: AnimatedScale(
      scale: highlighted ? 1.12 : 1,
      duration: const Duration(milliseconds: 150),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(type.color, Colors.white, 0.18)!,
              type.color,
              Color.lerp(type.color, Colors.black, 0.08)!,
            ],
          ),
          borderRadius: BorderRadius.circular(size * 0.24),
          border: Border.all(
            width: size * 0.07,
            color: hasIssue
                ? const Color(0xFFE53935)
                : highlighted
                ? const Color(0xFFFFD54F)
                : Colors.white.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              offset: Offset(0, size * 0.06),
              blurRadius: size * 0.08,
            ),
          ],
        ),
        child: _picture(),
      ),
    ),
  );
}
