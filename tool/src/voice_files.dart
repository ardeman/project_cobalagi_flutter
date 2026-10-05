// Shared helpers for the voice-over tools. Pure Dart plus ffmpeg.
import 'dart:convert';
import 'dart:io';

/// Present while assets/audio/ holds macOS test voices (tool/test_voices.dart).
final testVoicesMarker = File('assets/audio/TEST_VOICES');

File clipFile(String language, String clipId) =>
    File('assets/audio/$language/$clipId.mp3');

/// The ARB strings of [language], keyed by message name.
Map<String, Object?> loadStrings(String language) =>
    jsonDecode(File('lib/app/l10n/app_$language.arb').readAsStringSync())
        as Map<String, Object?>;

/// Trims silence at both ends and evens out loudness, writing a small mono
/// MP3, so every clip sounds equally loud whatever made it.
Future<void> normalizeAudio(String input, String output) =>
    runChecked('ffmpeg', [
      '-y',
      '-loglevel',
      'error',
      '-i',
      input,
      '-af',
      'silenceremove=start_periods=1:start_threshold=-50dB,areverse,'
          'silenceremove=start_periods=1:start_threshold=-50dB,areverse,'
          'loudnorm=I=-16:TP=-1.5:LRA=11',
      '-ac',
      '1',
      '-ar',
      '22050',
      '-b:a',
      '64k',
      output,
    ]);

Future<void> runChecked(String command, List<String> args) async {
  final result = await Process.run(command, args);
  if (result.exitCode != 0) {
    throw ProcessException(command, args, '${result.stderr}', result.exitCode);
  }
}
