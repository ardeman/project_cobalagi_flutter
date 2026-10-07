import 'package:flutter/material.dart';
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
            final tile = windowClass == WindowClass.compact ? 132.0 : 168.0;
            return Center(
              child: SingleChildScrollView(
                padding: belowBars(context, const EdgeInsets.all(24)),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    for (final game in cubit.curriculum.warmUp.games)
                      _GameTile(
                        game: game,
                        size: tile,
                        stars: learner.warmUp[game.name] ?? 0,
                        onTap: () => context.go(
                          '/child/$profileId/warm-up/${game.name}',
                        ),
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
