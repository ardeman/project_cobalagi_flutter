import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cobalagi/core/gamepad/gamepad_scope.dart';
import 'package:cobalagi/core/gamepad/gamepad_shortcut.dart';
import 'package:cobalagi/core/gamepad/pad_input.dart';
import 'package:cobalagi/core/widgets/focus_tap.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../engine/program/instruction.dart';
import 'package:cobalagi/core/widgets/glass_surface.dart';
import '../../../../engine/program/validation.dart';
import '../cubit/blocks_cubit.dart';
import '../data/block.dart';
import 'block_tile.dart';

/// Block editor: drag (touch or mouse) or tap palette blocks to build a row.
/// Drag a placed block to reorder it, into a repeat block to repeat it, or
/// back onto the palette to remove it.
class BlockEditor extends StatefulWidget {
  const BlockEditor({
    super.key,
    required this.palette,
    required this.blockSize,
    this.activeBlockId,
    this.lookHere = const {},
    this.fromHint = false,
    this.issueBlockIds = const {},
    this.enabled = true,
    this.showHowTo = false,
    this.showTips = true,
    this.pointAt,
    this.fitContent = false,
    this.paletteKey,
    this.programKey,
    this.blockKeys = const {},
  });

  /// Mark the palette, the program and each palette block, e.g. for a
  /// guided tour.
  final Key? paletteKey;
  final Key? programKey;
  final Map<BlockType, Key> blockKeys;

  /// Shows a hand dragging the first palette block into the program, for a
  /// child who hasn't played yet. Hidden once the program has a block.
  final bool showHowTo;

  /// A palette block a "Watch me!" demo is about to tap: it grows a little
  /// and a hand points at it.
  final BlockType? pointAt;

  /// Shows written tips, such as how the Step Box works. Phones leave them
  /// out to keep room for the blocks; the goal voice explains the same.
  final bool showTips;

  /// Phones place the editor in a page that scrolls with the world: it takes
  /// the height of its blocks instead of filling the space it is given.
  final bool fitContent;

  final Set<InstructionKind> palette;
  final double blockSize;
  final String? activeBlockId;

  /// Blocks wearing a "look here" ring: the one that walked into a rock on
  /// the last run, or, [fromHint], the ones the hint says to change.
  final Set<String> lookHere;
  final bool fromHint;
  final Set<String> issueBlockIds;
  final bool enabled;

  @override
  State<BlockEditor> createState() => _BlockEditorState();
}

class _BlockEditorState extends State<BlockEditor> {
  final _stack = GlobalKey();
  final _firstBlock = GlobalKey();
  final _program = GlobalKey();

  /// The picked block's focus: the highlight follows it when it moves, so
  /// a block carried with a controller keeps the highlight.
  final _pickedFocus = FocusNode();

  /// The program and star rows: A on a row picks it, then the highlight
  /// steps onto its first block.
  final _mainRowFocus = FocusNode();
  final _starRowFocus = FocusNode();
  GamepadScope? _pad;
  PadCaptureEntry? _carry;
  BlockProgram? _shown;

