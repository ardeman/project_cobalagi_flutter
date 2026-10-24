// Records a native speaker reading the voice clips, for languages that
// ElevenLabs can't speak (Acehnese, Minangkabau). generate_voice.dart then
// turns each recording into Koba's or the narrator's voice with ElevenLabs
// speech-to-speech, keeping the speaker's pronunciation.
//
// Run it in your own terminal (it asks for the microphone):
//
//   dart run tool/record_voice.dart --lang ace          # lines not recorded yet
//   dart run tool/record_voice.dart --lang ace --only cheer_celebrate_1
//   dart run tool/record_voice.dart --lang ace --redo   # every line again
//   dart run tool/record_voice.dart --lang ace --mic 1  # another microphone
//   dart run tool/record_voice.dart --mics              # list microphones
//
// Recordings go to the git-ignored recordings/<lang>/<clipId>.wav: they are
// the speaker's own voice, so they never enter the repo. Needs ffmpeg.
import 'dart:io';

import 'package:cobalagi/core/audio/voice_clips.dart';

import 'src/voice_files.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--mics')) {
    final result = await Process.run('ffmpeg', [
      '-hide_banner',
      '-f',
      'avfoundation',
      '-list_devices',
      'true',
      '-i',
      '',
    ]);
    final lines = '${result.stderr}'.split('\n');
    final audio = lines.indexWhere((l) => l.contains('audio devices'));
    for (final line in lines.skip(audio + 1)) {
      final at = line.indexOf('] [');
      if (at >= 0) stdout.writeln(line.substring(at + 2));
    }
    return;
  }
  final language = _option(args, '--lang');
  if (language == null) {
    stderr.writeln('Say which language: --lang ace');
    exitCode = 64;
    return;
  }
  final mic = _option(args, '--mic') ?? 'default';
  final only = _option(args, '--only')?.split(',').toSet();
  final redo = args.contains('--redo') || only != null;
  final strings = loadStrings(language);
  final indonesian = loadStrings('id');

  final todo = [
    for (final MapEntry(key: id, value: arbKey) in VoiceClips.all.entries)
      if ((only == null || only.contains(id)) &&
          (redo || !recordingFile(language, id).existsSync()))
        (
          id: id,
          text: strings[arbKey]! as String,
          indonesian: indonesian[arbKey],
        ),
  ];
  stdout.writeln(
    '${todo.length} lines to record. Enter starts, Enter stops; '
    'q quits (what is recorded is kept).\n',
  );
  for (final (i, clip) in todo.indexed) {
    final speaker = VoiceClips.speakerOf(clip.id).name;
    stdout
      ..writeln('── ${i + 1}/${todo.length}  ${clip.id}  ($speaker)')
      ..writeln('   ${clip.text}')
      ..writeln('   id: ${clip.indonesian}');
    final out = recordingFile(language, clip.id);
    while (true) {
      stdout.write('   [Enter] record  [s] skip  [q] quit: ');
      final start = stdin.readLineSync()?.trim();
      if (start == 'q' || start == null) return;
      if (start == 's') break;
      await _record(mic, out);
      stdout.write('   [Enter] next  [p] play  [r] again  [q] quit: ');
      var answer = stdin.readLineSync()?.trim();
      while (answer == 'p') {
        await Process.run('afplay', [out.path]);
        stdout.write('   [Enter] next  [p] play  [r] again  [q] quit: ');
        answer = stdin.readLineSync()?.trim();
      }
      if (answer == 'q' || answer == null) return;
      if (answer != 'r') break;
    }
  }
  stdout.writeln(
    'Done. Make the clips with: dart run tool/generate_voice.dart --lang $language',
  );
}

Future<void> _record(String mic, File out) async {
  out.parent.createSync(recursive: true);
  final ffmpeg = await Process.start('ffmpeg', [
    '-y',
    '-loglevel',
    'error',
    '-f',
    'avfoundation',
    '-i',
    ':$mic',
    '-ac',
    '1',
    '-ar',
    '44100',
    out.path,
  ]);
  stdout.write('   ● recording… [Enter] stop ');
  stdin.readLineSync();
  ffmpeg.stdin.write('q');
  await ffmpeg.stdin.close();
  if (await ffmpeg.exitCode != 0) {
    stderr.writeln(
      await ffmpeg.stderr.transform(systemEncoding.decoder).join(),
    );
  }
}

String? _option(List<String> args, String name) {
  final i = args.indexOf(name);
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
}
