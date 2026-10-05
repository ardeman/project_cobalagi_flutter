import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/voice_clips.dart';
import '../../../core/responsive/window_class.dart';
import '../../../learning/learner_state.dart';
import '../../../learning/learning_engine.dart';
import '../../learning/cubit/learning_cubit.dart';
import '../../learning/view/concepts.dart';
import '../../profiles/cubit/profiles_cubit.dart';
import '../../profiles/view/profile_avatar.dart';

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
            Text(l10n.greeting(profile.nickname)),
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
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (learner.review case final trip?)
                      _BonusBanner(conceptId: trip.conceptId),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 24,
                      children: [
                        for (var i = 0; i < concepts.length; i++) ...[
                          if (i > 0)
                            Icon(
                              Icons.more_horiz_rounded,
                              size: islandSize * 0.4,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          _Island(
                            conceptId: concepts[i].id,
                            size: islandSize,
                            stars: _stars(engine, learner, concepts[i].id),
                            current: i == currentIndex,
                            locked:
                                i > currentIndex &&
                                !learner.progress.containsKey(concepts[i].id),
                            onTap: () => context.go(
                              '/child/$profileId/island/${concepts[i].id}',
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 40),
                    FilledButton.icon(
                      icon: const Icon(Icons.play_arrow_rounded, size: 48),
                      label: Text(l10n.play),
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

  /// 3 stars at mastery, 2 while practising well, 1 once started.
  static int _stars(LearningEngine engine, LearnerState learner, String id) {
    final progress = learner.progress[id];
    if (progress == null || progress.scores.isEmpty) return 0;
    final mastery = progress.mastery;
    if (mastery >= engine.config.advanceAt) return 3;
    if (mastery >= engine.config.practiceAt) return 2;
    return 1;
  }
}

class _Island extends StatelessWidget {
  const _Island({
    required this.conceptId,
    required this.size,
    required this.stars,
    required this.current,
    required this.locked,
    required this.onTap,
  });

  final String conceptId;
  final double size;
  final int stars;
  final bool current;
  final bool locked;

  /// Opens the island's levels; ignored while the island is locked.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = locked ? Colors.grey.shade400 : conceptColor(conceptId);
    return Semantics(
      button: !locked,
      child: GestureDetector(
        onTap: locked ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  width: size * 0.06,
                  color: current ? const Color(0xFFFFD54F) : Colors.white,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (current ? const Color(0xFFFFD54F) : Colors.black)
                        .withValues(alpha: current ? 0.6 : 0.15),
                    blurRadius: current ? size * 0.2 : size * 0.06,
                    offset: Offset(0, size * 0.04),
                  ),
                ],
              ),
              child: Icon(
                locked ? Icons.lock_rounded : conceptIcon(conceptId),
                size: size * 0.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Icon(
                    i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: size * 0.2,
                    color: const Color(0xFFFFC83D),
                  ),
              ],
            ),
            Text(
              conceptName(AppLocalizations.of(context), conceptId),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
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
    return Card(
      color: const Color(0xFFFFF3C4),
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
            Column(
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
          ],
        ),
      ),
    );
  }
}
