import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    this.issueBlockIds = const {},
    this.enabled = true,
    this.showHowTo = false,
    this.showTips = true,
    this.fitContent = false,
  });

  /// Shows a hand dragging the first palette block into the program, for a
  /// child who hasn't played yet. Hidden once the program has a block.
  final bool showHowTo;

  /// Shows written tips, such as how the Step Box works. Phones leave them
  /// out to keep room for the blocks; the goal voice explains the same.
  final bool showTips;

  /// Phones place the editor in a page that scrolls with the world: it takes
  /// the height of its blocks instead of filling the space it is given.
  final bool fitContent;

  final Set<InstructionKind> palette;
  final double blockSize;
  final String? activeBlockId;
  final Set<String> issueBlockIds;
  final bool enabled;

  @override
  State<BlockEditor> createState() => _BlockEditorState();
}

class _BlockEditorState extends State<BlockEditor> {
  final _stack = GlobalKey();
  final _firstBlock = GlobalKey();
  final _program = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.watch<BlocksCubit>();
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
      issueBlockIds: widget.issueBlockIds,
      // Placed blocks sit in rows that scroll, on tablets too.
      holdToDrag: true,
    );

    final top = <Widget>[
      DragTarget<Block>(
        onAcceptWithDetails: (d) => cubit.remove(d.data.id),
        builder: (context, candidates, _) => GlassSurface(
          padding: EdgeInsets.all(gap),
          tint: candidates.isEmpty ? null : scheme.errorContainer,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final type in types)
                _PaletteBlock(
                  key: type == types.first ? _firstBlock : null,
                  type: type,
                  size: widget.blockSize,
                  // Replacing a picked block keeps the count, so the palette
                  // stays usable even at the block limit.
                  enabled:
                      widget.enabled &&
                      (!cubit.isFull || cubit.state.pickedBlock != null),
                  hold: widget.fitContent,
                  onTap: () => cubit.tap(type),
                ),
            ],
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
        GestureDetector(
          onTap: () => cubit.pickRow(star: true),
          child: _StarRow(
            blocks: cubit.state.star,
            style: style,
            picked: cubit.state.tapToStar,
          ),
        ),
        SizedBox(height: gap),
      ],
    ];
    final row = _BlockRow(parentId: null, blocks: blocks, style: style);
    final program = GestureDetector(
      onTap: () => cubit.pickRow(star: false),
      child: DragTarget<Object>(
        onWillAcceptWithDetails: (d) =>
            widget.enabled && (d.data is Block || !cubit.isFull),
        onAcceptWithDetails: (d) => cubit.drop(d.data, index: blocks.length),
        builder: (context, candidates, _) => GlassSurface(
          padding: EdgeInsets.all(gap),
          tint: candidates.isEmpty ? null : scheme.primaryContainer,
          borderColor: candidates.isNotEmpty
              ? scheme.primary
              : showStar && !cubit.state.tapToStar
              ? scheme.primary.withValues(alpha: 0.6)
              : null,
          borderWidth: showStar && !cubit.state.tapToStar ? 3 : 1.2,
          child: widget.fitContent ? row : SingleChildScrollView(child: row),
        ),
      ),
    );

    final column = Column(
      mainAxisSize: widget.fitContent ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.fitContent) ...[
          ...top,
          ConstrainedBox(
            key: _program,
            // Always room to drop a block.
            constraints: BoxConstraints(minHeight: widget.blockSize + gap * 4),
            child: program,
          ),
        ] else ...[
          ...top,
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
                IconButton.filledTonal(
                  tooltip: l10n.undo,
                  onPressed: widget.enabled && cubit.canUndo
                      ? cubit.undo
                      : null,
                  icon: const Icon(Icons.undo_rounded),
                ),
                SizedBox(width: gap),
                IconButton.filledTonal(
                  tooltip: l10n.redo,
                  onPressed: widget.enabled && cubit.canRedo
                      ? cubit.redo
                      : null,
                  icon: const Icon(Icons.redo_rounded),
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
    required this.issueBlockIds,
    this.holdToDrag = false,
  });

  final double size;
  final double gap;
  final bool enabled;
  final String? activeBlockId;
  final Set<String> issueBlockIds;

  /// See [_dragSource].
  final bool holdToDrag;
}

