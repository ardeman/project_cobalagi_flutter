import 'package:flutter/material.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/audio/voice_clips.dart';
import '../../../engine/world/grid_point.dart';
import '../../../engine/world/level.dart';
import '../../../learning/placement/pretest_question.dart';
import '../../editors/icon_blocks/data/icon_block.dart';
import '../../editors/icon_blocks/view/icon_block_tile.dart';
import 'pretest_pictures.dart';

/// The spoken and written prompt for a question, plus its voice clip id.
(String text, String clip) promptFor(
  AppLocalizations l10n,
  PretestQuestion question,
) => switch (question) {
  ReadingQuestion() => (l10n.promptReading, VoiceClips.pretestReading),
  CountingQuestion() => (l10n.promptCounting, VoiceClips.pretestCounting),
  SideQuestion(target: Side.left) => (
    l10n.promptSideLeft,
    VoiceClips.pretestSideLeft,
  ),
  SideQuestion(target: Side.right) => (
    l10n.promptSideRight,
    VoiceClips.pretestSideRight,
  ),
  TurnQuestion(turn: Side.left) => (
    l10n.promptTurnLeft,
    VoiceClips.pretestTurnLeft,
  ),
  TurnQuestion(turn: Side.right) => (
    l10n.promptTurnRight,
    VoiceClips.pretestTurnRight,
  ),
  PatternQuestion() => (l10n.promptPattern, VoiceClips.pretestPattern),
  SequencingQuestion() => (l10n.promptSequencing, VoiceClips.pretestSequencing),
};

/// Shows [question] and reports the tapped option index.
class QuestionView extends StatelessWidget {
  const QuestionView({
    super.key,
    required this.question,
    required this.size,
    required this.onAnswer,
  });

  final PretestQuestion question;

  /// Base size of pictures and option cards.
  final double size;
  final ValueChanged<int>? onAnswer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (Widget? stimulus, List<Widget> options) = switch (question) {
      ReadingQuestion(:final words, :final options) => (
        _Board(
          child: Text(
            writtenWords(l10n, words),
            style: Theme.of(
              context,
            ).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        [for (final p in options) PretestPicture(picture: p, size: size * 0.6)],
      ),
      CountingQuestion(:final object, :final count, :final options) => (
        _Board(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < count; i++)
                PretestPicture(picture: Picture(object), size: size * 0.38),
            ],
          ),
        ),
        [
          for (final n in options)
            Text(
              '$n',
              style: TextStyle(
                fontSize: size * 0.45,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
      SideQuestion() => (
        null,
        [
          PretestPicture(picture: const Picture('star'), size: size * 0.6),
          PretestPicture(picture: const Picture('star'), size: size * 0.6),
        ],
      ),
      TurnQuestion(:final facing, :final turn, :final options) => (
        _Board(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DirectionArrow(direction: facing, size: size * 0.7),
              const SizedBox(width: 16),
              Icon(
                turn == Side.left
                    ? Icons.turn_left_rounded
                    : Icons.turn_right_rounded,
                size: size * 0.5,
                color: turn == Side.left
                    ? IconBlockType.turnLeft.color
                    : IconBlockType.turnRight.color,
              ),
            ],
          ),
        ),
        [
          for (final d in options)
            DirectionArrow(direction: d, size: size * 0.55),
        ],
      ),
      PatternQuestion(:final sequence, :final options) => (
        _Board(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              for (final p in sequence)
                PretestPicture(picture: p, size: size * 0.4),
              Icon(
                Icons.help_rounded,
                size: size * 0.45,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
        [for (final p in options) PretestPicture(picture: p, size: size * 0.5)],
      ),
      SequencingQuestion(:final map, :final options) => (
        _Board(
          child: _MiniMap(level: map, cell: size * 0.32),
        ),
        [
          for (final steps in options)
            Wrap(
              spacing: 4,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                for (final kind in steps)
                  IconBlockTile(
                    type: IconBlockType.values.firstWhere(
                      (t) => t.kind == kind,
                    ),
                    size: size * 0.28,
                  ),
              ],
            ),
        ],
      ),
    };

    final cards = [
      for (var i = 0; i < options.length; i++)
        _OptionCard(
          size: question is SequencingQuestion ? size * 1.6 : size,
          onTap: onAnswer == null ? null : () => onAnswer!(i),
          child: options[i],
        ),
    ];
    // Side questions place their two options left and right of a house.
    if (question is SideQuestion) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          cards[0],
          SizedBox(width: size * 0.3),
          PretestPicture(picture: const Picture('house'), size: size),
          SizedBox(width: size * 0.3),
          cards[1],
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (stimulus != null) ...[stimulus, SizedBox(height: size * 0.25)],
        Wrap(
          alignment: WrapAlignment.center,
          spacing: size * 0.2,
          runSpacing: size * 0.2,
          children: cards,
        ),
      ],
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(28),
    ),
    child: child,
  );
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.size,
    required this.onTap,
    required this.child,
  });

  final double size;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size * (size > 300 ? 0.45 : 1),
    child: Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Padding(padding: const EdgeInsets.all(8), child: child),
        ),
      ),
    ),
  );
}

/// A small top-down map: path tiles, the arrow at the start, a flag at the goal.
class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.level, required this.cell});

  final Level level;
  final double cell;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var y = 0; y < level.height; y++)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var x = 0; x < level.width; x++) _cell(GridPoint(x, y)),
          ],
        ),
    ],
  );

  Widget _cell(GridPoint p) {
    final open = level.isOpen(p);
    return Container(
      width: cell,
      height: cell,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: open ? const Color(0xFFFFF1C9) : const Color(0xFF9CCC65),
        borderRadius: BorderRadius.circular(cell * 0.2),
      ),
      child: p == level.start
          ? DirectionArrow(direction: level.startFacing, size: cell * 0.8)
          : p == level.goal
          ? Icon(Icons.flag_rounded, size: cell * 0.75, color: Colors.red)
          : null,
    );
  }
}
