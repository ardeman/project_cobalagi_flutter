import 'package:flutter/widgets.dart';

/// Material 3 window size classes, based on the space a layout actually gets.
enum WindowClass {
  compact,
  medium,
  expanded;

  static WindowClass fromWidth(double width) => width < 600
      ? compact
      : width < 840
      ? medium
      : expanded;
}

class WindowClassBuilder extends StatelessWidget {
  const WindowClassBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, WindowClass windowClass) builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) =>
        builder(context, WindowClass.fromWidth(constraints.maxWidth)),
  );
}
