import 'dart:math';

import 'package:flutter/material.dart';

/// A scroll view that fills its space, so a drag anywhere on the screen
/// scrolls it (also beside narrow content on a wide tablet), with its
/// [child] centred across, at most [maxWidth] wide, and up and down too
/// while it fits ([centerVertically]).
class CenteredScrollView extends StatelessWidget {
  const CenteredScrollView({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.maxWidth = double.infinity,
    this.centerVertically = true,
    this.controller,
  });

  final Widget child;
  final EdgeInsets padding;
  final double maxWidth;
  final bool centerVertically;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => SingleChildScrollView(
      controller: controller,
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: centerVertically
              ? max(0.0, box.maxHeight - padding.vertical)
              : 0,
        ),
        child: Align(
          alignment: centerVertically ? Alignment.center : Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        ),
      ),
    ),
  );
}
