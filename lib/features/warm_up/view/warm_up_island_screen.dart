import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cobalagi/core/widgets/centered_scroll_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/voice_clips.dart';
import '../../../core/responsive/window_class.dart';
import '../../../learning/placement/pretest_question.dart';
import '../../../learning/warm_up/warm_up.dart';
import '../../learning/cubit/learning_cubit.dart';
import '../../learning/view/concepts.dart';
import 'warm_up_games.dart';
import 'package:cobalagi/core/widgets/glass_app_bar.dart';

/// The Warm-up island: picture games without reading, always open. Each
/// game earns up to three stars as the child reaches its harder levels.
class WarmUpIslandScreen extends StatefulWidget {
  const WarmUpIslandScreen({super.key, required this.profileId});

  final int profileId;

  @override
  State<WarmUpIslandScreen> createState() => _WarmUpIslandScreenState();
}

class _WarmUpIslandScreenState extends State<WarmUpIslandScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AudioService>().playVoice(
        VoiceClips.warmUpPick,
        languageCode: Localizations.localeOf(context).languageCode,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.watch<LearningCubit>();
    final learner = cubit.state.learner;
    if (learner == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final profileId = widget.profileId;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        leading: BackButton(onPressed: () => context.go('/child/$profileId')),
        title: Row(
          children: [
            Icon(
              conceptIcon(warmUpIsland),
              color: conceptColor(warmUpIsland),
              size: 32,
            ),
            const SizedBox(width: 12),
            Text(conceptName(l10n, warmUpIsland)),
          ],
        ),
      ),
      // The scroll view pads itself, so content passes under the bar.
      body: SafeArea(
        top: false,
        bottom: false,
        child: WindowClassBuilder(
          builder: (context, windowClass) {
            final padding = belowBars(context, const EdgeInsets.all(24));
            final room = MediaQuery.sizeOf(context);
            final tile = _tileSize(
              games: cubit.curriculum.warmUp.games.length,
              width: room.width - padding.horizontal,
              height: room.height - padding.vertical,
              largest: windowClass == WindowClass.compact ? 132.0 : 168.0,
            );
            return CenteredScrollView(
              padding: padding,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: _gap,
                runSpacing: _gap,
                children: [
                  for (final game in cubit.curriculum.warmUp.games)
                    _GameTile(
                      game: game,
                      size: tile,
                      stars: learner.warmUp[game.name] ?? 0,
                      onTap: () =>
                          context.go('/child/$profileId/warm-up/${game.name}'),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Gap between game tiles.
const _gap = 20.0;

/// The biggest tile, up to [largest], at which every game fits the screen
/// at once in some number of columns (a phone held sideways puts them all in
/// one row), so the games never need scrolling. Never below a big finger's
/// size: on a tiny screen the page scrolls instead.
double _tileSize({
  required int games,
  required double width,
  required double height,
  required double largest,
}) {
  var best = 0.0;
  for (var columns = 1; columns <= max(1, games); columns++) {
    final rows = (games / columns).ceil();
    // Each tile's card has a 4 dp margin around it.
    final fit =
        min(
          (width - _gap * (columns - 1)) / columns,
          (height - _gap * (rows - 1)) / rows,
        ) -
        8;
    best = max(best, fit);
  }
  // Rounded down, so a row that fills the width exactly never wraps.
  return best.floorToDouble().clamp(80.0, largest);
}

class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.game,
    required this.size,
    required this.stars,
    required this.onTap,
  });

  final WarmUpGame game;
  final double size;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = game.label(AppLocalizations.of(context));
    return Semantics(
      button: true,
      label: name,
      excludeSemantics: true,
      child: Card(
        color: game.color,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(game.icon, size: size * 0.4, color: Colors.white),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: size * 0.12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < maxSkillLevel; i++)
                      Icon(
                        i < stars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: size * 0.16,
                        color: i < stars
                            ? const Color(0xFFFFC83D)
                            : Colors.white70,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
