import 'dart:async';
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Whether the iPhone's hinge is half open, from `UIHingeInteraction`
/// (iOS 27.1 and later, `AppDelegate.swift`); null elsewhere. Android reports
/// its fold to Flutter itself ([MediaQueryData.displayFeatures]).
Stream<bool>? hingeHalfOpen() {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return null;
  return const EventChannel(
    'cobalagi/hinge',
  ).receiveBroadcastStream().map((status) => status == 'partiallyOpen');
}

/// How far controls keep from the fold on either side: a child holding a
/// half-folded phone can't tap into the crease.
const foldClearance = 32.0;

/// The screen of a half-folded phone, split at its fold: the half that
/// stands up shows the world, the half that lies flat (the bottom half, or
/// the right half held like a book) holds the controls. Both stop
/// [foldClearance] short of the fold.
class FoldHalves {
  const FoldHalves({required this.view, required this.controls});

  /// The fold of a half-folded phone in [data], or null when the screen is
  /// flat, closed or has no fold. A hinge (two screens) always splits.
  static FoldHalves? of(BuildContext context) =>
      fromMediaQuery(MediaQuery.of(context));

  static FoldHalves? fromMediaQuery(MediaQueryData data) {
    final size = data.size;
    for (final feature in data.displayFeatures) {
      final splits =
          feature.type == DisplayFeatureType.hinge ||
          (feature.type == DisplayFeatureType.fold &&
              feature.state == DisplayFeatureState.postureHalfOpened);
      if (!splits) continue;
      final fold = feature.bounds;
      if (fold.top <= 0 && fold.bottom >= size.height) {
        // Upright like a book: the fold runs top to bottom.
        return FoldHalves(
          view: Rect.fromLTRB(0, 0, fold.left - foldClearance, size.height),
          controls: Rect.fromLTRB(
            fold.right + foldClearance,
            0,
            size.width,
            size.height,
          ),
        );
      }
      if (fold.left <= 0 && fold.right >= size.width) {
        // Like a laptop on a table: the fold runs side to side.
        return FoldHalves(
          view: Rect.fromLTRB(0, 0, size.width, fold.top - foldClearance),
          controls: Rect.fromLTRB(
            0,
            fold.bottom + foldClearance,
            size.width,
            size.height,
          ),
        );
      }
    }
    return null;
  }

  /// Where the world (or a screen's pictures) shows, in screen coordinates.
  final Rect view;

  /// Where everything the child taps goes, in screen coordinates.
  final Rect controls;

  /// A point in the controls' half, for pop-ups' `anchorPoint`: Flutter puts
  /// a dialog on the side of the fold the anchor is on.
  Offset get anchor => controls.center;

  /// Held like a book, the strip between the halves; null on a table. Flutter picks the status bar's
  /// style at the top centre of the screen, which is this strip, while the
  /// status bar (on the iPhone Duo, in its top right corner) sits over the
  /// controls' half: the strip takes that half's style.
  Rect? statusBarGap(Size screen) => view.bottom < screen.height
      ? null
      : Rect.fromLTRB(view.right, 0, controls.left, screen.height);
}

/// Gives the app below the fold the iPhone reports through [hingeHalfOpen],
/// as Android reports its own: a [DisplayFeatureType.fold] across the middle
/// of the screen's long side, which on an iPhone that folds like a book is
/// where it bends. Everything below reads folds the same way, from
/// [MediaQueryData.displayFeatures] ([FoldHalves.of]).
class HingeFold extends StatefulWidget {
  const HingeFold({super.key, this.halfOpen, required this.child});

  /// Null does nothing (tests, and every platform but iOS).
  final Stream<bool>? halfOpen;
  final Widget child;

  @override
  State<HingeFold> createState() => _HingeFoldState();
}

class _HingeFoldState extends State<HingeFold> {
  StreamSubscription<bool>? _subscription;
  var _halfOpen = false;