  /// The block [_pickedFocus] belongs to: the last one picked, kept after
  /// it is unpicked, so the highlight stays on it.
  String? _focusId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pad = GamepadScope.maybeOf(context);
    // Touching the screen while carrying puts the block down.
    if (!(_pad?.active ?? false)) {
      final cubit = context.read<BlocksCubit>();
      if (cubit.state.carrying) cubit.dropCarried();
    }
  }

  @override
  void dispose() {
    _endCarry();
    _pickedFocus.dispose();
    _mainRowFocus.dispose();
    _starRowFocus.dispose();
    super.dispose();
  }

  /// While a block is carried, the d-pad moves it, A puts it down and B
  /// puts it back.
  void _followCarry(BlocksCubit cubit) {
    final pad = _pad;
    if (pad == null) return;
    if (cubit.state.carrying && _carry == null) {
      _carry = PadCaptureEntry(
        context,
        cubit.cancelCarry,
        onMove: (direction) => cubit.carryBy(
          direction == PadDirection.left || direction == PadDirection.up
              ? -1
              : 1,
        ),
        onConfirm: cubit.dropCarried,
        // Letting go of R2 puts the block down.
        onRelease: (_) => cubit.dropCarried(),
        // The stick drags it freely instead, as a finger: a moved block is
        // put down first, else it goes back to where it was picked up.
        onFreeDrag: () {
          final moved = cubit.carryMoved;
          moved ? cubit.dropCarried() : cubit.cancelCarry();
          return moved;
        },
      );
      pad.captures.add(_carry!);
    } else if (!cubit.state.carrying) {
      _endCarry();
    }
    // A picked block moved to another row is a new widget: give it the
    // highlight back.
    final state = cubit.state;
    final picked =
        state.pickedBlock ??
        state.selectedContainer?.replaceAll(BlocksCubit.otherwiseRow, '');
    if (picked != null) _focusId = picked;
    if (pad.active &&
        !identical(state, _shown) &&
        (state.pickedBlock ?? state.selectedContainer) != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pickedFocus.context != null) {
          _pickedFocus.requestFocus();
        }
      });
    }
    _shown = state;
  }

  /// Picks a row, then moves focus inside it: with a controller, the
  /// highlight steps onto the row's first block.
  void _pickRow(BlocksCubit cubit, {required bool star}) {
    cubit.pickRow(star: star);
    // Harmless on touch, where focus shows nothing.
    final row = star ? _starRowFocus : _mainRowFocus;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // The first in reading order: the top line, then the left.
      final blocks = [
        for (final n in row.descendants)
          if (n.canRequestFocus && !n.skipTraversal && n.context != null) n,
      ];
      if (blocks.isEmpty) return;
      blocks.sort(
        (a, b) => (a.rect.top - b.rect.top).abs() > 8
            ? a.rect.top.compareTo(b.rect.top)
            : a.rect.left.compareTo(b.rect.left),
      );
      blocks.first.requestFocus();
    });
  }

  void _endCarry() {
    if (_carry != null) _pad?.captures.remove(_carry!);
    _carry = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.watch<BlocksCubit>();
    _followCarry(cubit);
    final blocks = cubit.state.main;
    final scheme = Theme.of(context).colorScheme;
    final types = [
      for (final type in BlockType.values)
        if (widget.palette.contains(type.kind)) type,
    ];
    final gap = widget.blockSize * 0.18;
    final showStar = widget.palette.contains(InstructionKind.call);
    final style = _BlockStyle(
      size: widget.blockSize,
      gap: gap,
      enabled: widget.enabled,
      activeBlockId: widget.activeBlockId,
      lookHere: widget.lookHere,
      fromHint: widget.fromHint,
      issueBlockIds: widget.issueBlockIds,
      stepValues: _stepValues(blocks),
      pickedFocus: _pickedFocus,
      focusId: _focusId,
    );

    // [starMax]: on a tablet the star row may take this much height at most
    // and scrolls inside it, so the main program always keeps room.
    List<Widget> topFor(double? starMax) => <Widget>[
      KeyedSubtree(
        key: widget.paletteKey,
        child: DragTarget<Block>(
          onAcceptWithDetails: (d) => cubit.remove(d.data.id),
          builder: (context, candidates, _) => GlassSurface(
            padding: EdgeInsets.all(gap),
            // Red while a block (dragged, or carried with a controller) would
            // be deleted here.
            tint: candidates.isEmpty && !cubit.state.overPalette
                ? null
                : scheme.errorContainer,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final type in types)
                  KeyedSubtree(
                    key: widget.blockKeys[type],
                    child: _PaletteBlock(
                      key: type == types.first ? _firstBlock : null,
                      type: type,
                      size: widget.blockSize,
                      // Replacing a picked block keeps the count, so the palette
                      // stays usable even at the block limit.
                      enabled:
                          widget.enabled &&
                          (!cubit.isFull || cubit.state.pickedBlock != null),
                      pointed: type == widget.pointAt,
                      onTap: () => cubit.tap(type),
                      onGrab: () => cubit.grabNew(type),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      SizedBox(height: gap),
      if (widget.showTips &&
          widget.palette.contains(InstructionKind.setSteps)) ...[
        Text(l10n.variableHint),
        SizedBox(height: gap),
      ],
      if (showStar) ...[
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: starMax ?? double.infinity),
          child: SingleChildScrollView(
            child: FocusTap(
              focusNode: _starRowFocus,
              onTap: () => _pickRow(cubit, star: true),
              child: _StarRow(
                blocks: cubit.state.star,
                style: style,
                picked: cubit.state.tapToStar,
              ),
            ),
          ),
        ),
        SizedBox(height: gap),
      ],
    ];
    final program = FocusTap(
      key: widget.programKey,
      focusNode: _mainRowFocus,
      onTap: () => _pickRow(cubit, star: false),
      child: _BlockRow(
        parentId: null,
        blocks: blocks,
        style: style,
        frame: (row, hovered) => GlassSurface(
          padding: EdgeInsets.all(gap),
          tint: hovered ? scheme.primaryContainer : null,
          borderColor: hovered
              ? scheme.primary
              : showStar && !cubit.state.tapToStar
              ? scheme.primary.withValues(alpha: 0.6)
              : null,
          borderWidth: showStar && !cubit.state.tapToStar ? 3 : 1.2,
          child: widget.fitContent ? row : SingleChildScrollView(child: row),
        ),
      ),
    );

    Widget columnFor(double? starMax) => Column(
      mainAxisSize: widget.fitContent ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.fitContent) ...[
          ...topFor(null),
          ConstrainedBox(
            key: _program,
            // Always room to drop a block.
            constraints: BoxConstraints(minHeight: widget.blockSize + gap * 4),
            child: program,
          ),
        ] else ...[
          ...topFor(starMax),
          Expanded(key: _program, child: program),
        ],
        SizedBox(height: gap),
        // Count and buttons share a line when there is room; on narrow
        // columns the count gets its own line above them.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: gap,
          children: [
            if (cubit.maxBlocks case final max?)
              Text(
                '${cubit.blockCount} / $max',
                style: Theme.of(context).textTheme.headlineSmall,
              )
            else
              const SizedBox.shrink(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // L1 and R1, as undo and redo sit: left, then right.
                GamepadShortcut(
                  button: PadButton.leftBumper,
                  onPressed: widget.enabled && cubit.canUndo
                      ? cubit.undo
                      : null,
                  child: IconButton.filledTonal(
                    tooltip: l10n.undo,
                    onPressed: widget.enabled && cubit.canUndo
                        ? cubit.undo
                        : null,
                    icon: const Icon(Icons.undo_rounded),
                  ),
                ),
                SizedBox(width: gap),
                GamepadShortcut(
                  button: PadButton.rightBumper,
                  onPressed: widget.enabled && cubit.canRedo
                      ? cubit.redo
                      : null,
                  child: IconButton.filledTonal(
                    tooltip: l10n.redo,
                    onPressed: widget.enabled && cubit.canRedo
                        ? cubit.redo
                        : null,
                    icon: const Icon(Icons.redo_rounded),
                  ),
                ),
                SizedBox(width: gap),
                IconButton.filledTonal(
                  tooltip: cubit.state.pickedBlock != null
                      ? l10n.removeBlock
                      : l10n.clearBlocks,
                  onPressed:
                      widget.enabled &&
                          (blocks.isNotEmpty || cubit.state.star.isNotEmpty)
                      ? cubit.deletePickedOrClear
                      : null,
                  icon: Icon(
                    cubit.state.pickedBlock != null
                        ? Icons.delete_rounded
                        : Icons.delete_sweep_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    final column = widget.fitContent
        // Phones scroll the whole page, so the star row grows freely.
        ? columnFor(null)
        : LayoutBuilder(
            builder: (context, box) => columnFor(
              box.maxHeight.isFinite
                  ? max(widget.blockSize * 1.5, box.maxHeight * 0.3)
                  : null,
            ),
          );
    final editor = widget.fitContent
        ? BlocListener<BlocksCubit, BlockProgram>(
            // A new block in the program comes into view, even when the
            // program sits below the fold on a phone.
            listenWhen: (before, after) =>
                _count(after.main) > _count(before.main),
            listener: (_, _) =>
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final program = _program.currentContext;
                  if (program == null || !program.mounted) return;
                  final box = program.findRenderObject()! as RenderBox;
                  // Reveal the program's end above any bar floating over the
                  // page (reported as padding), like a text field's caret.
                  final bar = MediaQuery.paddingOf(program).bottom;
                  // Just the last row: new blocks land at the end.
                  final last = min(box.size.height, widget.blockSize * 2);
                  box.showOnScreen(
                    rect: Rect.fromLTWH(
                      0,
                      box.size.height - last,
                      box.size.width,
                      last + bar,
                    ),
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                }),
            child: column,
          )
        : column;
    if (!widget.showHowTo || !widget.enabled || blocks.isNotEmpty) {
      return editor;
    }
    return Stack(
      key: _stack,
      children: [
        editor,
        Positioned.fill(
          child: IgnorePointer(
            child: _HowToHand(
              stack: _stack,
              from: _firstBlock,
              to: _program,
              size: widget.blockSize,
            ),
          ),
        ),
      ],
    );
  }
}

int _count(List<Block> blocks) =>
    blocks.expand((block) => block.selfAndDescendants).length;

/// Shared look and state for placed blocks.
final class _BlockStyle {
  const _BlockStyle({
    required this.size,
    required this.gap,
    required this.enabled,
    required this.activeBlockId,
    this.lookHere = const {},
    this.fromHint = false,
    required this.issueBlockIds,
    this.stepValues = const {},
    required this.pickedFocus,
    this.focusId,
  });

  final double size;
  final double gap;
  final bool enabled;
  final String? activeBlockId;
  final Set<String> lookHere;
  final bool fromHint;
  final Set<String> issueBlockIds;

  /// The Step Box number each "use steps" block will use, by block id.
  final Map<String, String> stepValues;

  /// Focus for the picked block or row ([_BlockEditorState._pickedFocus]).
  final FocusNode pickedFocus;

  /// The block that uses [pickedFocus].
  final String? focusId;

  FocusNode? focusFor(String blockId) =>
      blockId == focusId ? pickedFocus : null;
}

/// Walks the main row in order, like a run: each "save steps" sets the
/// number for the "use steps" blocks after it ("?" before any is saved).
Map<String, String> _stepValues(List<Block> main) {
  final values = <String, String>{};
  int? saved;
  void walk(List<Block> row) {
    for (final block in row) {
      if (block.type == BlockType.setSteps) saved = block.count;
      if (block.type == BlockType.moveSteps) {
        values[block.id] = saved?.toString() ?? '?';
      }
      walk(block.children);
      walk(block.otherwise);
    }
  }

  walk(main);
  return values;
}

/// A dragged block is drawn this much bigger than [_BlockStyle.size].
const _lift = 1.1;

/// The finger holds a dragged block this far down it, so the block floats
/// just above the finger and the spot it will land on stays in sight.
const _hold = 0.85;

/// The dragged block's centre, which decides where it lands (see
/// [_BlockDraggable]).
Offset _centreOf(DragTargetDetails<Object> details, double size) =>
    details.offset + Offset(size * _lift / 2, size * _lift / 2);

/// A block that drags as soon as a finger or mouse moves it: touching a
/// block always drags it, and a swipe on the space around blocks scrolls.
/// It is shown [_lift] times [size] just above the finger, so even a wide
/// repeat lifts as a tile right where it's held. The block's centre, not
/// the finger, picks where it lands: where a child puts the block is where
/// it goes. Held near the top or bottom of an area that scrolls, it scrolls
/// that area, so the child can reach any spot without letting go.
class _BlockDraggable<T extends Object> extends StatefulWidget {
  const _BlockDraggable({
    required this.data,
    required this.type,
    required this.size,
    required this.childWhenDragging,
    required this.child,
  });

  final T data;
  final BlockType type;
  final double size;
  final Widget childWhenDragging;
  final Widget child;

  @override
  State<_BlockDraggable<T>> createState() => _BlockDraggableState<T>();
}

class _BlockDraggableState<T extends Object> extends State<_BlockDraggable<T>> {
  EdgeDraggingAutoScroller? _scroller;

  /// The nearest area around this block that can scroll up or down.
  ScrollableState? _scrollable() {
    var scrollable = Scrollable.maybeOf(context);
    while (scrollable != null) {
      final position = scrollable.position;
      if (scrollable.axisDirection == AxisDirection.down &&
          position.hasContentDimensions &&
          position.maxScrollExtent > position.minScrollExtent) {
        return scrollable;
      }
      scrollable = Scrollable.maybeOf(scrollable.context);
    }
    return null;
  }

  void _stop() {
    _scroller?.stopAutoScroll();
    _scroller = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lifted = widget.size * _lift;
    final anchor = Offset(lifted / 2, lifted * _hold);
    return Draggable<T>(
      data: widget.data,
      feedback: Material(
        type: MaterialType.transparency,
        child: BlockTile(type: widget.type, size: lifted),
      ),
      dragAnchorStrategy: (_, _, _) => anchor,
      feedbackOffset: Offset(0, lifted / 2 - anchor.dy),
      onDragStarted: () {
        HapticFeedback.selectionClick();
        if (_scrollable() case final scrollable?) {
          _scroller = EdgeDraggingAutoScroller(scrollable, velocityScalar: 50);
        }
      },
      onDragUpdate: (details) => _scroller?.startAutoScrollIfNecessary(
        (details.globalPosition - anchor) & Size.square(lifted),
      ),
      onDragEnd: (_) => _stop(),
      childWhenDragging: widget.childWhenDragging,
      child: widget.child,
    );
  }
}

/// A see-through copy of the dragged block where it will land.
class _DropGhost extends StatelessWidget {
  const _DropGhost({required this.data, required this.size});

  /// The dragged palette [BlockType] or placed [Block].
  final Object? data;
  final double size;

  @override
  Widget build(BuildContext context) {
    final type = switch (data) {
      final Block block => block.type,
      final BlockType type => type,
      _ => null,
    };
    if (type == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: Opacity(
        key: const ValueKey('dropGhost'),
        opacity: 0.4,
        child: BlockTile(type: type, size: size),
      ),
    );
  }
}

/// A row of placed blocks that takes drops anywhere in its [frame]. The
/// dragged block lands next to the nearest block, before or after it by
/// which half its centre is over (top or bottom half of a wide repeat), and
/// a see-through copy shows the spot. The copy stays while the block is
/// over it, so the row can't jump back and forth; spots that would leave a
/// moved block where it is show nothing.
class _BlockRow extends StatefulWidget {
  const _BlockRow({
    required this.parentId,
    required this.blocks,
    required this.style,
    required this.frame,
    this.idle,
  });

  final String? parentId;
  final List<Block> blocks;
  final _BlockStyle style;

  /// The row's box around [blocks]; [hovered] while a drop spot shows.
  final Widget Function(Widget blocks, bool hovered) frame;

  /// Shown after the last block while no drop spot shows, e.g. a "+".
  final Widget? idle;

  @override
  State<_BlockRow> createState() => _BlockRowState();
}

class _BlockRowState extends State<_BlockRow> {
  final _keys = <String, GlobalKey>{};
  final _ghost = GlobalKey();

  /// Where a drop would land, or null where it changes nothing.
  int? _slot;

  static Rect? _rectOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  int? _slotFor(Object data, Offset at) {
    final style = widget.style;
    final blocks = widget.blocks;
    if (_slot != null &&
        (_rectOf(_ghost)?.inflate(style.gap / 2).contains(at) ?? false)) {
      return _slot;
    }
    final rects = [for (final b in blocks) _rectOf(_keys[b.id] ?? _ghost)];
    var slot = blocks.length;
    // Below every block means the end; otherwise next to the nearest one,
    // looking along its line first.
    if (rects.isNotEmpty &&
        rects.every((r) => r != null) &&
        at.dy <= rects.map((r) => r!.bottom).reduce(max) + style.gap / 2) {
      var best = 0;
      var bestDistance = double.infinity;
      for (var i = 0; i < rects.length; i++) {
        final r = rects[i]!;
        final dx = max(0.0, max(r.left - at.dx, at.dx - r.right));
        final dy = max(0.0, max(r.top - at.dy, at.dy - r.bottom));
        final distance = dx * dx + 4 * dy * dy;
        if (distance < bestDistance) {
          best = i;
          bestDistance = distance;
        }
      }
      final r = rects[best]!;
      final after = r.width >= style.size * 3
          ? at.dy > r.center.dy
          : at.dx > r.center.dx;
      slot = best + (after ? 1 : 0);
    }
    if (data is Block) {
      final from = blocks.indexWhere((b) => b.id == data.id);
      if (from >= 0 && (slot == from || slot == from + 1)) return null;
    }
    return slot;
  }

  void _show(int? slot) {
    if (slot != _slot) setState(() => _slot = slot);
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final blocks = widget.blocks;
    final cubit = context.read<BlocksCubit>();
    _keys.removeWhere((id, _) => !blocks.any((b) => b.id == id));
    return DragTarget<Object>(
      // A moved block's own row takes it too, so lifting a block shows no
      // drop spot elsewhere.
      onWillAcceptWithDetails: (d) =>
          style.enabled &&
          (cubit.canDrop(d.data, widget.parentId) ||
              blocks.any((b) => b == d.data)),
      onMove: (d) => _show(_slotFor(d.data, _centreOf(d, style.size))),
      onLeave: (_) => _show(null),
      onAcceptWithDetails: (d) {
        final slot = _slot;
        _show(null);
        if (slot == null) return;
        cubit.drop(d.data, parentId: widget.parentId, index: slot);
      },
      builder: (context, candidates, _) {
        final data = candidates.firstOrNull;
        final slot = data == null ? null : _slot;
        final children = <Widget>[
          for (final block in blocks)
            KeyedSubtree(
              key: _keys.putIfAbsent(block.id, GlobalKey.new),
              child: _PlacedBlock(block: block, style: style),
            ),
        ];
        if (slot != null) {
          children.insert(
            min(slot, children.length),
            KeyedSubtree(
              key: _ghost,
              child: _DropGhost(data: data, size: style.size),
            ),
          );
        } else if (widget.idle case final idle?) {
          children.add(idle);
        }
        return widget.frame(
          Wrap(
            spacing: style.gap,
            runSpacing: style.gap,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: children,
          ),
          slot != null,
        );
      },
    );
  }
}

class _PaletteBlock extends StatelessWidget {
  const _PaletteBlock({
    super.key,
    required this.type,
    required this.size,
    required this.enabled,
    required this.onTap,
    required this.onGrab,
    this.pointed = false,
  });

  final BlockType type;
  final double size;
  final bool enabled;
  final VoidCallback onTap;

  /// R2 held: drag a new block out, as a finger does.
  final VoidCallback onGrab;
  final bool pointed;

  @override
  Widget build(BuildContext context) {
    final tile = BlockTile(
      type: type,
      size: type.isCondition && size < 64 ? 64 : size,
    );
    if (pointed) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedScale(
            scale: 1.15,
            duration: const Duration(milliseconds: 200),
            child: tile,
          ),
          Positioned(
            right: -size * 0.25,
            bottom: -size * 0.3,
            child: Icon(
              Icons.touch_app_rounded,
              size: size * 0.7,
              color: Colors.white,
              shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
            ),
          ),
        ],
      );
    }
    if (!enabled) return Opacity(opacity: 0.4, child: tile);
    return _BlockDraggable<BlockType>(
      data: type,
      type: type,
      size: size,
      childWhenDragging: Opacity(opacity: 0.5, child: tile),
      child: FocusTap(onTap: onTap, onGrab: onGrab, child: tile),
    );
  }
}

class _PlacedBlock extends StatelessWidget {
  const _PlacedBlock({required this.block, required this.style});

  final Block block;
  final _BlockStyle style;

  @override
  Widget build(BuildContext context) {
    final size = style.size;
    final container = block.type.isContainer;
    final Widget plain = container
        ? _ContainerBlock(block: block, style: style)
        : block.type == BlockType.setSteps
        ? _SavedStepsBlock(block: block, style: style)
        : BlockTile(
            key: ValueKey(block.id),
            type: block.type,
            size: size,
            highlighted: block.id == style.activeBlockId,
            hasIssue: style.issueBlockIds.contains(block.id),
            mark: !style.lookHere.contains(block.id)
                ? BlockMark.none
                : style.fromHint
                ? BlockMark.hint
                : BlockMark.bumped,
            stepValue: style.stepValues[block.id],
          );
    if (!style.enabled) return plain;
    final cubit = context.read<BlocksCubit>();
    final picked = context.select<BlocksCubit, bool>(
      (c) => c.state.pickedBlock == block.id,
    );
    final carried = picked && cubit.state.carrying;
    // A tap picks a single block to fix: a ring shows which one. With a
    // controller, holding R2 on it carries it somewhere else.
    final Widget body = container
        ? plain
        : Semantics(
            selected: picked,
            child: FocusTap(
              focusNode: style.focusFor(block.id),
              onTap: () => cubit.pickBlock(block.id),
              onGrab: () => cubit.carry(block.id),
              child: _Lifted(
                lifted: carried,
                size: size,
                child: Container(
                  foregroundDecoration: picked
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(size * 0.26),
                          border: Border.all(
                            color: const Color(0xFFFFC83D),
                            width: 5,
                          ),
                        )
                      : null,
                  child: plain,
                ),
              ),
            ),
          );
    return _BlockDraggable<Block>(
      data: block,
      type: block.type,
      size: size,
      childWhenDragging: Opacity(opacity: 0.3, child: body),
      child: body,
    );
  }
}

