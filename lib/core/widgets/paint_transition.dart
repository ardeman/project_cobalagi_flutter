import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Moves or scales [child] with [animation] when painting only.
///
/// `AnimatedBuilder` and `ScaleTransition` rebuild on every frame, and a
/// rebuild inside a `LayoutBuilder` (every screen sits in a
/// `WindowClassBuilder`) lays out and repaints the whole screen around it,
/// glass panels and all. This never rebuilds or lays out: each frame only
/// repaints [child]'s own small layer. Use it for animations that loop.
class PaintTransition extends SingleChildRenderObjectWidget {
  const PaintTransition({
    super.key,
    required this.animation,
    required this.transform,
    super.child,
  });

  final Animation<double> animation;

  /// The transform for the animation's value, in the child's own space.
  final Matrix4 Function(double value, Size size) transform;

  /// Moves the child up and down by [value] times [dy].
  static Matrix4 Function(double, Size) translateY(double dy) =>
      (value, _) => Matrix4.translationValues(0, value * dy, 0);

  /// Scales the child about its centre from 1 to [to] as [value] goes 0 → 1.
  static Matrix4 Function(double, Size) scaleUpTo(double to) => (value, size) {
    final scale = 1 + (to - 1) * value;
    final centre = size.center(Offset.zero);
    return Matrix4.translationValues(centre.dx, centre.dy, 0)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-centre.dx, -centre.dy, 0, 1);
  };

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderPaintTransition(animation, transform);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderPaintTransition renderObject,
  ) {
    renderObject
      ..animation = animation
      ..transform = transform;
  }
}

/// The render object behind [PaintTransition].
class RenderPaintTransition extends RenderProxyBox {
  RenderPaintTransition(this._animation, this.transform);

  Animation<double> _animation;
  Matrix4 Function(double value, Size size) transform;

  set animation(Animation<double> value) {
    if (value == _animation) return;
    if (attached) _animation.removeListener(markNeedsPaint);
    _animation = value;
    if (attached) _animation.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  Matrix4 get _matrix => transform(_animation.value, size);

  // Each frame repaints this layer alone.
  @override
  bool get isRepaintBoundary => true;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _animation.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _animation.removeListener(markNeedsPaint);
    super.detach();
  }

  /// The transform's layer, kept between frames. (As a repaint boundary,
  /// this render object's own [layer] is its offset layer.)
  final _transformLayer = LayerHandle<TransformLayer>();

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      _transformLayer.layer = null;
      return;
    }
    _transformLayer.layer = context.pushTransform(
      needsCompositing,
      offset,
      _matrix,
      super.paint,
      oldLayer: _transformLayer.layer,
    );
  }

  @override
  void dispose() {
    _transformLayer.layer = null;
    super.dispose();
  }

  // Taps follow the child to where it is drawn, as with Transform, even
  // outside where it was laid out.
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) =>
      hitTestChildren(result, position: position);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      result.addWithPaintTransform(
        transform: _matrix,
        position: position,
        hitTest: (result, position) =>
            super.hitTestChildren(result, position: position),
      );

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) =>
      transform.multiply(_matrix);
}
