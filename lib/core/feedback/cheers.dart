import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/l10n/app_localizations.dart';
import '../audio/voice_clips.dart';

enum CheerMood {
  /// After a right answer or a solved puzzle.
  celebrate,

  /// After anything else. Always positive; never says "wrong".
  encourage,
}

/// One cheerful response: words, a picture and a matching voice clip.
final class Cheer {
  const Cheer({
    required this.text,
    required this.icon,
    required this.color,
    required this.clip,
  });

  final String text;
  final IconData icon;
  final Color color;

  /// Voice clip id, e.g. `cheer_celebrate_3`.
  final String clip;
}

const _icons = {
  CheerMood.celebrate: [
    (Icons.star_rounded, Color(0xFFFFC83D)),
    (Icons.emoji_events_rounded, Color(0xFFFFB300)),
    (Icons.rocket_launch_rounded, Color(0xFFFF7A59)),
    (Icons.auto_awesome_rounded, Color(0xFFAB47BC)),
    (Icons.celebration_rounded, Color(0xFFEC407A)),
    (Icons.favorite_rounded, Color(0xFFE53935)),
  ],
  CheerMood.encourage: [
    (Icons.thumb_up_rounded, Color(0xFF26A69A)),
    (Icons.sentiment_very_satisfied_rounded, Color(0xFFFFB300)),
    (Icons.wb_sunny_rounded, Color(0xFFFFA000)),
    (Icons.favorite_rounded, Color(0xFFEC407A)),
    (Icons.auto_awesome_rounded, Color(0xFF29B6F6)),
  ],
};

List<String> _texts(AppLocalizations l10n, CheerMood mood) => switch (mood) {
  CheerMood.celebrate => [
    l10n.cheerCelebrate1,
    l10n.cheerCelebrate2,
    l10n.cheerCelebrate3,
    l10n.cheerCelebrate4,
    l10n.cheerCelebrate5,
    l10n.cheerCelebrate6,
  ],
  CheerMood.encourage => [
    l10n.cheerEncourage1,
    l10n.cheerEncourage2,
    l10n.cheerEncourage3,
    l10n.cheerEncourage4,
    l10n.cheerEncourage5,
  ],
};

/// Picks varied cheers: random words and picture, never the same words twice
/// in a row.
class CheerPicker {
  CheerPicker([Random? random]) : _random = random ?? Random();

  final Random _random;
  final _last = <CheerMood, int>{};

  Cheer next(AppLocalizations l10n, CheerMood mood) {
    final texts = _texts(l10n, mood);
    var i = _random.nextInt(texts.length);
    if (i == _last[mood]) {
      i = (i + 1 + _random.nextInt(texts.length - 1)) % texts.length;
    }
    _last[mood] = i;
    final icons = _icons[mood]!;
    final (icon, color) = icons[_random.nextInt(icons.length)];
    return Cheer(
      text: texts[i],
      icon: icon,
      color: color,
      clip: VoiceClips.cheer(mood.name, i + 1),
    );
  }
}

/// A cheer that pops in with a little bounce and tilt.
class CheerBadge extends StatelessWidget {
  const CheerBadge({super.key, required this.cheer, required this.size});

  final Cheer cheer;
  final double size;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(cheer),
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 600),
    curve: Curves.elasticOut,
    builder: (context, t, child) => Transform.rotate(
      angle: (1 - t) * -0.4,
      child: Transform.scale(scale: 0.4 + 0.6 * t, child: child),
    ),
    child: Icon(cheer.icon, size: size, color: cheer.color),
  );
}
