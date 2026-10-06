import 'package:flutter/material.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../data/icon_block.dart';

extension IconBlockTypeStyle on IconBlockType {
  IconData get icon => switch (this) {
    IconBlockType.forward => Icons.arrow_upward_rounded,
    IconBlockType.turnLeft => Icons.turn_left_rounded,
    IconBlockType.turnRight => Icons.turn_right_rounded,
    IconBlockType.repeat => Icons.repeat_rounded,
    IconBlockType.star => Icons.star_rounded,
  };

  Color get color => switch (this) {
    IconBlockType.forward => const Color(0xFF43A047),
    IconBlockType.turnLeft => const Color(0xFF1E88E5),
    IconBlockType.turnRight => const Color(0xFFFB8C00),
    IconBlockType.repeat => const Color(0xFF8E24AA),
    IconBlockType.star => const Color(0xFFD81B60),
  };

  /// Spoken by screen readers; pre-readers rely on the icon alone.
  String label(AppLocalizations l10n) => switch (this) {
    IconBlockType.forward => l10n.blockForward,
    IconBlockType.turnLeft => l10n.blockTurnLeft,
    IconBlockType.turnRight => l10n.blockTurnRight,
    IconBlockType.repeat => l10n.blockRepeat,
    IconBlockType.star => l10n.blockStar,
  };
}

/// A square icon block. [highlighted] marks the block that is running;
/// [hasIssue] marks a block the child needs to fix.
class IconBlockTile extends StatelessWidget {
  const IconBlockTile({
    super.key,
    required this.type,
    required this.size,
    this.highlighted = false,
    this.hasIssue = false,
  });

  final IconBlockType type;
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
          color: type.color,
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
