/// Short sounds for things that happen in play, at
/// `assets/audio/sfx/<name>.mp3`. They come from tool/generate_sfx.dart, whose
/// prompts live in tool/sound_effects.json under the same names.
enum SoundEffect {
  /// The actor walks one tile.
  step,

  /// The actor turns on the spot.
  turn,

  /// The actor walks into a tree or the edge.
  bump,

  /// The actor picks up a star.
  star,

  /// The puzzle is solved: the actor reached the flag.
  goal,

  /// A block lands in the program.
  drop;

  String get asset => 'audio/sfx/$name.mp3';
}
