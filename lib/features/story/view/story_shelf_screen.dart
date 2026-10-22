import 'package:cobalagi/core/responsive/fold.dart';
import 'package:cobalagi/features/adventure_map/view/fold_scenery.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/responsive/window_class.dart';
import 'package:cobalagi/core/widgets/centered_scroll_view.dart';
import 'package:cobalagi/core/widgets/glass_app_bar.dart';
import 'package:cobalagi/core/widgets/glass_surface.dart';
import 'package:cobalagi/features/learning/cubit/learning_cubit.dart';
import 'package:cobalagi/features/learning/view/concepts.dart';
import 'package:cobalagi/features/profiles/cubit/profiles_cubit.dart';
import 'package:cobalagi/features/profiles/view/profile_avatar.dart';
import 'package:cobalagi/features/story/data/story_art.dart';
import 'package:cobalagi/features/story/data/story_scene.dart';
import 'package:cobalagi/features/story/view/story_player.dart';
import 'package:cobalagi/features/story/view/story_screen.dart';

/// The map's movie button: every scene of the story the child has reached
/// ([StoryScreen.reached]), each a card with a still from it, in story
/// order. A card plays its scene again, which saves nothing.
class StoryShelfScreen extends StatefulWidget {
  const StoryShelfScreen({super.key, required this.profileId});

  final int profileId;

  @override
  State<StoryShelfScreen> createState() => _StoryShelfScreenState();
}

class _StoryShelfScreenState extends State<StoryShelfScreen> {
  StoryArt? _art;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfilesCubit>().state.byId(widget.profileId);
    StoryArt.load().then(
      (art) {
        if (!mounted) return;
        setState(
          () => _art = art.withEmblem(
            profile == null ? null : avatarEmblem(profile.avatar),
          ),
        );
      },
      // Without pictures the cards still show the night sky and a title.
      onError: (Object _) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final learner = context.watch<LearningCubit>().state.learner;
    if (learner == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final map = '/child/${widget.profileId}';
    // On a half-folded phone, the beginning and the endings stand behind the
    // fold and the planets' scenes lie flat in front of it.
    final folded = FoldHalves.of(context) != null;
    final reached = StoryScreen.reached(learner);
    bool planet(String name) => name.startsWith('arrival-');
    Widget shelf(Iterable<String> names, {EdgeInsets? padding}) =>
        WindowClassBuilder(
          builder: (context, windowClass) => CenteredScrollView(
            padding: padding ?? belowBars(context, const EdgeInsets.all(24)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 20,
                runSpacing: 20,
                children: [
                  for (final name in names)
                    _SceneCard(
                      scene: StoryScreen.scenes[name]!,
                      title: _title(l10n, name),
                      art: _art,
                      width: windowClass == WindowClass.compact ? 280 : 260,
                      onTap: () => context.go('$map/story/$name?replay=true'),
                    ),
                ],
              ),
            ),
          ),
        );
    return FoldHalf(
      viewTakesTaps: folded,
      view: folded
          ? shelf(
              reached.where((name) => !planet(name)),
              padding: EdgeInsets.zero,
            )
          : const FoldScenery(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(
          leading: BackButton(onPressed: () => context.go(map)),
          title: Text(l10n.storyTitle),
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: Builder(
            builder: (context) =>
                shelf(folded ? reached.where(planet) : reached),
          ),
        ),
      ),
    );
  }

  static String _title(AppLocalizations l10n, String name) {
    final concept = name.substring(name.lastIndexOf('-') + 1);
    return switch (name) {
      'intro' => l10n.storyShelfIntro,
      _ when name.startsWith('arrival-') => conceptName(l10n, concept),
      _ when name.startsWith('new-planet-') => l10n.storyShelfNewPlanet,
      _ when name.startsWith('full-again-') => l10n.storyShelfFullAgain,
      _ => l10n.storyShelfEnding,
    };
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({
    required this.scene,
    required this.title,
    required this.art,
    required this.width,
    required this.onTap,
  });

  final StoryScene scene;
  final String title;
  final StoryArt? art;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: GlassSurface(
      radius: 20,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          painter: StoryScenePainter(
                            scene: scene,
                            frame: _Still(
                              StoryFrame(
                                beat: scene.beats.length - 1,
                                t: 1,
                                time: 0,
                              ),
                            ),
                            art: art,
                            stage: EdgeInsets.zero,
                          ),
                        ),
                        // In the sky's corner, clear of Koba and the ship.
                        const Positioned(
                          left: 6,
                          top: 6,
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            size: 44,
                            color: Color(0xE6FFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// A frame that never changes, so a card paints once.
class _Still implements ValueListenable<StoryFrame> {
  const _Still(this.value);

  @override
  final StoryFrame value;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
