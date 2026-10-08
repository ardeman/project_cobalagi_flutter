import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cobalagi/core/widgets/glass_surface.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/audio/voice_clips.dart';
import '../../../engine/world/grid_point.dart';
import '../../../engine/world/level.dart';
import '../../../learning/placement/pretest_question.dart';
import '../../editors/blocks/data/block.dart';
import '../../editors/blocks/view/block_tile.dart';
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
  ColorQuestion(:final color) => (
    switch (color) {
      'red' => l10n.promptColorRed,
      'blue' => l10n.promptColorBlue,
      'green' => l10n.promptColorGreen,
      _ => l10n.promptColorYellow,
    },
    VoiceClips.warmUpColor(color),
  ),
  ShapeQuestion(:final shape) => (
    switch (shape) {
      'circle' => l10n.promptShapeCircle,
      'square' => l10n.promptShapeSquare,
      'triangle' => l10n.promptShapeTriangle,
      _ => l10n.promptShapeHeart,
    },
    VoiceClips.warmUpShape(shape),
  ),
};

/// Shows [question] and reports the tapped option index.
class QuestionView extends StatelessWidget {
  const QuestionView({
    super.key,
    required this.question,
    required this.size,
    required this.onAnswer,
    this.chosen,
    this.answerLabel,
  });

  final PretestQuestion question;

  /// After an answer: the tapped option. The right option lights up green;
  /// a wrong tap wobbles in orange.
  final int? chosen;

  /// After a wrong tap, shown under the right option, e.g. "The answer is
  /// this one!".
  final String? answerLabel;

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
                    ? BlockType.turnLeft.color
                    : BlockType.turnRight.color,
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
      ColorQuestion(:final options) || ShapeQuestion(:final options) => (
        null,
        [for (final p in options) PretestPicture(picture: p, size: size * 0.6)],
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
                  BlockTile(
                    type: BlockType.values.firstWhere((t) => t.kind == kind),
                    size: size * 0.28,
                  ),
              ],
            ),
        ],
      ),
    };

    final screen = MediaQuery.sizeOf(context);
    final sideways = screen.height < 600 && screen.width > screen.height * 1.3;
    final cards = [
      for (var i = 0; i < options.length; i++)
        _OptionCard(
          // Sideways, step cards share the row with the map, so they shrink.
          size: question is SequencingQuestion
              ? size * (sideways ? 1.3 : 1.6)
              : size,
          onTap: onAnswer == null ? null : () => onAnswer!(i),
          mark: switch (chosen) {
            null => _Mark.none,
            _ when i == question.correct => _Mark.right,
            final c when c == i => _Mark.wrong,
            _ => _Mark.faded,
          },
          label:
              chosen != null &&
                  chosen != question.correct &&
                  i == question.correct
              ? answerLabel
              : null,
          child: options[i],
        ),
    ];
    // Side questions place their two options left and right of a house.
    if (question is SideQuestion) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          cards[0],
          Flexible(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: size * 0.1),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: PretestPicture(
                  picture: const Picture('house'),
                  size: size,
                ),
              ),
            ),
          ),
          cards[1],
        ],
      );
    }
    // The label under the right answer needs room before the next row of
    // cards, e.g. when step cards stack on a phone. Kept before the answer
    // too, so the cards don't move when it appears.
    final labelled = answerLabel != null;
    final answers = Wrap(
      alignment: WrapAlignment.center,
      spacing: size * 0.2,
      runSpacing: labelled ? math.max(size * 0.2, _labelRoom) : size * 0.2,
      children: cards,
    );
    // Phones held sideways: the picture goes beside the answers, so both
    // fit the short screen without scrolling.
    if (stimulus != null && sideways) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          stimulus,
          SizedBox(width: size * 0.4),
          Flexible(child: answers),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (stimulus != null) ...[stimulus, SizedBox(height: size * 0.25)],
        answers,
      ],
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      GlassSurface(padding: const EdgeInsets.all(24), radius: 28, child: child);
}

/// How an option looks after the child answers.
enum _Mark { none, right, wrong, faded }

const _rightColor = Color(0xFF43A047);

/// Height of the arrow and one line of "The answer is this one!" under a
/// card, plus a little air.
const _labelRoom = 96.0;
const _wrongColor = Color(0xFFFB8C00);

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.size,
    required this.onTap,
    required this.mark,
    required this.child,
    this.label,
  });

  final double size;
  final VoidCallback? onTap;
  final _Mark mark;
  final Widget child;

  /// Shown under the card, pointing up at it, without moving other cards.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final height = size * (size > 300 ? 0.45 : 1);
    final border = switch (mark) {
      _Mark.right => _rightColor,
      _Mark.wrong => _wrongColor,
      _ => Colors.transparent,
    };
    Widget card = SizedBox(
      width: size,
      height: height,
      child: Card(
        elevation: 3,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: border, width: 8),
        ),
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Padding(padding: const EdgeInsets.all(8), child: child),
          ),
        ),
      ),
    );
    if (mark == _Mark.right || mark == _Mark.wrong) {
      card = Stack(
        clipBehavior: Clip.none,
        children: [
          card,
          Positioned(
            right: -10,
            top: -10,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: border,
              child: Icon(
                mark == _Mark.right ? Icons.check_rounded : Icons.close_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          if (label case final text?)
            Positioned(
              top: height + 10,
              left: -size,
              right: -size,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_upward_rounded,
                    color: _rightColor,
                    size: 32,
                  ),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _rightColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }
    return switch (mark) {
      _Mark.faded => Opacity(opacity: 0.35, child: card),
      _Mark.wrong => _Wobble(child: card),
      _Mark.right => TweenAnimationBuilder<double>(
        tween: Tween(begin: 1, end: 1.08),
        duration: const Duration(milliseconds: 350),
        curve: Curves.elasticOut,
        builder: (_, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: card,
      ),
      _Mark.none => card,
    };
  }
}

/// A short side-to-side shake for a wrong tap.
class _Wobble extends StatelessWidget {
  const _Wobble({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 600),
    builder: (_, t, child) => Transform.translate(
      offset: Offset(math.sin(t * math.pi * 6) * 14 * (1 - t), 0),
      child: child,
    ),
    child: child,
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