/// How long a finger rests on a block before it lifts where its row
/// scrolls; a swipe that moves sooner scrolls instead.
const _holdToDrag = Duration(milliseconds: 200);

/// A block that can be dragged. Where its row scrolls ([hold]), a finger
/// lifts it only after a short hold, so swiping across wide blocks scrolls
/// instead; a mouse, which scrolls with its wheel, still drags at once.
Widget _dragSource<T extends Object>({
  required bool hold,
  required T data,
  required Widget feedback,
  required Widget childWhenDragging,
  required Widget child,
}) {
  if (!hold) {
    return Draggable<T>(
      data: data,
      feedback: feedback,
      childWhenDragging: childWhenDragging,
      child: child,
    );
  }
  return _MouseDraggable<T>(
    data: data,
    feedback: feedback,
    childWhenDragging: childWhenDragging,
    child: _HoldDraggable<T>(
      data: data,
      feedback: feedback,
      childWhenDragging: childWhenDragging,
      child: child,
    ),
  );
}

/// Drags at once, but only with a mouse or trackpad.
class _MouseDraggable<T extends Object> extends Draggable<T> {
  const _MouseDraggable({
    required super.data,
    required super.feedback,
    required super.childWhenDragging,
    required super.child,
  });

  @override
  MultiDragGestureRecognizer createRecognizer(
    GestureMultiDragStartCallback onStart,
  ) => ImmediateMultiDragGestureRecognizer(
    supportedDevices: const {
      PointerDeviceKind.mouse,
      PointerDeviceKind.trackpad,
    },
  )..onStart = onStart;
}

/// Drags after [_holdToDrag] with a finger or stylus, with a small click.
class _HoldDraggable<T extends Object> extends Draggable<T> {
  const _HoldDraggable({
    required super.data,
    required super.feedback,
    required super.childWhenDragging,
    required super.child,
  });

  @override
  MultiDragGestureRecognizer createRecognizer(
    GestureMultiDragStartCallback onStart,
  ) =>
      DelayedMultiDragGestureRecognizer(
          delay: _holdToDrag,
          supportedDevices: const {
            PointerDeviceKind.touch,
            PointerDeviceKind.stylus,
            PointerDeviceKind.invertedStylus,
            PointerDeviceKind.unknown,
          },
        )
        ..onStart = (position) {
          final drag = onStart(position);
          if (drag != null) HapticFeedback.selectionClick();
          return drag;
        };
}

class _BlockRow extends StatelessWidget {
  const _BlockRow({
    required this.parentId,
    required this.blocks,
    required this.style,
    this.trailing,
  });

  final String? parentId;
  final List<Block> blocks;
  final _BlockStyle style;

  /// Shown after the last block, e.g. a drop spot for adding at the end.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: style.gap,
    runSpacing: style.gap,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (var i = 0; i < blocks.length; i++)
        _PlacedBlock(
          block: blocks[i],
          style: style,
          onDrop: (data) => context.read<BlocksCubit>().drop(
            data,
            parentId: parentId,
            index: i,
          ),
        ),
      ?trailing,
    ],
  );
}

class _PaletteBlock extends StatelessWidget {
  const _PaletteBlock({
    super.key,
    required this.type,
    required this.size,
    required this.enabled,
    required this.onTap,
    this.hold = false,
  });

  final BlockType type;
  final double size;
  final bool enabled;
  final VoidCallback onTap;
  final bool hold;

  @override
  Widget build(BuildContext context) {
    final tile = BlockTile(
      type: type,
      size: type == BlockType.ifPathClear && size < 64 ? 64 : size,
    );
    if (!enabled) return Opacity(opacity: 0.4, child: tile);
    return _dragSource<BlockType>(
      hold: hold,
      data: type,
      feedback: Material(
        type: MaterialType.transparency,
        child: BlockTile(type: type, size: size * 1.1),
      ),
      childWhenDragging: Opacity(opacity: 0.5, child: tile),
      child: GestureDetector(onTap: onTap, child: tile),
    );
  }
}