/// The saved number is editable with large buttons and picture dots.
class _SavedStepsBlock extends StatelessWidget {
  const _SavedStepsBlock({required this.block, required this.style});
  final Block block;
  final _BlockStyle style;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      label: l.stepBoxValue(block.count.toString()),
      child: Container(
        key: ValueKey(block.id),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: block.type.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: style.issueBlockIds.contains(block.id)
                ? Theme.of(context).colorScheme.error
                : block.id == style.activeBlockId
                ? const Color(0xFFFFD54F)
                : block.type.color,
            width: 3,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BlockTile(type: block.type, size: style.size),
            _CountStepper(
              count: block.count,
              size: 64,
              color: block.type.color,
              onChanged: style.enabled
                  ? (value) =>
                        context.read<BlocksCubit>().setCount(block.id, value)
                  : null,
              fewerLabel: l.stepsFewer,
              moreLabel: l.stepsMore,
              minimum: 1,
            ),
          ],
        ),
      ),
    );
  }
}

/// A repeat or condition holding its own row of blocks.
class _ContainerBlock extends StatelessWidget {
  const _ContainerBlock({required this.block, required this.style});

  final Block block;
  final _BlockStyle style;

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<BlocksCubit>();
    final size = style.size;
    // An "otherwise" block holds two rows: clear, and blocked.
    final twoRows = block.type == BlockType.ifElse;
    // Only a repeat carries a count.
    final counted = block.type == BlockType.repeat;
    final color = block.type.color;
    final active = block.selfAndDescendants.any(
      (b) => b.id == style.activeBlockId,
    );
    final hasIssue = style.issueBlockIds.contains(block.id);
    final addSpot = Semantics(
      container: true,
      child: Icon(
        Icons.add_rounded,
        size: size * 0.6,
        color: color.withValues(alpha: 0.6),
        semanticLabel: AppLocalizations.of(context).dropBlocksHere,
      ),
    );
    final carried = cubit.state.carrying && cubit.state.pickedBlock == block.id;
    final header = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The controller picks the block here: the whole block holds other
        // blocks, which the highlight must reach too.
        // With a controller, holding R2 here carries the whole block.
        FocusTap(
          focusNode: style.focusFor(block.id),
          onTap: style.enabled ? () => cubit.pickContainer(block.id) : null,
          onGrab: style.enabled ? () => cubit.carry(block.id) : null,
          child: BlockTile(type: block.type, size: size * 0.8),
        ),
        if (counted) ...[
          SizedBox(height: style.gap * 0.5),
          _CountStepper(
            count: block.count,
            size: size,
            color: color,
            onChanged: style.enabled
                ? (count) => cubit.setCount(block.id, count)
                : null,
          ),
        ],
      ],
    );
    // A drop row: the block's own row, or an "otherwise" block's second.
    Widget dropRow(String parentId, List<Block> blocks) => _BlockRow(
      parentId: parentId,
      blocks: blocks,
      style: style,
      idle: style.enabled && blocks.isNotEmpty ? addSpot : null,
      frame: (row, hovered) => Container(
        constraints: BoxConstraints(
          minWidth: size * 1.4,
          minHeight: size * 1.2,
        ),
        padding: EdgeInsets.all(style.gap * 0.5),
        decoration: BoxDecoration(
          color: hovered
              ? color.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(size * 0.2),
          border: cubit.state.selectedContainer == parentId && twoRows
              ? Border.all(color: color, width: 3)
              : null,
        ),
        // An empty row shows a "+" in its middle.
        child: blocks.isEmpty && !hovered ? addSpot : row,
      ),
    );
    final Widget body;
    if (twoRows) {
      // Pictures, not words, tell the rows apart: an open path, then a
      // wall. A tap on a row picks it for tapped palette blocks.
      Widget labelled(String parentId, List<Block> blocks, bool clear) {
        final l10n = AppLocalizations.of(context);
        return GestureDetector(
          onTap: style.enabled ? () => cubit.pickContainer(parentId) : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FocusTap(
                onTap: style.enabled
                    ? () => cubit.pickContainer(parentId)
                    : null,
                child: Tooltip(
                  message: clear
                      ? l10n.otherwiseRowClear
                      : l10n.otherwiseRowBlocked,
                  child: Icon(
                    clear ? Icons.check_circle_rounded : Icons.block_rounded,
                    size: size * 0.45,
                    color: clear
                        ? const Color(0xFF43A047)
                        : const Color(0xFFE53935),
                  ),
                ),
              ),
              SizedBox(width: style.gap * 0.5),
              Flexible(child: dropRow(parentId, blocks)),
            ],
          ),
        );
      }

      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          labelled(block.id, block.children, true),
          SizedBox(height: style.gap * 0.5),
          labelled(BlocksCubit.otherwiseOf(block.id), block.otherwise, false),
        ],
      );
    } else {
      body = dropRow(block.id, block.children);
    }
    return GestureDetector(
      onTap: style.enabled ? () => cubit.pickContainer(block.id) : null,
      child: _Lifted(
        lifted: carried,
        size: size,
        child: AnimatedContainer(
          key: ValueKey(block.id),
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.all(style.gap * 0.6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(size * 0.28),
            border: Border.all(
              width: cubit.state.selectedContainer == block.id
                  ? size * 0.1
                  : size * 0.07,
              color: hasIssue
                  ? const Color(0xFFE53935)
                  : active
                  ? const Color(0xFFFFD54F)
                  : color,
            ),
          ),
          // Stack the header over the body when the room this block gets
          // (not the screen) is too narrow for them side by side.
          child: LayoutBuilder(
            builder: (context, box) {
              final nested = block.children.any((b) => b.type.isCondition);
              // Count buttons, then a condition holding a block.
              final sideBySide =
                  (counted ? 64 * 2 + size * 0.5 : size * 0.8) +
                  style.gap +
                  (nested ? size * 3.4 : size * 1.6) +
                  (twoRows ? size * 0.6 : 0);
              final stacked = box.maxWidth < sideBySide;
              return stacked
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        header,
                        SizedBox(height: style.gap),
                        body,
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        header,
                        SizedBox(width: style.gap),
                        Flexible(child: body),
                      ],
                    );
            },
          ),
        ),
      ),
    );
  }
}

