import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cobalagi/features/adventure_map/view/fold_scenery.dart';
import 'package:cobalagi/core/responsive/fold.dart';
import 'package:cobalagi/core/character/koba_head.dart';
import 'package:cobalagi/core/gamepad/gamepad_shortcut.dart';
import 'package:cobalagi/core/gamepad/pad_input.dart';
import 'package:cobalagi/core/widgets/centered_scroll_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:go_router/go_router.dart';
import 'package:cobalagi/core/widgets/glass_app_bar.dart';
import 'package:cobalagi/core/widgets/glass_frame.dart';
import 'package:cobalagi/core/widgets/glass_surface.dart';
import 'package:cobalagi/features/story/view/ship_flight.dart';
import 'package:cobalagi/features/story/view/story_screen.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/sound_effects.dart';
import '../../../core/audio/voice_clips.dart';
import '../../../core/responsive/window_class.dart';
import '../../../learning/progress_report.dart';
import '../../../learning/stickers.dart';
import '../../../learning/learning_engine.dart';
import '../../../learning/story.dart';
import '../../../learning/warm_up/warm_up.dart';
import '../../learning/cubit/learning_cubit.dart';
import '../../learning/view/concepts.dart';
import '../../profiles/cubit/profiles_cubit.dart';
import '../../profiles/view/profile_avatar.dart';
import 'space_map.dart';

/// A child's home: one island per concept, with stars for mastery.
class AdventureMapScreen extends StatefulWidget {
  const AdventureMapScreen({
    super.key,
    required this.profileId,
    this.flyHome = false,
  });

  final int profileId;

  /// Set by "Continue the adventure" on another planet: Koba's ship flies
  /// back to the current planet, then the puzzle starts, as with Play.
  final bool flyHome;

  @override
  State<AdventureMapScreen> createState() => _AdventureMapScreenState();
}

class _AdventureMapScreenState extends State<AdventureMapScreen> {
  /// The map, so Play can fly Koba's ship back to the current planet first.
  final _map = GlobalKey<SpaceMapState>();

  int get profileId => widget.profileId;

  /// Whether this visit's [AdventureMapScreen.flyHome] has started.
  var _flyingHome = false;

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
    // The map is built under the screens opened from it, so a planet opened
    // by the puzzle just solved waits until the map is on top.
    final celebrate = (ModalRoute.of(context)?.isCurrent ?? true)
        ? cubit.state.islandToCelebrate
        : null;
    // A finished planet: Koba's ship flies from it to the one opening (map
    // index + 1, after the Warm-up planet), its stars filling the tank.
    final opening = switch (celebrate) {
      final id? => engine.graph.indexOf(id),
      null => -1,
    };
    final flight = opening < 1
        ? null
        : MapFlight(
            from: opening,
            to: opening + 1,
            fillFrom: Story.tankFill(
              finished: opening - 1,
              planets: concepts.length,
            ),
            fillTo: Story.tankFill(finished: opening, planets: concepts.length),
          );
    SpaceMap map(EdgeInsets padding, {bool sky = true}) => SpaceMap(
      sky: sky,
      key: _map,
      padding: padding,
      flight: flight,
      shipFill: Story.tankFill(
        finished: currentIndex,
        planets: concepts.length,
      ),
      emblem: avatarEmblem(profile.avatar),
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
              cubit.curriculum.lessonIds[concepts[i].id] ?? const [],
            ),
            solvedLessons:
                learner.progress[concepts[i].id]?.solvedLessons.length ?? 0,
            totalLessons: lessons[concepts[i].id]?.length ?? 0,
            current: i == currentIndex,
            unlocking: concepts[i].id == celebrate,
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
    // The ship flies back from a planet the child visited first.
    void onPlay() {
      void go() => context.go('/child/$profileId/play');
      final map = _map.currentState;
      map == null ? go() : map.flyHome(go);
    }

