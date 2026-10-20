import 'package:flutter/painting.dart';

import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/audio/sound_effects.dart';
import 'package:cobalagi/features/story/data/story_art.dart';

/// One line of a story scene: a voice clip with its words, and how long the
/// pictures take to play it out. The next beat waits for the clip to end.
final class StoryBeat {
  const StoryBeat({
    required this.clip,
    required this.words,
    required this.length,
    this.effects = const [],
  });

  /// A `VoiceClips` id.
  final String clip;

  /// The clip's words, shown under the scene.
  final String Function(AppLocalizations l10n) words;
  final Duration length;

  /// Sounds to play, by when in the beat (0 to 1).
  final List<(double, SoundEffect)> effects;
}

/// Where a scene is: the beat playing, how far through its pictures (0 to
/// 1, held at 1 while the voice finishes) and the seconds since the scene
/// began, for things that keep moving (twinkles, blinks, bobbing).
final class StoryFrame {
  const StoryFrame({required this.beat, required this.t, required this.time});

  final int beat;
  final double t;
  final double time;
}

/// A scene of the Star fuel story, played by `StoryPlayer`: its beats, and
/// how to paint any moment of them. Painting is a pure function of the
/// frame, so a scene can be shown still (reduced motion) at each beat's end.
abstract class StoryScene {
  const StoryScene();

  /// Saved in `LearnerState.tutorialsSeen` once played (see `Story`).
  String get id;

  List<StoryBeat> get beats;

  /// Paints [frame] in [stage], the room the scene's action has; the night
  /// sky behind it is already painted. Without [art] (still loading) the
  /// pictures are left out.
  void paint(Canvas canvas, Rect stage, StoryFrame frame, StoryArt? art);
}
