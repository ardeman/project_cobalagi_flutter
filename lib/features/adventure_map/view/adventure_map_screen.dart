import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cobalagi/core/widgets/centered_scroll_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cobalagi/core/widgets/glass_app_bar.dart';
import 'package:cobalagi/core/widgets/glass_frame.dart';
import 'package:cobalagi/core/widgets/glass_surface.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/sound_effects.dart';
import '../../../core/audio/voice_clips.dart';
import '../../../core/responsive/window_class.dart';
import '../../../learning/progress_report.dart';
import '../../../learning/stickers.dart';
import '../../../learning/warm_up/warm_up.dart';
import '../../learning/cubit/learning_cubit.dart';
import '../../learning/view/concepts.dart';
import '../../profiles/cubit/profiles_cubit.dart';
import '../../profiles/view/profile_avatar.dart';
import 'ocean_map.dart';

/// A child's home: one island per concept, with stars for mastery.
class AdventureMapScreen extends StatelessWidget {
  const AdventureMapScreen({super.key, required this.profileId});

  final int profileId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = context.watch<ProfilesCubit>().state.byId(profileId);
    final cubit = context.watch<LearningCubit>();
    final learner = cubit.state.learner;
    if (profile == null || learner == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final engine = cubit.engine;
    final concepts = engine.graph.concepts;
    final currentIndex = engine.graph.indexOf(learner.currentConcept);

    final lessons = cubit.curriculum.lessons;
    OceanMap map(EdgeInsets padding) => OceanMap(
      padding: padding,
      marker: GlassSurface(
        padding: const EdgeInsets.all(3),
        radius: 48,
        blur: false,
        child: ProfileAvatar(avatar: profile.avatar, size: 40),
      ),
      islands: [
        // Picture games before the coding islands, always open.
        MapIsland(
          conceptId: warmUpIsland,
          stars: cubit.curriculum.warmUp.islandStars(learner.warmUp),
          solvedLessons: cubit.curriculum.warmUp.gamesPlayed(learner.warmUp),
          totalLessons: cubit.curriculum.warmUp.games.length,
          current: false,
          locked: false,
        ),
        for (var i = 0; i < concepts.length; i++)
          MapIsland(
            conceptId: concepts[i].id,
            stars: ProgressReport.starsFor(
              learner.progress[concepts[i].id],
              engine.config,
              totalLessons: lessons[concepts[i].id]?.length ?? 0,
            ),
            solvedLessons:
                learner.progress[concepts[i].id]?.solvedLessons.length ?? 0,
            totalLessons: lessons[concepts[i].id]?.length ?? 0,
            current: i == currentIndex,
            unlocking: concepts[i].id == cubit.state.islandToCelebrate,
            locked:
                i > currentIndex &&
                !learner.progress.containsKey(concepts[i].id),
          ),
      ],
      onOpen: (id) => context.go(
        id == warmUpIsland
            ? '/child/$profileId/warm-up'
            : '/child/$profileId/island/$id',
      ),
    );
    final play = Padding(
      padding: const EdgeInsets.all(16),
      child: FilledButton.icon(
        icon: const Icon(Icons.play_arrow_rounded, size: 48),
        label: Text(l10n.play),
        onPressed: () => context.go('/child/$profileId/play'),
      ),
    );
    final banner = switch (learner.review) {
      final trip? => _BonusBanner(conceptId: trip.conceptId),
      null => null,
    };

    return _CelebrationTrigger(
      island: cubit.state.islandToCelebrate,
      child: Scaffold(
        // Phones scroll the sea under the glass bars.
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(
          leading: BackButton(onPressed: () => context.go('/')),
          actions: [
            if (learner.placement != null)
              _StickerButton(
                fresh: newStickers(learner, cubit.stickers).length,
                onPressed: () => context.go('/child/$profileId/stickers'),
              ),
          ],
          title: Row(
            children: [
              ProfileAvatar(avatar: profile.avatar, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.greeting(profile.nickname),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        body: WindowClassBuilder(
          builder: (context, windowClass) {
            final islandSize = switch (windowClass) {
              WindowClass.compact => 104.0,
              WindowClass.medium => 140.0,
              WindowClass.expanded => 180.0,
            };
            if (learner.placement == null) {
              return SafeArea(
                child: _Welcome(
                  size: islandSize,
                  onStart: () => context.go('/child/$profileId/pretest'),
                ),
              );
            }
            // The sea fills the screen on every device, under the app bar and
            // the Play bar. They stay clear while nothing is beneath them and
            // turn to glass when islands scroll under; the bonus banner
            // floats on top.
            final top = MediaQuery.paddingOf(context).top;
            return GlassFrame(
              bottom: SafeArea(top: false, child: Center(child: play)),
              builder: (context, insets) => Stack(
                children: [
                  Positioned.fill(
                    child: map(
                      EdgeInsets.only(
                        top: top + (banner == null ? 0 : 88),
                        bottom: insets.bottom,
                      ),
                    ),
                  ),
                  if (banner != null)
                    Positioned(
                      top: top + 8,
                      left: 16,
                      right: 16,
                      child: banner,
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

/// Opens the sticker book; a badge counts stickers not seen yet.
class _StickerButton extends StatelessWidget {
  const _StickerButton({required this.fresh, required this.onPressed});

  final int fresh;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: AppLocalizations.of(context).stickerBook,
    style: IconButton.styleFrom(minimumSize: const Size(64, 64)),
    onPressed: onPressed,
    icon: Badge(
      isLabelVisible: fresh > 0,
      label: Text('$fresh'),
      backgroundColor: const Color(0xFFFF7A59),
      child: const Icon(Icons.collections_bookmark_rounded, size: 32),
    ),
  );
}

/// First visit: invite the child to the warm-up game that places them.
class _Welcome extends StatefulWidget {
  const _Welcome({required this.size, required this.onStart});

  final double size;
  final VoidCallback onStart;

  @override
  State<_Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<_Welcome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AudioService>().playVoice(
        VoiceClips.pretestWelcome,
        languageCode: Localizations.localeOf(context).languageCode,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final onStart = widget.onStart;
    final l10n = AppLocalizations.of(context);
    return CenteredScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sports_esports_rounded,
            // Smaller on short screens, so Start stays in view.
            size: min(size * 1.2, MediaQuery.sizeOf(context).height * 0.22),
            color: const Color(0xFFFF7A59),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.pretestWelcome,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            icon: const Icon(Icons.play_arrow_rounded, size: 48),
            label: Text(l10n.pretestStart),
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

class _BonusBanner extends StatelessWidget {
  const _BonusBanner({required this.conceptId});

  final String conceptId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GlassSurface(
      tint: const Color(0xFFFFF3C4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.diamond_rounded,
              size: 48,
              color: Color(0xFF26C6DA),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.bonusAdventure,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(conceptName(l10n, conceptId)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Plays the opening of a newly reached island once: a cheer while the map
/// animates it, then it is marked as celebrated.
class _CelebrationTrigger extends StatefulWidget {
  const _CelebrationTrigger({required this.island, required this.child});

  final String? island;
  final Widget child;

  @override
  State<_CelebrationTrigger> createState() => _CelebrationTriggerState();
}

class _CelebrationTriggerState extends State<_CelebrationTrigger> {
  Timer? _done;

  @override
  void initState() {
    super.initState();
    if (widget.island == null) return;
    final learning = context.read<LearningCubit>();
    context.read<AudioService>().playEffect(SoundEffect.goal);
    _done = Timer(const Duration(milliseconds: 2400), learning.celebrated);
  }

  @override
  void dispose() {
    _done?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
