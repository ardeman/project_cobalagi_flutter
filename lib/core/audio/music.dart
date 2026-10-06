/// Background music at `assets/audio/music/<name>.mp3`, made by
/// tool/generate_music.dart from the prompts in tool/music.json.
enum MusicTrack {
  /// Plays, looped, while the app is open.
  theme;

  String get asset => 'audio/music/$name.mp3';
}