    if (!widget.flyHome) {
      _flyingHome = false;
    } else if (!_flyingHome && (ModalRoute.of(context)?.isCurrent ?? true)) {
      _flyingHome = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) onPlay();
      });
    }

    final play = Padding(
      padding: const EdgeInsets.all(16),
      child: GamepadShortcut(
        button: PadButton.x,
        onPressed: onPlay,
        child: FilledButton.icon(
          icon: const Icon(Icons.play_arrow_rounded, size: 48),
          label: Text(l10n.play),
          onPressed: onPlay,
        ),
      ),
    );
    final banner = switch (learner.review) {
      final trip? => _BonusBanner(conceptId: trip.conceptId),
      null => null,
    };

    return _CelebrationTrigger(
      island: celebrate,
      flies: flight != null && !MediaQuery.disableAnimationsOf(context),
      // The story's scenes (the intro, the new planet scene and the endings)
      // wait for a celebration to end, and for the map to be on top.
      story: switch (StoryScreen.dueOnMap(
        learner,
        concepts.last.id,
        mapComplete: cubit.state.lastDecision is MapComplete,
      )) {
        final scene? => '/child/$profileId/story/$scene',
        null => null,
      },
      // Space is dark: the bars, their glass and words are made for night.
      child: Theme(
        data: AppTheme.dark(),
        child: _MaybeFolded(
          // Half folded, the planets stand behind the fold and the bars lie
          // flat in front of it.
          fold: learner.placement == null ? null : FoldHalves.of(context),
          // One sky across both halves, painted behind them.
          map: (padding) => map(padding, sky: false),
          banner: banner,
          play: play,
          bar: (context, {glass = true}) => GlassAppBar(
            glass: glass,
            leading: BackButton(onPressed: () => context.go('/')),
            actions: [
              if (learner.placement != null)
                _StoryButton(
                  onPressed: () => context.go('/child/$profileId/stories'),
                ),
              if (learner.placement != null)
                _StickerButton(
                  fresh: newStickers(learner, cubit.stickers).length,
                  onPressed: () => context.go('/child/$profileId/stickers'),
                ),
            ],
            title: _Greeting(words: l10n.greeting(profile.nickname)),
          ),
          child: Scaffold(
            // Phones scroll the sky under the glass bars.
            extendBodyBehindAppBar: true,
            appBar: GlassAppBar(
              leading: BackButton(onPressed: () => context.go('/')),
              actions: [
                if (learner.placement != null)
                  _StoryButton(
                    onPressed: () => context.go('/child/$profileId/stories'),
                  ),
                if (learner.placement != null)
                  _StickerButton(
                    fresh: newStickers(learner, cubit.stickers).length,
                    onPressed: () => context.go('/child/$profileId/stickers'),
                  ),
              ],
              title: _Greeting(words: l10n.greeting(profile.nickname)),
            ),
            body: WindowClassBuilder(
              builder: (context, windowClass) {
                final islandSize = switch (windowClass) {
                  WindowClass.compact => 104.0,
                  WindowClass.medium => 140.0,
                  WindowClass.expanded => 180.0,
                };
                if (learner.placement == null) {
                  // In space like the map, so the night bars and words show.
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      const SpaceSky(),
                      SafeArea(
                        child: _Welcome(
                          size: islandSize,
                          onStart: () =>
                              context.go('/child/$profileId/pretest'),
                        ),
                      ),
                    ],
                  );
                }
                // The sky fills the screen on every device, under the app bar and
                // the Play bar. They stay clear while nothing is beneath them and
                // turn to glass when planets scroll under; the bonus banner
                // floats on top.
                final safe = MediaQuery.paddingOf(context);
                final top = safe.top;
                return GlassFrame(
                  bottom: SafeArea(top: false, child: Center(child: play)),
                  builder: (context, insets) => Stack(
                    children: [
                      Positioned.fill(
                        child: map(
                          EdgeInsets.only(
                            left: safe.left,
                            top: top + (banner == null ? 0 : 88),
                            right: safe.right,
                            bottom: insets.bottom,
                          ),
                        ),
                      ),
                      if (banner != null)
                        Positioned(
                          top: top + 8,
                          left: 16,
                          right: 16,
                          // Floating glass, as wide as its words.
                          child: Center(child: banner),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// The map as it is, or on a half-folded phone ([fold]) split at the fold:
/// the planets behind it, the bar, the bonus banner and Play in front, all
/// on one starry sky.
class _MaybeFolded extends StatelessWidget {
  const _MaybeFolded({
    required this.fold,
    required this.map,
    required this.banner,
    required this.play,
    required this.bar,
    required this.child,
  });

  final FoldHalves? fold;
  final Widget Function(EdgeInsets padding) map;
  final Widget? banner;
  final Widget play;
  final PreferredSizeWidget Function(BuildContext context, {bool glass}) bar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fold = this.fold;
    if (fold == null) {
      // Not folded, or before the warm-up: one half, as on a closed phone.
      return FoldHalf(view: const FoldScenery(), child: child);
    }
    final banner = this.banner;
    // Light time and signal over space.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const SpaceSky(),
            FoldSplit(
              halves: fold,
              // The bar above the planets, as the play screen's sits above
              // the world.
              view: Builder(
                builder: (context) {
                  final top = MediaQuery.paddingOf(context).top;
                  final barBottom = top + GlassAppBar.height;
                  return Stack(
                    children: [
                      // The planets pass under the bar and blur away
                      // towards the top, never cut off on a line.
                      Positioned.fill(
                        // The bar is plain: the map's scrolling mustn't
                        // turn it to glass.
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (_) => true,
                          child: map(
                            MediaQuery.paddingOf(
                              context,
                            ).copyWith(top: barBottom),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: barBottom + 24,
                        // Blur only, no tint: the sky shows no band.
                        child: const LiquidGlassScrollEdge(
                          edge: LiquidGlassEdge.top,
                          color: Colors.transparent,
                          blur: 10,
                        ),
                      ),
                      Positioned(
                        top: top,
                        left: 0,
                        right: 0,
                        height: GlassAppBar.height,
                        // Below the status bar, which the bar would
                        // otherwise add to its own height.
                        child: MediaQuery.removePadding(
                          context: context,
                          removeTop: true,
                          child: bar(context, glass: false),
                        ),
                      ),
                    ],
                  );
                },
              ),
              // Play in the middle of the flat half, under the bonus banner.
              controls: SafeArea(
                child: Column(
                  children: [
                    if (banner != null)
                      Padding(padding: const EdgeInsets.all(16), child: banner),
                    Expanded(child: Center(child: play)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Koba greeting the child, with "Hi, Arde!" when it fits whole: a bar too
/// narrow for it (a phone, with the map's buttons) leaves Koba alone, never
/// a cut-off "Hi...". The child's emblem is on Koba's ship, on the map.
class _Greeting extends StatelessWidget {
  const _Greeting({required this.words});

  final String words;

  /// Koba's picture has room around its head, so it is drawn bigger than
  /// the bar's buttons' icons to look their size.
  static const _koba = 56.0;
  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final text = TextPainter(
        text: TextSpan(text: words, style: DefaultTextStyle.of(context).style),
        maxLines: 1,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final fits = _koba + _gap + text.width <= constraints.maxWidth;
      text.dispose();
      return Row(
        children: [
          // Koba greets the child and watches where they tap.
          const KobaHead.follow(size: _koba),
          if (fits) ...[
            const SizedBox(width: _gap),
            Flexible(child: Text(words, maxLines: 1, softWrap: false)),
          ],
        ],
      );
    },
  );
}

/// Opens the story shelf, to watch Koba's story again (⧉, like "Watch how"
/// on a planet).
class _StoryButton extends StatelessWidget {
  const _StoryButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: GamepadShortcut(
      button: PadButton.view,
      onPressed: onPressed,
      child: IconButton.filledTonal(
        tooltip: AppLocalizations.of(context).storyTitle,
        style: IconButton.styleFrom(minimumSize: const Size(64, 64)),
        onPressed: onPressed,
        // Gold, like the story's stars, so it isn't taken for the stickers.
        icon: const Icon(
          Icons.theaters_rounded,
          size: 32,
          color: Color(0xFFFFC83D),
        ),
      ),
    ),
  );
}

/// Opens the sticker book; a badge counts stickers not seen yet.
class _StickerButton extends StatelessWidget {
  const _StickerButton({required this.fresh, required this.onPressed});

  final int fresh;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => GamepadShortcut(
    button: PadButton.y,
    onPressed: onPressed,
    // The top right carries the count of new stickers.
    badgeOnLeft: true,
    child: IconButton.filledTonal(
      tooltip: AppLocalizations.of(context).stickerBook,
      style: IconButton.styleFrom(minimumSize: const Size(64, 64)),
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: fresh > 0,
        label: Text('$fresh'),
        backgroundColor: const Color(0xFFFF7A59),
        child: const Icon(Icons.collections_bookmark_rounded, size: 32),
      ),
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
            // White on the starry sky, like the planets' names.
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
              shadows: const [Shadow(color: Color(0xAA0B0D2A), blurRadius: 6)],
            ),
          ),
          const SizedBox(height: 32),
          GamepadShortcut(
            button: PadButton.x,
            onPressed: onStart,
            child: FilledButton.icon(
              icon: const Icon(Icons.play_arrow_rounded, size: 48),
              label: Text(l10n.pretestStart),
              onPressed: onStart,
            ),
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
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.diamond_rounded, size: 48, color: Color(0xFF26C6DA)),
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
    );
    if (MediaQuery.highContrastOf(context)) {
      return GlassSurface(tint: const Color(0xFFFFF3C4), child: content);
    }
    // Liquid glass floating over the sea, sized to its words, with a
    // warm gold tint for the bonus.
    return LiquidGlassLens(
      style: const LiquidGlassStyle(
        shape: LiquidGlassShape.continuousRoundedRectangle(
          cornerRadius: 28,
          borderWidth: 1.2,
        ),
        appearance: LiquidGlassAppearance(
          color: Color(0x66FFF3C4),
          blur: LiquidGlassBlur(sigmaX: 6, sigmaY: 6),
        ),
        refraction: LiquidGlassRefraction(
          distortion: 0.18,
          distortionWidth: 28,
          chromaticAberration: 0.004,
        ),
      ),
      child: content,
    );
  }
}

/// Plays the opening of a newly reached island once: a cheer while the map
/// animates it (after Koba's ship [flies] there), then it is marked as
/// celebrated. Otherwise it opens the [story] scene's route, if one is due,
/// once the map is on top.
class _CelebrationTrigger extends StatefulWidget {
  const _CelebrationTrigger({
    required this.island,
    required this.flies,
    required this.story,
    required this.child,
  });

  final String? island;
  final bool flies;
  final String? story;
  final Widget child;

  @override
  State<_CelebrationTrigger> createState() => _CelebrationTriggerState();
}

class _CelebrationTriggerState extends State<_CelebrationTrigger> {
  Timer? _done;
  late final LearningCubit _learning;

  /// The scene this map opened, so it opens once.
  String? _openedStory;

  @override
  void initState() {
    super.initState();
    _learning = context.read<LearningCubit>();
    _celebrate();
  }

  /// Starts the celebration of [_CelebrationTrigger.island], once it is set.
  void _celebrate() {
    if (widget.island == null || _done != null) return;
    // The ship's flight has its own sounds, ending in the cheer.
    if (!widget.flies) {
      context.read<AudioService>().playEffect(SoundEffect.goal);
    }
    _done = Timer(
      const Duration(milliseconds: 2400) +
          (widget.flies ? ShipFlight.duration : Duration.zero),
      () {
        _done = null;
        _learning.celebrated();
      },
    );
  }

  // The map is built under the screens opened from it (the first warm-up
  // among them), so a scene can become due while it is hidden: it opens when
  // the map is on top again.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _openStory();
  }

  @override
  void didUpdateWidget(_CelebrationTrigger oldWidget) {
    super.didUpdateWidget(oldWidget);
    _celebrate();
    _openStory();
  }

  void _openStory() {
    final story = widget.story;
    if (widget.island != null || story == null || story == _openedStory) {
      return;
    }
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    _openedStory = story;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) GoRouter.maybeOf(context)?.go(story);
    });
  }

  @override
  void dispose() {
    // Leaving the map before it ends still counts as celebrated, so the
    // next puzzle doesn't send the child back to the map.
    if (_done != null) {
      _done!.cancel();
      _learning.celebrated();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