  @override
  void initState() {
    super.initState();
    _subscription = widget.halfOpen?.listen(
      (halfOpen) => setState(() => _halfOpen = halfOpen),
      // An iPhone without a hinge, or an older iOS: no fold.
      onError: (Object _) {},
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    if (!_halfOpen ||
        data.displayFeatures.any((f) => f.type != DisplayFeatureType.cutout)) {
      return widget.child;
    }
    final size = data.size;
    final fold = size.width > size.height
        ? Rect.fromLTWH(size.width / 2, 0, 0, size.height)
        : Rect.fromLTWH(0, size.height / 2, size.width, 0);
    return MediaQuery(
      data: data.copyWith(
        displayFeatures: [
          ...data.displayFeatures,
          DisplayFeature(
            bounds: fold,
            type: DisplayFeatureType.fold,
            state: DisplayFeatureState.postureHalfOpened,
          ),
        ],
      ),
      child: widget.child,
    );
  }
}

/// Lays a screen out across a half-folded phone ([FoldHalves]): [view] in
/// the half that stands up and [controls] in the half that lies flat, so
/// nothing the child taps sits on the fold. Each half gets the screen's
/// safe-area padding only on the screen edges it touches.
class FoldSplit extends StatelessWidget {
  const FoldSplit({
    super.key,
    required this.halves,
    required this.view,
    required this.controls,
  });

  final FoldHalves halves;
  final Widget view;
  final Widget controls;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Stack(
      alignment: Alignment.topLeft,
      children: [
        _half(context, halves.view, size, view),
        _half(
          context,
          halves.controls,
          size,
          controls,
          statusBarGap: halves.statusBarGap(size),
        ),
      ],
    );
  }
}

/// A whole screen in the flat half of a half-folded phone: screens that
/// don't split ([FoldSplit]) sit there, the size of a closed phone, and the
/// half that stands up shows [view], a picture to look at.
class FoldHalf extends StatefulWidget {
  const FoldHalf({
    super.key,
    this.view,
    this.behindFold = false,
    this.viewTakesTaps = false,
    required this.child,
  });

  /// Shown behind the fold while half folded; takes no taps. The screen's
  /// app bar (back and title) moves above it ([FoldBarSlot]), as the play
  /// screen's top bar sits above the world.
  final Widget? view;

  /// Puts [child] in the half that stands up instead, for a screen that is
  /// only to look at (the splash).
  final bool behindFold;

  /// Whether [view] is part of the screen the child uses (one of its
  /// sections, clear of the fold), not just a picture.
  final bool viewTakesTaps;
  final Widget child;

  @override
  State<FoldHalf> createState() => _FoldHalfState();
}

class _FoldHalfState extends State<FoldHalf> {
  Object? _barOwner;
  Widget? _bar;

