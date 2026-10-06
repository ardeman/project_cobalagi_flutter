import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/responsive/window_class.dart';
import '../../learning/cubit/learning_cubit.dart';
import '../../learning/view/concepts.dart';
import 'package:cobalagi/core/widgets/glass_app_bar.dart';

/// One island's levels. Levels already played can be replayed for fun; the
/// rest open as the adventure reaches them.
class IslandScreen extends StatelessWidget {
  const IslandScreen({
    super.key,
    required this.profileId,
    required this.conceptId,
  });

  final int profileId;
  final String conceptId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.watch<LearningCubit>();
    final learner = cubit.state.learner;
    if (learner == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final lessons = cubit.curriculum.lessons[conceptId] ?? const [];
    final progress = cubit.engine.progressOf(learner, conceptId);
    final color = conceptColor(conceptId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        leading: BackButton(onPressed: () => context.go('/child/$profileId')),
        title: Row(
          children: [
            Icon(conceptIcon(conceptId), color: color, size: 32),
            const SizedBox(width: 12),
            Text(conceptName(l10n, conceptId)),
          ],
        ),
      ),
      // The scroll view pads itself, so content passes under the bar.
      body: SafeArea(
        top: false,
        bottom: false,
        child: WindowClassBuilder(
          builder: (context, windowClass) {
            final tile = windowClass == WindowClass.compact ? 104.0 : 140.0;
            return Center(
              child: SingleChildScrollView(
                padding: belowBars(context, const EdgeInsets.all(24)),
                child: Column(
                  children: [
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 20,
                      runSpacing: 20,
                      children: [
                        for (var i = 0; i < lessons.length; i++)
                          _LevelTile(
                            number: i + 1,
                            size: tile,
                            color: color,
                            played: progress.attemptedLessons.contains(
                              lessons[i].id,
                            ),
                            solved: progress.solvedLessons.contains(
                              lessons[i].id,
                            ),
                            onTap: () => context.go(
                              '/child/$profileId/replay/${lessons[i].id}',
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    FilledButton.icon(
                      icon: const Icon(Icons.play_arrow_rounded, size: 40),
                      label: Text(l10n.continueAdventure),
                      onPressed: () => context.go('/child/$profileId/play'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.number,
    required this.size,
    required this.color,
    required this.played,
    required this.solved,
    required this.onTap,
  });

  final int number;
  final double size;
  final Color color;
  final bool played;
  final bool solved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: played,
      label: played
          ? l10n.levelNumber(number)
          : '${l10n.levelNumber(number)}, ${l10n.levelLocked}',
      child: Card(
        color: played ? color : scheme.surfaceContainerHigh,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: played ? onTap : null,
          child: SizedBox(
            width: size,
            height: size,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (played)
                  Text(
                    '$number',
                    style: TextStyle(
                      fontSize: size * 0.36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(
                    Icons.lock_rounded,
                    size: size * 0.36,
                    color: scheme.outline,
                  ),
                Icon(
                  solved ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: size * 0.22,
                  color: solved
                      ? const Color(0xFFFFC83D)
                      : (played ? Colors.white70 : Colors.transparent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
