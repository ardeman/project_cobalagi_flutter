import 'package:flutter/material.dart';
import 'package:cobalagi/core/widgets/centered_scroll_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/voice_clips.dart';
import '../../../core/responsive/window_class.dart';
import '../../../learning/stickers.dart';
import '../../../learning/warm_up/warm_up.dart';
import '../../learning/cubit/learning_cubit.dart';
import '../../learning/view/concepts.dart';
import '../../warm_up/view/warm_up_games.dart';
import 'sticker_view.dart';
import 'package:cobalagi/core/widgets/glass_app_bar.dart';

/// A child's sticker book: a sticker for every finished island and every
/// Warm-up game at three stars. Stickers earned since the last visit pop in.
class StickerBookScreen extends StatefulWidget {
  const StickerBookScreen({super.key, required this.profileId});

  final int profileId;

  @override
  State<StickerBookScreen> createState() => _StickerBookScreenState();
}

class _StickerBookScreenState extends State<StickerBookScreen> {
  /// The stickers that are new on this visit, kept while the book is open.
  Set<String>? _fresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AudioService>().playVoice(
        VoiceClips.stickerBook,
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
    final book = cubit.stickers;
    if (_fresh == null) {
      _fresh = newStickers(learner, book);
      // Seen from now on: next time they sit still in the book.
      if (_fresh!.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => cubit.markStickersSeen(_fresh!),
        );
      }
    }
    final fresh = _fresh!;
    final islands = [
      for (final s in book)
        if (s.game == null) s,
    ];
    final games = [
      for (final s in book)
        if (s.game != null) s,
    ];
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        leading: BackButton(
          onPressed: () => context.go('/child/${widget.profileId}'),
        ),
        title: Text(l10n.stickerBook),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: WindowClassBuilder(
          builder: (context, windowClass) {
            final size = windowClass == WindowClass.compact ? 88.0 : 112.0;
            Widget section(String title, List<Sticker> stickers) => Column(
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 24,
                  runSpacing: 20,
                  children: [
                    for (final (i, s) in stickers.indexed)
                      _Slot(
                        sticker: s,
                        size: size,
                        // Alternate tilts, like stuck on by hand.
                        tilt: (i.isEven ? 1 : -1) * (0.01 + (i % 3) * 0.012),
                        fresh: fresh.contains(s.id),
                      ),
                  ],
                ),
              ],
            );
            return CenteredScrollView(
              padding: belowBars(context, const EdgeInsets.all(24)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  children: [
                    section(l10n.stickersIslands, islands),
                    const SizedBox(height: 40),
                    section(conceptName(l10n, warmUpIsland), games),
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

class _Slot extends StatelessWidget {
  const _Slot({
    required this.sticker,
    required this.size,
    required this.tilt,
    required this.fresh,
  });

  final Sticker sticker;
  final double size;
  final double tilt;
  final bool fresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final game = sticker.game;
    final name = game == null
        ? conceptName(l10n, sticker.id)
        : game.label(l10n);
    return Semantics(
      label: sticker.earned ? name : '$name, ${l10n.stickerNotYet}',
      excludeSemantics: true,
      child: SizedBox(
        width: size * 1.35,
        child: Column(
          children: [
            StickerView(
              icon: game?.icon ?? conceptIcon(sticker.id),
              color: game?.color ?? conceptColor(sticker.id),
              earned: sticker.earned,
              size: size,
              tilt: tilt,
              fresh: fresh,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: sticker.earned
                    ? null
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
