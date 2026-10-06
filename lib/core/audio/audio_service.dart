import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'music.dart';
import 'sound_effects.dart';

/// Plays prerecorded voice clips from `assets/audio/<languageCode>/<clipId>.mp3`.
/// Clip ids are listed in `VoiceClips`.
abstract interface class AudioService {
  /// Missing clips are skipped silently, so screens can request clips before
  /// they are recorded. A clip interrupts whatever is playing, unless [queue]
  /// is true, in which case it plays after it.
  Future<void> playVoice(
    String clipId, {
    required String languageCode,
    bool queue = false,
  });

  /// Completes once the current clip and everything queued after it have
  /// finished, so a screen can wait before moving on and cutting a clip off.
  Future<void> whenIdle();

  /// Plays a short sound over any voice. Ignored while [effectsOn] is false;
  /// missing sounds are skipped silently.
  void playEffect(SoundEffect effect);

  /// Sound effects on or off (a parent setting). Voices always play.
  bool get effectsOn;
  set effectsOn(bool on);

  /// Background music on or off (a parent setting). While on, the theme loops
  /// quietly whenever the app is in the foreground, softer while a voice
  /// speaks.
  bool get musicOn;
  set musicOn(bool on);

  /// Whether the app is visible; music pauses in the background.
  set foreground(bool visible);

  Future<void> dispose();
}

class AudioplayersAudioService implements AudioService {
  AudioplayersAudioService({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle {
    _done = _voice.onPlayerComplete.listen((_) => _playNext());
  }

  final AssetBundle _bundle;
  final _voice = AudioPlayer();
  late final StreamSubscription<void> _done;
  final _queue = <String>[];
  var _playing = false;
  final _idleWaiters = <Completer<void>>[];
  Set<String>? _assets;

  /// A few players, so quick steps can overlap without cutting each other.
  final _effects = List.generate(3, (_) => AudioPlayer());
  var _nextEffect = 0;
  final _music = AudioPlayer();
  var _musicStarted = false;
  var _musicOn = false;
  var _foreground = true;

  /// Effects and music mix in without taking audio focus from the voice.
  static final _mixing = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();
  var _contextsSet = false;

  static const _musicVolume = 0.22;
  static const _musicUnderVoice = 0.08;

  @override
  var effectsOn = true;

  @override
  bool get musicOn => _musicOn;

  @override
  set musicOn(bool on) {
    _musicOn = on;
    unawaited(_updateMusic());
  }

  @override
  set foreground(bool visible) {
    _foreground = visible;
    unawaited(_updateMusic());
  }

  Future<void> _setContexts() async {
    if (_contextsSet) return;
    _contextsSet = true;
    try {
      for (final player in [..._effects, _music]) {
        await player.setAudioContext(_mixing);
      }
    } on Object {
      // Not every platform supports audio contexts; mixing is a nicety.
    }
  }

  Future<void> _updateMusic() async {
    try {
      if (!_musicOn || !_foreground) {
        if (_musicStarted) await _music.pause();
        return;
      }
      if (_musicStarted) {
        await _music.resume();
        return;
      }
      if (!await _hasAsset(MusicTrack.theme.asset)) return;
      await _setContexts();
      _musicStarted = true;
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.play(
        AssetSource(MusicTrack.theme.asset),
        volume: _playing ? _musicUnderVoice : _musicVolume,
      );
    } on Object {
      // Music that can't play must never break the game.
    }
  }

  void _duck({required bool underVoice}) {
    if (!_musicStarted) return;
    unawaited(
      _music
          .setVolume(underVoice ? _musicUnderVoice : _musicVolume)
          .catchError((Object _) {}),
    );
  }

  Future<bool> _hasAsset(String path) async {
    _assets ??= (await AssetManifest.loadFromAssetBundle(
      _bundle,
    )).listAssets().toSet();
    return _assets!.contains('assets/$path');
  }

  @override
  void playEffect(SoundEffect effect) {
    if (!effectsOn) return;
    unawaited(_playEffect(effect));
  }

  Future<void> _playEffect(SoundEffect effect) async {
    if (!await _hasAsset(effect.asset)) return;
    await _setContexts();
    final player = _effects[_nextEffect];
    _nextEffect = (_nextEffect + 1) % _effects.length;
    try {
      await player.stop();
      await player.play(AssetSource(effect.asset), volume: 0.6);
    } on Object {
      // A sound that can't play must never break the game.
    }
  }

  @override
  Future<void> whenIdle() {
    if (!_playing && _queue.isEmpty) return Future.value();
    final waiter = Completer<void>();
    _idleWaiters.add(waiter);
    return waiter.future;
  }

  void _notifyIdle() {
    for (final waiter in _idleWaiters) {
      waiter.complete();
    }
    _idleWaiters.clear();
  }

  @override
  Future<void> playVoice(
    String clipId, {
    required String languageCode,
    bool queue = false,
  }) async {
    final path = 'audio/$languageCode/$clipId.mp3';
    if (!await _hasAsset(path)) return;
    if (queue && _playing) {
      _queue.add(path);
      return;
    }
    _queue.clear();
    await _start(path);
  }

  Future<void> _start(String path) async {
    _playing = true;
    _duck(underVoice: true);
    try {
      await _voice.stop();
      await _voice.play(AssetSource(path));
    } on Object {
      // A clip that can't play must never break the game.
      _playNext();
    }
  }

  void _playNext() {
    _playing = false;
    if (_queue.isNotEmpty) {
      _start(_queue.removeAt(0));
    } else {
      _duck(underVoice: false);
      _notifyIdle();
    }
  }

  @override
  Future<void> dispose() async {
    _notifyIdle();
    await _done.cancel();
    await _voice.dispose();
    for (final player in [..._effects, _music]) {
      await player.dispose();
    }
  }
}

class SilentAudioService implements AudioService {
  const SilentAudioService();

  @override
  Future<void> playVoice(
    String clipId, {
    required String languageCode,
    bool queue = false,
  }) async {}

  @override
  Future<void> whenIdle() async {}

  @override
  void playEffect(SoundEffect effect) {}

  @override
  bool get effectsOn => false;

  @override
  set effectsOn(bool on) {}

  @override
  bool get musicOn => false;

  @override
  set musicOn(bool on) {}

  @override
  set foreground(bool visible) {}

  @override
  Future<void> dispose() async {}
}
