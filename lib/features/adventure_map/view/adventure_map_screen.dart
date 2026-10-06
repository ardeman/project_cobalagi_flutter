import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cobalagi/core/widgets/glass_surface.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/voice_clips.dart';
import '../../../core/responsive/window_class.dart';
import '../../../learning/progress_report.dart';
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

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/')),
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
      body: SafeArea(
        child: WindowClassBuilder(
          builder: (context, windowClass) {
            final islandSize = switch (windowClass) {
              WindowClass.compact => 104.0,
              WindowClass.medium => 140.0,
              WindowClass.expanded => 180.0,
            };
            if (learner.placement == null) {
              return _Welcome(
                size: islandSize,
                onStart: () => context.go('/child/$profileId/pretest'),
              );
            }
            final lessons = cubit.curriculum.lessons;
            return Column(
              children: [
                if (learner.review case final trip?)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _BonusBanner(conceptId: trip.conceptId),
                  ),
                Expanded(
                  child: OceanMap(
                    marker: GlassSurface(
                      padding: const EdgeInsets.all(3),
                      radius: 48,
                      blur: false,
                      child: ProfileAvatar(avatar: profile.avatar, size: 40),
                    ),
                    islands: [
                      for (var i = 0; i < concepts.length; i++)
                        MapIsland(
                          conceptId: concepts[i].id,
                          stars: ProgressReport.starsFor(
                            learner.progress[concepts[i].id],
                            engine.config,
                          ),
                          solvedLessons:
                              learner
                                  .progress[concepts[i].id]
                                  ?.solvedLessons
                                  .length ??
                              0,
                          totalLessons: lessons[concepts[i].id]?.length ?? 0,
                          current: i == currentIndex,
                          locked:
                              i > currentIndex &&
                              !learner.progress.containsKey(concepts[i].id),
                        ),
                    ],
                    onOpen: (id) => context.go('/child/$profileId/island/$id'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.icon(
                    icon: const Icon(Icons.play_arrow_rounded, size: 48),
                    label: Text(l10n.play),
                    onPressed: () => context.go('/child/$profileId/play'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
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
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sports_esports_rounded,
              size: size * 1.2,
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
