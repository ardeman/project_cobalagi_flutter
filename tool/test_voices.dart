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
import 'dart:io';

import 'package:cobalagi/core/audio/voice_clips.dart';

import 'src/voice_files.dart';

/// Voice and speaking rate (words per minute) per language; a little slower
/// than the default for young children.
const voices = {'id': ('Damayanti', 160), 'en': ('Flo (English (US))', 165)};

Future<void> main(List<String> args) async {
  if (args.contains('--clean')) {
    var removed = 0;
    for (final language in voices.keys) {
      for (final id in VoiceClips.all.keys) {
        final file = clipFile(language, id);
        if (file.existsSync()) {
          file.deleteSync();
          removed++;
        }
      }
    }
    if (testVoicesMarker.existsSync()) testVoicesMarker.deleteSync();
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
    final strings = loadStrings(language);
    for (final MapEntry(key: id, value: arbKey) in VoiceClips.all.entries) {
      final out = clipFile(language, id);
      if (out.existsSync() && !force) continue;
      final text = strings[arbKey]! as String;
      final aiff = '${temp.path}/$id.aiff';
      await runChecked('say', ['-v', voice, '-r', '$rate', '-o', aiff, text]);
      await normalizeAudio(aiff, out.path);
      made++;
    }
  }
  temp.deleteSync(recursive: true);
  testVoicesMarker.writeAsStringSync(
    'assets/audio/ holds TEST voices from macOS `say`. Do not release.\n'
    'Remove with: dart run tool/test_voices.dart --clean\n',
  );
  stdout.writeln('Created $made test clips.');
}
