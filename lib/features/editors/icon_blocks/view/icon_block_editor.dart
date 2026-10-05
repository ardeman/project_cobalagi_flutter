import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../engine/program/instruction.dart';
import '../cubit/icon_blocks_cubit.dart';
import '../data/icon_block.dart';
import 'icon_block_tile.dart';

/// Tier 1 editor: drag (touch or mouse) or tap palette blocks to build a row.
/// Drag a placed block to reorder it, or back onto the palette to remove it.
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
    // Repeat blocks arrive with the Loops levels in Phase 3.
    final types = [
      for (final type in IconBlockType.values)
        if (palette.contains(type.kind) && type != IconBlockType.repeat) type,
    ];
    final gap = blockSize * 0.18;

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
            onAcceptWithDetails: (d) => _drop(cubit, d.data, blocks.length),
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
                child: Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (var i = 0; i < blocks.length; i++)
                      _PlacedBlock(
                        block: blocks[i],
                        size: blockSize,
                        enabled: enabled,
                        highlighted: blocks[i].id == activeBlockId,
                        hasIssue: issueBlockIds.contains(blocks[i].id),
                        onDrop: (data) => _drop(cubit, data, i),
                      ),
                  ],
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

  static void _drop(IconBlocksCubit cubit, Object data, int index) {
    switch (data) {
      case IconBlockType type:
        cubit.add(type, index: index);
      case IconBlock block:
        cubit.move(block.id, index);
    }
  }
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
    required this.size,
    required this.enabled,
    required this.highlighted,
    required this.hasIssue,
    required this.onDrop,
  });

  final IconBlock block;
  final double size;
  final bool enabled;
  final bool highlighted;
  final bool hasIssue;

  /// Something was dropped on this block: insert it before this block.
  final void Function(Object data) onDrop;

  @override
  Widget build(BuildContext context) {
    final tile = IconBlockTile(
      key: ValueKey(block.id),
      type: block.type,
      size: size,
      highlighted: highlighted,
      hasIssue: hasIssue,
    );
    if (!enabled) return tile;
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
          Draggable<IconBlock>(
            data: block,
            feedback: Material(
              type: MaterialType.transparency,
              child: IconBlockTile(type: block.type, size: size * 1.1),
            ),
            childWhenDragging: Opacity(opacity: 0.3, child: tile),
            child: tile,
          ),
        ],
      ),
    );
  }
}
