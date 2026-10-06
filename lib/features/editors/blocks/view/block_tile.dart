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
    BlockType.moveSteps => const Color(0xFFEF6C00),
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
  });

  final BlockType type;
  final double size;
  final bool highlighted;
  final bool hasIssue;

  @override
  Widget build(BuildContext context) => Semantics(
    label: type.label(AppLocalizations.of(context)),
    button: true,
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
        child: Icon(type.icon, color: Colors.white, size: size * 0.6),
      ),
    ),
  );
}
