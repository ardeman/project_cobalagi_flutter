// Shared helpers for the voice-over tools. Pure Dart plus ffmpeg.
import 'dart:convert';
import 'dart:io';

/// Present while assets/audio/ holds macOS test voices (tool/test_voices.dart).
final testVoicesMarker = File('assets/audio/TEST_VOICES');

File clipFile(String language, String clipId) =>
    File('assets/audio/$language/$clipId.mp3');

/// A native speaker's reading of a clip (tool/record_voice.dart), git-ignored.
File recordingFile(String language, String clipId) =>
    File('recordings/$language/$clipId.wav');

/// The ARB strings of [language], keyed by message name.
Map<String, Object?> loadStrings(String language) =>
    jsonDecode(File('lib/app/l10n/app_$language.arb').readAsStringSync())
        as Map<String, Object?>;

/// The MP3 voice format in `tool/elevenlabs.json` (`mp3_<sampleRate>_<kbps>`).
///
/// Clips are stored mono. One speaker has no stereo image, so a second
/// channel would spend half the bits on silence.
class VoiceFormat {
  const VoiceFormat({
    required this.name,
    required this.sampleRate,
    required this.bitrateKbps,
  });

  /// The ElevenLabs `output_format` string, such as `mp3_22050_32`.
  final String name;

  final int sampleRate;
  final int bitrateKbps;

  static final _pattern = RegExp(r'^mp3_(\d+)_(\d+)$');

  static VoiceFormat parse(String format) {
    final match = _pattern.firstMatch(format);
    if (match == null) {
      throw FormatException(
        'Unsupported output_format "$format". '
        'Voice clips use mp3_<sampleRate>_<kbps>.',
      );
    }
    return VoiceFormat(
      name: format,
      sampleRate: int.parse(match.group(1)!),
      bitrateKbps: int.parse(match.group(2)!),
    );
  }

  /// The format new clips are requested and stored in.
  static VoiceFormat load() {
    final config =
        jsonDecode(File('tool/elevenlabs.json').readAsStringSync())
            as Map<String, Object?>;
    final format = config['output_format'];
    if (format is! String) {
      throw const FormatException(
        'tool/elevenlabs.json needs a string output_format.',
      );
    }
    return parse(format);
  }
}

/// Language folders under `assets/audio/`. Sound effects and music keep
/// their own rates.
List<String> bundledVoiceLanguages() {
  const notVoice = {'sfx', 'music'};
  final languages = <String>[];
  for (final entity in Directory('assets/audio').listSync()) {
    if (entity is! Directory) continue;
    final name = entity.path.split(Platform.pathSeparator).last;
    if (!notVoice.contains(name)) languages.add(name);
  }
  languages.sort();
  return languages;
}

/// ffmpeg arguments for a mono CBR MP3, at LAME's highest quality for the
/// bitrate.
List<String> monoMp3Args({required int sampleRate, required int bitrateKbps}) =>
    [
      '-ac',
      '1',
      '-ar',
      '$sampleRate',
      '-c:a',
      'libmp3lame',
      '-compression_level',
      '0',
      '-b:a',
      '${bitrateKbps}k',
    ];

/// Trims silence at both ends and evens out loudness, writing a mono MP3,
/// so every clip sounds equally loud whatever made it.
///
/// [bitrateKbps] stays 64 for sound effects. Voice clips pass [VoiceFormat],
/// so a lower `output_format` is what gets stored.
Future<void> normalizeAudio(
  String input,
  String output, {
  int sampleRate = 22050,
  int bitrateKbps = 64,
}) => runChecked('ffmpeg', [
  '-y',
  '-loglevel',
  'error',
  '-i',
  input,
  '-af',
  'silenceremove=start_periods=1:start_threshold=-50dB,areverse,'
      'silenceremove=start_periods=1:start_threshold=-50dB,areverse,'
      'loudnorm=I=-16:TP=-1.5:LRA=11',
  ...monoMp3Args(sampleRate: sampleRate, bitrateKbps: bitrateKbps),
  output,
]);

/// Trims silence at both ends, keeping the recording's quality, so
/// speech-to-speech converts (and bills) only the spoken part.
Future<void> trimSilence(String input, String output) => runChecked('ffmpeg', [
  '-y',
  '-loglevel',
  'error',
  '-i',
  input,
  '-af',
  'silenceremove=start_periods=1:start_threshold=-50dB,areverse,'
      'silenceremove=start_periods=1:start_threshold=-50dB,areverse',
  output,
]);

Future<void> runChecked(String command, List<String> args) async {
  final result = await Process.run(command, args);
  if (result.exitCode != 0) {
    throw ProcessException(command, args, '${result.stderr}', result.exitCode);
  }
}

/// A setting from the environment, or else from the git-ignored `.env` file.
String? setting(String name) {
  final fromEnvironment = Platform.environment[name];
  if (fromEnvironment != null && fromEnvironment.isNotEmpty) {
    return fromEnvironment;
  }
  final file = File('.env');
  if (!file.existsSync()) return null;
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final eq = trimmed.indexOf('=');
    if (eq < 0 || trimmed.substring(0, eq).trim() != name) continue;
    var value = trimmed.substring(eq + 1).trim();
    if (value.length >= 2 &&
        (value.startsWith('"') && value.endsWith('"') ||
            value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }
    return value.isEmpty ? null : value;
  }
  return null;
}