/// The child's own block: what a star block runs. Built like the main row,
/// but a star can't go inside it.
class _StarRow extends StatelessWidget {
  const _StarRow({
    required this.blocks,
    required this.style,
    required this.picked,
  });

  final List<Block> blocks;
  final _BlockStyle style;

  /// Tapped palette blocks go here; shown with a thicker border.
  final bool picked;

  @override
  Widget build(BuildContext context) {
    final size = style.size;
    final color = BlockType.star.color;
    final addSpot = Icon(
      Icons.add_rounded,
      size: size * 0.6,
      color: color.withValues(alpha: 0.6),
      semanticLabel: AppLocalizations.of(context).dropBlocksHere,
    );
    return _BlockRow(
      parentId: BlocksCubit.starRow,
      blocks: blocks,
      style: style,
      idle: style.enabled || blocks.isEmpty ? addSpot : null,
      frame: (row, hovered) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.all(style.gap),
        decoration: BoxDecoration(
          color: hovered
              ? color.withValues(alpha: 0.22)
              : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            width: picked ? 5 : 3,
            color: color.withValues(alpha: picked ? 1 : 0.5),
          ),
        ),
        child: Row(
          children: [
            BlockTile(type: BlockType.star, size: size * 0.8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: style.gap),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: size * 0.5,
                color: color,
              ),
            ),
            Expanded(child: row),
          ],
        ),
      ),
    );
  }
}

