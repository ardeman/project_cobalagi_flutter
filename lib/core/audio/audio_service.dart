import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

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
    _assets ??= (await AssetManifest.loadFromAssetBundle(
      _bundle,
    )).listAssets().toSet();
    if (!_assets!.contains('assets/$path')) return;
    if (queue && _playing) {
      _queue.add(path);
      return;
    }
    _queue.clear();
    await _start(path);
  }

  Future<void> _start(String path) async {
    _playing = true;
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
      _notifyIdle();
    }
  }

  @override
  Future<void> dispose() async {
    _notifyIdle();
    await _done.cancel();
    await _voice.dispose();
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
  Future<void> dispose() async {}
}