  // App bars hand over while they build (or go): applied after the frame.
  void _later(VoidCallback change) {
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        if (mounted) setState(change);
      })
      ..scheduleFrame();
  }

  void _showBar(Object owner, Widget bar) => _later(() {
    _barOwner = owner;
    _bar = bar;
  });

  void _hideBar(Object owner) => _later(() {
    if (_barOwner != owner) return;
    _barOwner = null;
    _bar = null;
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // The same tree flat or folded, so folding keeps the screen's state.
    final halves = FoldHalves.of(context);
    final view = widget.view;
    final hasView = halves != null && view != null && !widget.behindFold;
    final bar = hasView ? _bar : null;
    final rect =
        (widget.behindFold ? halves?.view : halves?.controls) ??
        Offset.zero & size;
    return FoldBarSlot._(
      state: hasView ? this : null,
      child: Stack(
        alignment: Alignment.topLeft,
        children: [
          _half(
            context,
            rect,
            size,
            widget.child,
            statusBarGap: widget.behindFold ? null : halves?.statusBarGap(size),
          ),
          if (hasView)
            _half(
              context,
              halves.view,
              size,
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ?bar,
                      if (bar != null) const SizedBox(height: 12),
                      Expanded(
                        child: widget.viewTakesTaps
                            ? view
                            : IgnorePointer(child: ExcludeFocus(child: view)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Where a screen's app bar shows on a half-folded phone: above the picture
/// behind the fold ([FoldHalf]). The app bar finds it with [maybeOf], hands
/// over what it shows with [show] and leaves its own place empty.
class FoldBarSlot extends InheritedWidget {
  const FoldBarSlot._({required _FoldHalfState? state, required super.child})
    : _state = state;

  final _FoldHalfState? _state;

  /// The slot above the picture, or null when not half folded.
  static FoldBarSlot? maybeOf(BuildContext context) {
    final slot = context.dependOnInheritedWidgetOfExactType<FoldBarSlot>();
    return slot?._state == null ? null : slot;
  }

  /// Shows [bar] above the picture, for [owner]; the app bar's own place
  /// takes no room meanwhile.
  void show(Object owner, Widget bar) => _state?._showBar(owner, bar);

  void hide(Object owner) => _state?._hideBar(owner);

  @override
  bool updateShouldNotify(FoldBarSlot old) => old._state != _state;
}

Widget _half(
  BuildContext context,
  Rect rect,
  Size size,
  Widget child, {
  Rect? statusBarGap,
}) {
  final data = MediaQuery.of(context);
  EdgeInsets keep(EdgeInsets insets) => EdgeInsets.fromLTRB(
    rect.left <= 0 ? insets.left : 0,
    rect.top <= 0 ? insets.top : 0,
    rect.right >= size.width ? insets.right : 0,
    rect.bottom >= size.height ? insets.bottom : 0,
  );
  return Positioned.fromRect(
    rect: rect,
    child: MediaQuery(
      data: data.copyWith(
        size: rect.size,
        padding: keep(data.padding),
        viewPadding: keep(data.viewPadding),
        // The keyboard rises over the flat half only.
        viewInsets: rect.bottom >= size.height
            ? data.viewInsets
            : EdgeInsets.zero,
        // Within one half there is no fold.
        displayFeatures: const [],
      ),
      // Always in the tree, so folding keeps the screen's state.
      child: _StatusBarAcrossFold(
        gap: statusBarGap?.shift(-rect.topLeft),
        child: child,
      ),
    ),
  );
}

/// Gives [gap] (in this widget's coordinates) the status bar style that
/// [child] sets at its own top centre, read as [child] paints.
class _StatusBarAcrossFold extends SingleChildRenderObjectWidget {
  const _StatusBarAcrossFold({required this.gap, super.child});

  final Rect? gap;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderStatusBarAcrossFold(gap);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderStatusBarAcrossFold renderObject,
  ) => renderObject.gap = gap;
}

class _RenderStatusBarAcrossFold extends RenderProxyBox {
  _RenderStatusBarAcrossFold(this._gap);

  Rect? _gap;
  set gap(Rect? value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsCompositingBitsUpdate();
    markNeedsPaint();
  }

  final _content = LayerHandle<ContainerLayer>();

  @override
  bool get alwaysNeedsCompositing => _gap != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    final gap = _gap;
    if (gap == null || child == null) {
      _content.layer = null;
      super.paint(context, offset);
      return;
    }
    final content = _content.layer ??= ContainerLayer();
    context.pushLayer(content, super.paint, offset);
    final style = content.find<SystemUiOverlayStyle>(
      offset + Offset(size.width / 2, 0),
    );
    if (style != null) {
      context.addLayer(
        AnnotatedRegionLayer<SystemUiOverlayStyle>(
          style,
          offset: offset + gap.topLeft,
          size: gap.size,
        ),
      );
    }
  }

  @override
  void dispose() {
    _content.layer = null;
    super.dispose();
  }
}
