// Fills assets/audio/ with TEST voice clips spoken by the macOS voices, so the
// voice flow can be tried in the app before real recordings exist.
//
// Apple's license does not cover shipping these voices in an app: never
// release with them. They are git-ignored, and assets/audio/TEST_VOICES marks
// that they are present.
//
//   dart run tool/test_voices.dart          # create missing clips
//   dart run tool/test_voices.dart --force  # recreate all clips
//   dart run tool/test_voices.dart --clean  # delete all test clips
//
// Needs macOS (`say`) and ffmpeg.
import 'dart:convert';
import 'dart:io';

import 'package:cobalagi/core/audio/voice_clips.dart';

/// Voice and speaking rate (words per minute) per language; a little slower
/// than the default for young children.
const voices = {'id': ('Damayanti', 160), 'en': ('Flo (English (US))', 165)};

final marker = File('assets/audio/TEST_VOICES');

Future<void> main(List<String> args) async {
  if (args.contains('--clean')) {
    var removed = 0;
    for (final language in voices.keys) {
      for (final id in VoiceClips.all.keys) {
        final file = File('assets/audio/$language/$id.mp3');
        if (file.existsSync()) {
          file.deleteSync();
          removed++;
        }
      }
    }
    if (marker.existsSync()) marker.deleteSync();
    stdout.writeln('Removed $removed test clips.');
    return;
  }
  if (!Platform.isMacOS) {
    stderr.writeln('This tool needs macOS for the `say` voices.');
    exitCode = 69;
    return;
  }
  final force = args.contains('--force');
  final temp = Directory.systemTemp.createTempSync('voices');
  var made = 0;
  for (final MapEntry(key: language, value: (voice, rate)) in voices.entries) {
    final strings =
        jsonDecode(File('lib/app/l10n/app_$language.arb').readAsStringSync())
            as Map<String, Object?>;
    for (final MapEntry(key: id, value: arbKey) in VoiceClips.all.entries) {
      final out = File('assets/audio/$language/$id.mp3');
      if (out.existsSync() && !force) continue;
      final text = strings[arbKey]! as String;
      final aiff = '${temp.path}/$id.aiff';
      await _run('say', ['-v', voice, '-r', '$rate', '-o', aiff, text]);
      // Trim silence at both ends, even out loudness, small mono MP3.
      await _run('ffmpeg', [
        '-y',
        '-loglevel',
        'error',
        '-i',
        aiff,
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
        out.path,
      ]);
      made++;
    }
  }
  temp.deleteSync(recursive: true);
  marker.writeAsStringSync(
    'assets/audio/ holds TEST voices from macOS `say`. Do not release.\n'
    'Remove with: dart run tool/test_voices.dart --clean\n',
  );
  stdout.writeln('Created $made test clips.');
}

Future<void> _run(String command, List<String> args) async {
  final result = await Process.run(command, args);
  if (result.exitCode != 0) {
    throw ProcessException(command, args, '${result.stderr}', result.exitCode);
  }
}
