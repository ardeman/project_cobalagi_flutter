import 'package:flutter/material.dart';

import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/widgets/focus_tap.dart';

/// One dot per map on a level with several (`Level.moreBoards`), so a child
/// sees there is more than one: the one in view is big, maps a run has
/// solved carry a green ✓, and the one it stopped on is orange. While
/// editing, tapping a dot shows that map ([onPick]); null while running.
class BoardDots extends StatelessWidget {
  const BoardDots({
    super.key,
    required this.count,
    required this.shown,
    required this.solved,
    this.stopped = false,
    this.onPick,
  });

  final int count;

  /// The map in view.
  final int shown;

  /// How many maps, from the first, the last run solved.
  final int solved;

  /// Whether the last run stopped on the map in view.
  final bool stopped;
  final ValueChanged<int>? onPick;

  static const _solvedColor = Color(0xFF43A047);
  static const _stoppedColor = Color(0xFFFB8C00);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          Semantics(
            button: true,
            selected: i == shown,
            label: l10n.boardNumber(i + 1),
            child: Tooltip(
              message: l10n.boardNumber(i + 1),
              child: FocusTap(
                onTap: onPick == null ? null : () => onPick!(i),
                // 64dp to tap, however small the dot.
                child: SizedBox.square(
                  dimension: 64,
                  child: Center(child: _dot(i)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _dot(int i) {
    final isShown = i == shown;
    final color = i < solved
        ? _solvedColor
        : isShown && stopped
        ? _stoppedColor
        : Colors.white.withValues(alpha: isShown ? 0.95 : 0.6);
    final size = isShown ? 34.0 : 24.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: const Color(0xFF263238), width: 2.5),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
      ),
      child: i < solved
          ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
          : null,
    );
  }
}