class _PlacedBlock extends StatelessWidget {
  const _PlacedBlock({
    required this.block,
    required this.style,
    required this.onDrop,
  });

  final Block block;
  final _BlockStyle style;

  /// Something was dropped on this block: insert it before this block.
  final void Function(Object data) onDrop;

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
          );
    if (!style.enabled) return plain;
    final cubit = context.read<BlocksCubit>();
    final picked = context.select<BlocksCubit, bool>(
      (c) => c.state.pickedBlock == block.id,
    );
    // A tap picks a single block to fix: a ring shows which one.
    final Widget body = container
        ? plain
        : Semantics(
            selected: picked,
            child: GestureDetector(
              onTap: () => cubit.pickBlock(block.id),
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
          );
    return DragTarget<Object>(
      onWillAcceptWithDetails: (d) => d.data != block,
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (context, candidates, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Shows where a dropped block will land.
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: candidates.isEmpty ? 0 : size * 0.5,
            height: size,
          ),
          // Flexible keeps a wide repeat block within the row, so it wraps.
          Flexible(
            child: _dragSource<Block>(
              hold: style.holdToDrag,
              data: block,
              feedback: Material(
                type: MaterialType.transparency,
                child: BlockTile(type: block.type, size: size * 1.1),
              ),
              childWhenDragging: Opacity(opacity: 0.3, child: body),
              child: body,
            ),
          ),
        ],
      ),
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
    final conditional = block.type == BlockType.ifPathClear;
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
    final header = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BlockTile(type: block.type, size: size * 0.8),
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
    final body = DragTarget<Object>(
      onWillAcceptWithDetails: (d) =>
          style.enabled &&
          d.data != block &&
          d.data != BlockType.repeat &&
          d.data != BlockType.untilGoal &&
          (!conditional || d.data != BlockType.ifPathClear) &&
          (d.data is Block || !cubit.isFull),
      onAcceptWithDetails: (d) =>
          cubit.drop(d.data, parentId: block.id, index: block.children.length),
      builder: (context, candidates, _) => Container(
        constraints: BoxConstraints(
          minWidth: size * 1.4,
          minHeight: size * 1.2,
        ),
        padding: EdgeInsets.all(style.gap * 0.5),
        decoration: BoxDecoration(
          color: candidates.isEmpty
              ? Colors.white.withValues(alpha: 0.6)
              : color.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(size * 0.2),
        ),
        child: block.children.isEmpty
            ? addSpot
            : _BlockRow(
                parentId: block.id,
                blocks: block.children,
                style: style,
                trailing: style.enabled ? addSpot : null,
              ),
      ),
    );
    return GestureDetector(
      onTap: style.enabled ? () => cubit.pickContainer(block.id) : null,
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
            final nested = block.children.any(
              (b) => b.type == BlockType.ifPathClear,
            );
            // Count buttons, then a condition holding a block.
            final sideBySide =
                (counted ? 64 * 2 + size * 0.5 : size * 0.8) +
                style.gap +
                (nested ? size * 3.4 : size * 1.6);
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
    final cubit = context.read<BlocksCubit>();
    final size = style.size;
    final color = BlockType.star.color;
    final addSpot = Icon(
      Icons.add_rounded,
      size: size * 0.6,
      color: color.withValues(alpha: 0.6),
      semanticLabel: AppLocalizations.of(context).dropBlocksHere,
    );
    return DragTarget<Object>(
      onWillAcceptWithDetails: (d) =>
          style.enabled &&
          d.data != BlockType.star &&
          (d.data is! Block || (d.data as Block).type != BlockType.star) &&
          (d.data is Block || !cubit.isFull),
      onAcceptWithDetails: (d) => cubit.drop(
        d.data,
        parentId: BlocksCubit.starRow,
        index: blocks.length,
      ),
      builder: (context, candidates, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.all(style.gap),
        decoration: BoxDecoration(
          color: candidates.isEmpty
              ? color.withValues(alpha: 0.08)
              : color.withValues(alpha: 0.22),
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
            Expanded(
              child: _BlockRow(
                parentId: BlocksCubit.starRow,
                blocks: blocks,
                style: style,
                trailing: style.enabled || blocks.isEmpty ? addSpot : null,
              ),
            ),
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
