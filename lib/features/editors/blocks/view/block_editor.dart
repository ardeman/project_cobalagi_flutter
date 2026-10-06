import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../engine/program/instruction.dart';
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
  });

  /// Shows a hand dragging the first palette block into the program, for a
  /// child who hasn't played yet. Hidden once the program has a block.
  final bool showHowTo;

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
    );

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DragTarget<Block>(
          onAcceptWithDetails: (d) => cubit.remove(d.data.id),
          builder: (context, candidates, _) => AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.all(gap),
            decoration: BoxDecoration(
              color: candidates.isEmpty
                  ? scheme.surfaceContainerHigh
                  : scheme.errorContainer,
              borderRadius: BorderRadius.circular(24),
            ),
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
                    enabled: widget.enabled && !cubit.isFull,
                    onTap: () => cubit.tap(type),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: gap),
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
        Expanded(
          key: _program,
          child: GestureDetector(
            onTap: () => cubit.pickRow(star: false),
            child: DragTarget<Object>(
              onWillAcceptWithDetails: (d) =>
                  widget.enabled && (d.data is Block || !cubit.isFull),
              onAcceptWithDetails: (d) =>
                  cubit.drop(d.data, index: blocks.length),
              builder: (context, candidates, _) => AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: EdgeInsets.all(gap),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    // The thicker border marks where tapped blocks go.
                    width: showStar && !cubit.state.tapToStar ? 5 : 3,
                    color: candidates.isEmpty
                        ? scheme.outlineVariant
                        : scheme.primary,
                  ),
                ),
                child: SingleChildScrollView(
                  child: _BlockRow(
                    parentId: null,
                    blocks: blocks,
                    style: style,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: gap),
        Row(
          children: [
            if (cubit.maxBlocks case final max?)
              Text(
                '${cubit.blockCount} / $max',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            const Spacer(),
            IconButton.filledTonal(
              tooltip: l10n.undo,
              onPressed: widget.enabled && blocks.isNotEmpty
                  ? cubit.removeLast
                  : null,
              icon: const Icon(Icons.backspace_rounded),
            ),
            SizedBox(width: gap),
            IconButton.filledTonal(
              tooltip: l10n.clearBlocks,
              onPressed:
                  widget.enabled &&
                      (blocks.isNotEmpty || cubit.state.star.isNotEmpty)
                  ? cubit.clear
                  : null,
              icon: const Icon(Icons.delete_sweep_rounded),
            ),
          ],
        ),
      ],
    );
    if (!widget.showHowTo || !widget.enabled || blocks.isNotEmpty) {
      return column;
    }
    return Stack(
      key: _stack,
      children: [
        column,
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

/// Shared look and state for placed blocks.
final class _BlockStyle {
  const _BlockStyle({
    required this.size,
    required this.gap,
    required this.enabled,
    required this.activeBlockId,
    required this.issueBlockIds,
  });

  final double size;
  final double gap;
  final bool enabled;
  final String? activeBlockId;
  final Set<String> issueBlockIds;
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
  });

  final BlockType type;
  final double size;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tile = BlockTile(type: type, size: size);
    if (!enabled) return Opacity(opacity: 0.4, child: tile);
    return Draggable<BlockType>(
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
    final Widget body = block.type == BlockType.repeat
        ? _RepeatBlock(block: block, style: style)
        : BlockTile(
            key: ValueKey(block.id),
            type: block.type,
            size: size,
            highlighted: block.id == style.activeBlockId,
            hasIssue: style.issueBlockIds.contains(block.id),
          );
    if (!style.enabled) return body;
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
            child: Draggable<Block>(
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

/// A repeat block: a count the child can change and a row of blocks inside.
class _RepeatBlock extends StatelessWidget {
  const _RepeatBlock({required this.block, required this.style});

  final Block block;
  final _BlockStyle style;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BlocksCubit>();
    final size = style.size;
    final color = BlockType.repeat.color;
    final active = block.selfAndDescendants.any(
      (b) => b.id == style.activeBlockId,
    );
    final hasIssue = style.issueBlockIds.contains(block.id);
    // Drops here land at the end of the repeat (the drop area around it
    // appends).
    final addSpot = Icon(
      Icons.add_rounded,
      size: size * 0.6,
      color: color.withValues(alpha: 0.6),
      semanticLabel: AppLocalizations.of(context).dropBlocksHere,
    );

    return AnimatedContainer(
      key: ValueKey(block.id),
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.all(style.gap * 0.6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          width: size * 0.07,
          color: hasIssue
              ? const Color(0xFFE53935)
              : active
              ? const Color(0xFFFFD54F)
              : color,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BlockTile(type: BlockType.repeat, size: size * 0.8),
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
          ),
          SizedBox(width: style.gap),
          // The blocks inside wrap within the width that is left.
          Flexible(
            child: DragTarget<Object>(
              onWillAcceptWithDetails: (d) =>
                  style.enabled &&
                  d.data != block &&
                  d.data != BlockType.repeat &&
                  (d.data is Block || !cubit.isFull),
              onAcceptWithDetails: (d) => cubit.drop(
                d.data,
                parentId: block.id,
                index: block.children.length,
              ),
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
                        // Without this there is nowhere to drop a block at
                        // the end once the repeat holds blocks.
                        trailing: style.enabled ? addSpot : null,
                      ),
              ),
            ),
          ),
        ],
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
  });

  final int count;
  final double size;
  final Color color;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget button(IconData icon, int to, String tooltip) => IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      iconSize: size * 0.4,
      color: color,
      onPressed: onChanged != null && to >= 2 && to <= maxCount
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
            button(Icons.remove_circle_rounded, count - 1, l10n.repeatFewer),
            Text(
              '$count',
              style: TextStyle(
                fontSize: size * 0.42,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            button(Icons.add_circle_rounded, count + 1, l10n.repeatMore),
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
