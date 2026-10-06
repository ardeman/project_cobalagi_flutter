import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'glass_bar.dart';

/// A scrolling page between an optional [top] and [bottom] bar. The content
/// runs under both bars, and each bar is frosted only while content is under
/// it. [builder] gets the insets the bars take, to pad its scroll view by.
class GlassFrame extends StatefulWidget {
  const GlassFrame({super.key, this.top, this.bottom, required this.builder});

  final Widget? top;
  final Widget? bottom;
  final Widget Function(BuildContext context, EdgeInsets insets) builder;

  @override
  State<GlassFrame> createState() => _GlassFrameState();
}

class _GlassFrameState extends State<GlassFrame> {
  var _topHeight = 0.0;
  var _bottomHeight = 0.0;
  var _underTop = false;
  var _underBottom = false;

  bool _onMetrics(ScrollMetrics metrics) {
    if (axisDirectionToAxis(metrics.axisDirection) != Axis.vertical) {
      return false;
    }
    // Rounding keeps a list that fits exactly from flickering.
    final top = metrics.extentBefore > 0.5;
    final bottom = metrics.extentAfter > 0.5;
    if (top != _underTop || bottom != _underBottom) {
      setState(() {
        _underTop = top;
        _underBottom = bottom;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => n.depth == 0 && _onMetrics(n.metrics),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => n.depth == 0 && _onMetrics(n.metrics),
        child: Stack(
          children: [
            Positioned.fill(
              // The bars count as padding, so whatever scrolls into view
              // (a new block, a caret) stops clear of them.
              child: Builder(
                builder: (context) {
                  final media = MediaQuery.of(context);
                  return MediaQuery(
                    data: media.copyWith(
                      padding: media.padding.copyWith(
                        top: max(media.padding.top, _topHeight),
                        bottom: max(media.padding.bottom, _bottomHeight),
                      ),
                    ),
                    child: widget.builder(
                      context,
                      EdgeInsets.only(top: _topHeight, bottom: _bottomHeight),
                    ),
                  );
                },
              ),
            ),
            if (widget.top case final top?)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _Measured(
                  onHeight: (h) => setState(() => _topHeight = h),
                  child: GlassBar(
                    under: _underTop,
                    edge: GlassEdge.top,
                    child: top,
                  ),
                ),
              ),
            if (widget.bottom case final bottom?)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _Measured(
                  onHeight: (h) => setState(() => _bottomHeight = h),
                  child: GlassBar(
                    under: _underBottom,
                    edge: GlassEdge.bottom,
                    child: bottom,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Reports its child's height after layout, whenever it changes.
class _Measured extends SingleChildRenderObjectWidget {
  const _Measured({required this.onHeight, super.child});

  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasured(onHeight);

  @override
  void updateRenderObject(BuildContext context, _RenderMeasured renderObject) {
    renderObject.onHeight = onHeight;
  }
}

class _RenderMeasured extends RenderProxyBox {
  _RenderMeasured(this.onHeight);

  ValueChanged<double> onHeight;
  double? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final height = size.height;
    if (height == _reported) return;
    _reported = height;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) onHeight(height);
    });
  }
}
