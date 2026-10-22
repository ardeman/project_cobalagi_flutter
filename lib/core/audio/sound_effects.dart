/// Short sounds for things that happen in play, at
/// `assets/audio/sfx/<name>.mp3`. They come from tool/generate_sfx.dart, whose
/// prompts live in tool/sound_effects.json under the same names.
enum SoundEffect {
  /// The actor walks one tile.
  step,

  /// The actor turns on the spot.
  turn,

  /// The actor bumps into a rock, moon rock or asteroid (or the edge of a
  /// planet with those). Each bump sound matches what the obstacles are
  /// made of (`Obstacle.bumpSound`).
  bumpRock,

  /// The actor bumps into a plant, hedge or cactus.
  bumpPlant,

  /// The actor bumps into a crystal or an ice spike.
  bumpCrystal,

  /// The actor bumps into a wooden crate.
  bumpWood,

  /// The actor picks up a star.
  star,

  /// The puzzle is solved: the actor reached the flag.
  goal,

  /// A block lands in the program.
  drop,

  /// The child touches Koba on the board, and it shakes its head with a
  /// smile.
  poke,

  /// Koba's ship lifts off a planet, on the map or in a story scene.
  shipLaunch,

  /// Koba's ship flies through space.
  shipFly,

  /// Koba's ship touches down on a planet.
  shipLand,

  /// The space wind that blows the stars out of the ship's tank in the
  /// story.
  wind;

  String get asset => 'audio/sfx/$name.mp3';
}
