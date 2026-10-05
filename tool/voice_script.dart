// Prints the voice-over recording script as CSV, one row per clip:
// id, file to record, words to say, and whether the file exists yet.
//
//   dart run tool/voice_script.dart [language]   # language: id (default) or en
import 'dart:convert';
import 'dart:io';

import 'package:cobalagi/core/audio/voice_clips.dart';

void main(List<String> args) {
  final language = args.isEmpty ? 'id' : args.first;
  final arb = File('lib/app/l10n/app_$language.arb');
  if (!arb.existsSync()) {
    stderr.writeln('No ARB file for "$language".');
    exitCode = 64;
    return;
  }
  final strings = jsonDecode(arb.readAsStringSync()) as Map<String, Object?>;
  String csv(String value) => '"${value.replaceAll('"', '""')}"';

  stdout.writeln('id,file,text,status');
  var missing = 0;
  for (final MapEntry(key: id, value: arbKey) in VoiceClips.all.entries) {
    final file = 'assets/audio/$language/$id.mp3';
    final recorded = File(file).existsSync();
    if (!recorded) missing++;
    final text = strings[arbKey] as String? ?? '';
    stdout.writeln(
      [id, file, csv(text), recorded ? 'recorded' : 'missing'].join(','),
    );
  }
  stderr.writeln('$missing of ${VoiceClips.all.length} clips missing.');
}
