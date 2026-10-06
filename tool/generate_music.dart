// Generates the background music with ElevenLabs Music.
//
//   dart run tool/generate_music.dart           # generate missing tracks
//   dart run tool/generate_music.dart --force   # regenerate all tracks
//
// Prompts live in tool/music.json; track names match MusicTrack. Uses the same
// API key as tool/generate_voice.dart (.env or ELEVENLABS_API_KEY), which needs
// the Music permission. Needs ffmpeg.
import 'dart:convert';
import 'dart:io';

import 'package:cobalagi/core/audio/music.dart';

import 'src/voice_files.dart';

Future<void> main(List<String> args) async {
  final key = setting('ELEVENLABS_API_KEY') ?? '';
  if (key.isEmpty) {
    stderr.writeln('Set ELEVENLABS_API_KEY in .env or the environment.');
    exitCode = 64;
    return;
  }
  final tracks =
      (jsonDecode(File('tool/music.json').readAsStringSync())
              as Map<String, Object?>)['tracks']!
          as Map<String, Object?>;
  final force = args.contains('--force');
  final temp = Directory.systemTemp.createTempSync('music');
  var failed = 0;
  for (final track in MusicTrack.values) {
    final out = File('assets/${track.asset}');
    if (out.existsSync() && !force) continue;
    final spec = tracks[track.name] as Map<String, Object?>?;
    if (spec == null) {
      stderr.writeln('✗ ${track.name}: no prompt in tool/music.json');
      failed++;
      continue;
    }
    try {
      final raw = File('${temp.path}/${track.name}.mp3');
      await _compose(key, {
        'prompt': spec['prompt'],
        'music_length_ms': (spec['seconds']! as int) * 1000,
        'force_instrumental': true,
      }, raw);
      out.parent.createSync(recursive: true);
      await _encode(raw.path, out.path);
      stdout.writeln('✓ ${out.path}');
    } on Object catch (e) {
      failed++;
      stderr.writeln('✗ ${track.name}: $e');
    }
  }
  temp.deleteSync(recursive: true);
  if (failed > 0) exitCode = 1;
}

/// Evens out loudness and fades both ends briefly, so the loop point is soft.
Future<void> _encode(String input, String output) => runChecked('ffmpeg', [
  '-y',
  '-loglevel',
  'error',
  '-i',
  input,
  '-af',
  'loudnorm=I=-20:TP=-2:LRA=11,afade=t=in:d=0.5,areverse,afade=t=in:d=1.5,areverse',
  '-ac',
  '2',
  '-ar',
  '44100',
  '-b:a',
  '96k',
  output,
]);

Future<void> _compose(String key, Map<String, Object?> body, File out) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
  try {
    final request = await client.postUrl(
      Uri.parse(
        'https://api.elevenlabs.io/v1/music?output_format=mp3_44100_128',
      ),
    );
    request.headers
      ..set('xi-api-key', key)
      ..contentType = ContentType.json;
    request.write(jsonEncode(body));
    final response = await request.close();
    if (response.statusCode != 200) {
      final message = await response.transform(utf8.decoder).join();
      throw HttpException('HTTP ${response.statusCode}: $message');
    }
    await response.pipe(out.openWrite());
  } finally {
    client.close();
  }
}