/// Repeat count as a number and dots, with big minus/plus buttons.
class _CountStepper extends StatelessWidget {
  const _CountStepper({
    required this.count,
    required this.size,
    required this.color,
    required this.onChanged,
    this.fewerLabel,
    this.moreLabel,
    this.minimum = 2,
  });

  final String? fewerLabel;
  final String? moreLabel;
  final int minimum;
  final int count;
  final double size;
  final Color color;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget button(IconData icon, int to, String tooltip) => IconButton(
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
      iconSize: size * 0.4,
      color: color,
      onPressed: onChanged != null && to >= minimum && to <= maxCount
          ? () => onChanged!(to)
          : null,
      icon: Icon(icon),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            button(
              Icons.remove_circle_rounded,
              count - 1,
              fewerLabel ?? l10n.repeatFewer,
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: size * 0.42,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            button(
              Icons.add_circle_rounded,
              count + 1,
              moreLabel ?? l10n.repeatMore,
            ),
          ],
        ),
        SizedBox(
          width: size * 1.4,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 3,
            runSpacing: 3,
            children: [
              for (var i = 0; i < count; i++)
                Container(
                  width: size * 0.11,
                  height: size * 0.11,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A hand that drags from [from] to [to], over and over: how to add a block.
class _HowToHand extends StatefulWidget {
  const _HowToHand({
    required this.stack,
    required this.from,
    required this.to,
    required this.size,
  });

  final GlobalKey stack;
  final GlobalKey from;
  final GlobalKey to;
  final double size;

  @override
  State<_HowToHand> createState() => _HowToHandState();
}

class _HowToHandState extends State<_HowToHand>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Centre of [key]'s widget, relative to the editor.
  Offset? _centre(GlobalKey key, {double dy = 0.5}) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    final stack = widget.stack.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || stack == null || !box.hasSize) return null;
    return stack.globalToLocal(
      box.localToGlobal(Offset(box.size.width / 2, box.size.height * dy)),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final from = _centre(widget.from);
      final to = _centre(widget.to, dy: 0.3);
      if (from == null || to == null) return const SizedBox.shrink();
      // Press, drag, let go, then fade before the next round.
      final t = _controller.value;
      final drag = Curves.easeInOut.transform(
        ((t - 0.15) / 0.55).clamp(0.0, 1.0),
      );
      final at = Offset.lerp(from, to, drag)!;
      final opacity = t < 0.85 ? 1.0 : (1 - (t - 0.85) / 0.15);
      final size = widget.size;
      return Stack(
        children: [
          // The block being dragged.
          if (t > 0.15 && t < 0.85)
            Positioned(
              left: at.dx - size * 0.45,
              top: at.dy - size * 0.45,
              child: Opacity(
                opacity: 0.75,
                child: BlockTile(type: BlockType.forward, size: size * 0.9),
              ),
            ),
          Positioned(
            left: at.dx - size * 0.1,
            top: at.dy + size * 0.05,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Icon(
                Icons.touch_app_rounded,
                size: size * 0.9,
                color: Colors.white,
                shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// A block carried with a controller floats up with a shadow, like a block
/// held by a finger.
class _Lifted extends StatelessWidget {
  const _Lifted({
    required this.lifted,
    required this.size,
    required this.child,
  });

  final bool lifted;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    transform: Matrix4.translationValues(0, lifted ? -size * 0.12 : 0, 0),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * 0.26),
      boxShadow: lifted
          ? const [
              BoxShadow(
                blurRadius: 14,
                offset: Offset(0, 8),
                color: Color(0x66000000),
              ),
            ]
          : const [],
    ),
    child: child,
  );
}
