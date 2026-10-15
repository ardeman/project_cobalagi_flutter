import 'package:flutter/material.dart';

import 'package:cobalagi/core/gamepad/pad_input.dart';

/// A small round key cap with a controller button's label, like the button
/// on the Steam Deck, pinned to the control that button presses.
class PadBadge extends StatelessWidget {
  const PadBadge({super.key, required this.button, this.size = 28});

  final PadButton button;
  final double size;

  @override
  Widget build(BuildContext context) {
    final wide = button.label.length > 1 && button.label.codeUnitAt(0) < 128;
    return ExcludeSemantics(
      child: Container(
        height: size,
        constraints: BoxConstraints(minWidth: size),
        padding: EdgeInsets.symmetric(horizontal: wide ? size * 0.2 : 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1E2448),
          borderRadius: BorderRadius.circular(size / 2),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black38)],
        ),
        // Fonts lack the menu and view signs: draw those.
        child: switch (button) {
          PadButton.menu => Icon(
            Icons.menu_rounded,
            size: size * 0.62,
            color: Colors.white,
          ),
          PadButton.view => Icon(
            Icons.filter_none_rounded,
            size: size * 0.5,
            color: Colors.white,
          ),
          _ => Text(
            button.label,
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * (wide ? 0.42 : 0.52),
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        },
      ),
    );
  }
}
