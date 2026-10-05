import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Plays prerecorded voice clips from `assets/audio/<languageCode>/<clipId>.mp3`.
abstract interface class AudioService {
  /// Missing clips are skipped silently, so screens can request clips before
  /// they are recorded.
  Future<void> playVoice(String clipId, {required String languageCode});

  Future<void> dispose();
}

class AudioplayersAudioService implements AudioService {
  AudioplayersAudioService({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final _voice = AudioPlayer();
  Set<String>? _assets;

  @override
  Future<void> playVoice(String clipId, {required String languageCode}) async {
    final path = 'audio/$languageCode/$clipId.mp3';
    _assets ??= (await AssetManifest.loadFromAssetBundle(
      _bundle,
    )).listAssets().toSet();
    if (!_assets!.contains('assets/$path')) return;
    await _voice.stop();
    await _voice.play(AssetSource(path));
  }

  @override
  Future<void> dispose() => _voice.dispose();
}

class SilentAudioService implements AudioService {
  const SilentAudioService();

  @override
  Future<void> playVoice(String clipId, {required String languageCode}) async {}

  @override
  Future<void> dispose() async {}
}
