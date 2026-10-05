import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../engine/program/instruction.dart';
import '../../../../engine/program/validation.dart';
import '../cubit/icon_blocks_cubit.dart';
import '../data/icon_block.dart';
import 'icon_block_tile.dart';

/// Tier 1 editor: drag (touch or mouse) or tap palette blocks to build a row.
/// Drag a placed block to reorder it, into a repeat block to repeat it, or
/// back onto the palette to remove it.
class IconBlockEditor extends StatelessWidget {
  const IconBlockEditor({
    super.key,
    required this.palette,
    required this.blockSize,
    this.activeBlockId,
    this.issueBlockIds = const {},
    this.enabled = true,
  });

  final Set<InstructionKind> palette;
  final double blockSize;
  final String? activeBlockId;
  final Set<String> issueBlockIds;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.watch<IconBlocksCubit>();
    final blocks = cubit.state;
    final scheme = Theme.of(context).colorScheme;
    final types = [
      for (final type in IconBlockType.values)
        if (palette.contains(type.kind)) type,
    ];
    final gap = blockSize * 0.18;
    final style = _BlockStyle(
      size: blockSize,
      gap: gap,
      enabled: enabled,
      activeBlockId: activeBlockId,
      issueBlockIds: issueBlockIds,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DragTarget<IconBlock>(
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
                    type: type,
                    size: blockSize,
                    enabled: enabled && !cubit.isFull,
                    onTap: () => cubit.add(type),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: gap),
        Expanded(
          child: DragTarget<Object>(
            onWillAcceptWithDetails: (d) =>
                enabled && (d.data is IconBlock || !cubit.isFull),
            onAcceptWithDetails: (d) =>
                cubit.drop(d.data, index: blocks.length),
            builder: (context, candidates, _) => AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.all(gap),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  width: 3,
                  color: candidates.isEmpty
                      ? scheme.outlineVariant
                      : scheme.primary,
                ),
              ),
              child: SingleChildScrollView(
                child: _BlockRow(parentId: null, blocks: blocks, style: style),
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
              onPressed: enabled && blocks.isNotEmpty ? cubit.removeLast : null,
              icon: const Icon(Icons.backspace_rounded),
            ),
            SizedBox(width: gap),
            IconButton.filledTonal(
              tooltip: l10n.clearBlocks,
              onPressed: enabled && blocks.isNotEmpty ? cubit.clear : null,
              icon: const Icon(Icons.delete_sweep_rounded),
            ),
          ],
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
  });

  final String? parentId;
  final List<IconBlock> blocks;
  final _BlockStyle style;

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
          onDrop: (data) => context.read<IconBlocksCubit>().drop(
            data,
            parentId: parentId,
            index: i,
          ),
        ),
    ],
  );
}

class _PaletteBlock extends StatelessWidget {
  const _PaletteBlock({
    required this.type,
    required this.size,
    required this.enabled,
    required this.onTap,
  });

  final IconBlockType type;
  final double size;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tile = IconBlockTile(type: type, size: size);
    if (!enabled) return Opacity(opacity: 0.4, child: tile);
    return Draggable<IconBlockType>(
      data: type,
      feedback: Material(
        type: MaterialType.transparency,
        child: IconBlockTile(type: type, size: size * 1.1),
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

  final IconBlock block;
  final _BlockStyle style;

  /// Something was dropped on this block: insert it before this block.
  final void Function(Object data) onDrop;

  @override
  Widget build(BuildContext context) {
    final size = style.size;
    final Widget body = block.type == IconBlockType.repeat
        ? _RepeatBlock(block: block, style: style)
        : IconBlockTile(
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
            child: Draggable<IconBlock>(
              data: block,
              feedback: Material(
                type: MaterialType.transparency,
                child: IconBlockTile(type: block.type, size: size * 1.1),
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

  final IconBlock block;
  final _BlockStyle style;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<IconBlocksCubit>();
    final size = style.size;
    final color = IconBlockType.repeat.color;
    final active = block.selfAndDescendants.any(
      (b) => b.id == style.activeBlockId,
    );
    final hasIssue = style.issueBlockIds.contains(block.id);

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
              IconBlockTile(type: IconBlockType.repeat, size: size * 0.8),
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
                  d.data != IconBlockType.repeat &&
                  (d.data is IconBlock || !cubit.isFull),
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
                    ? Icon(
                        Icons.add_rounded,
                        size: size * 0.6,
                        color: color.withValues(alpha: 0.6),
                        semanticLabel: AppLocalizations.of(
                          context,
                        ).dropBlocksHere,
                      )
                    : _BlockRow(
                        parentId: block.id,
                        blocks: block.children,
                        style: style,
                      ),
              ),
            ),
          ),
        ],
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
