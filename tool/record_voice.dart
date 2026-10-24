// Records a native speaker reading the voice clips, for languages that
// ElevenLabs can't speak (Acehnese, Minangkabau, Sundanese). generate_voice.dart then
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
// Or a speaker records on their phone, one file per line named by its
// number (001.m4a, 002.m4a…), from a script sheet:
//
//   dart run tool/record_voice.dart --lang ace --sheet  # build/recording_scripts/ace.txt
//   dart run tool/record_voice.dart --lang ace --import ~/Downloads/aceh
//
// Recordings go to the git-ignored recordings/<lang>/<clipId>.wav: they are
// the speaker's own voice, so they never enter the repo. Needs ffmpeg.
import 'dart:io';

import 'package:cobalagi/core/audio/voice_clips.dart';
import 'package:cobalagi/core/settings/app_language.dart';

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
  if (args.contains('--sheet')) return _writeSheet(language);
  if (_option(args, '--import') case final String folder) {
    return _import(language, Directory(folder));
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

/// The lines in a stable order: a line's number on the script sheet is its
/// place here, so the sheet and the import agree while the clips don't change.
List<String> get _numbered => VoiceClips.all.keys.toList();

String _number(int i) => '${i + 1}'.padLeft(3, '0');

/// A plain-text script for a speaker recording on their phone, in
/// Indonesian, since every speaker of a regional language reads it.
void _writeSheet(String language) {
  final strings = loadStrings(language);
  final indonesian = loadStrings('id');
  final name = AppLanguage.of(language)?.name ?? language;
  final out = File('build/recording_scripts/$language.txt');
  final sheet = StringBuffer()
    ..writeln('Naskah rekaman Coba Lagi: $name (${_numbered.length} baris)')
    ..writeln()
    ..writeln('Terima kasih sudah membantu! Suaramu akan diubah menjadi suara')
    ..writeln(
      'Koba (robot kecil yang ramah) atau pencerita di aplikasi Coba Lagi,',
    )
    ..writeln('aplikasi belajar coding untuk anak. Pengucapanmu yang dipakai,')
    ..writeln('jadi bacalah seperti bicara biasa sehari-hari.')
    ..writeln()
    ..writeln('Cara merekam:')
    ..writeln('- Satu file untuk satu baris, beri nama dengan nomornya:')
    ..writeln('  001, 002, 003, … (aplikasi perekam suara apa saja boleh).')
    ..writeln('- Baca hanya kalimatnya saja, tanpa nomor atau nama pembicara.')
    ..writeln(
      '- Di ruangan yang tenang, ponsel kira-kira sejengkal dari mulut.',
    )
    ..writeln('- KOBA: ceria, ramah, seperti mengajak anak kecil bermain.')
    ..writeln('  NARATOR: tenang dan hangat, seperti membacakan cerita.')
    ..writeln('- Ada yang salah? Rekam ulang saja dengan nomor yang sama.')
    ..writeln('- Kalimat yang terasa kaku boleh diucapkan lebih alami,')
    ..writeln(
      '  asal artinya sama; catat nomornya supaya teksnya ikut diubah.',
    );
  for (final (i, id) in _numbered.indexed) {
    final arbKey = VoiceClips.all[id]!;
    final speaker = VoiceClips.speakerOf(id) == Speaker.koba
        ? 'KOBA'
        : 'NARATOR';
    sheet
      ..writeln()
      ..writeln('${_number(i)}  $speaker')
      ..writeln('     ${strings[arbKey]}')
      ..writeln('     (artinya: ${indonesian[arbKey]})');
  }
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(sheet.toString());
  stdout.writeln('Wrote ${out.path}. Send it to the speaker.');
}

/// Turns phone recordings named by their number into `recordings/<lang>/`.
Future<void> _import(String language, Directory folder) async {
  final numbered = _numbered;
  var imported = 0;
  for (final file in folder.listSync().whereType<File>()) {
    final name = file.uri.pathSegments.last;
    final number = int.tryParse(RegExp(r'^\d+').stringMatch(name) ?? '');
    if (number == null || number < 1 || number > numbered.length) {
      stderr.writeln(
        'Skipped $name: no line number from 1 to ${numbered.length}.',
      );
      continue;
    }
    final out = recordingFile(language, numbered[number - 1]);
    out.parent.createSync(recursive: true);
    await runChecked('ffmpeg', [
      '-y',
      '-loglevel',
      'error',
      '-i',
      file.path,
      '-ac',
      '1',
      '-ar',
      '44100',
      out.path,
    ]);
    imported++;
  }
  stdout.writeln(
    'Imported $imported recordings into recordings/$language/. Make the '
    'clips with: dart run tool/generate_voice.dart --lang $language',
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
