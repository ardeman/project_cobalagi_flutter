// Generates the game's sound effects with ElevenLabs' sound-effects model.
//
//   dart run tool/generate_sfx.dart              # generate missing effects
//   dart run tool/generate_sfx.dart --force      # regenerate all effects
//   dart run tool/generate_sfx.dart --only star,goal
//
// Prompts live in tool/sound_effects.json; names match SoundEffect. Uses the
// same API key as tool/generate_voice.dart (.env or ELEVENLABS_API_KEY).
// Needs ffmpeg.
import 'dart:convert';
import 'dart:io';

import 'package:cobalagi/core/audio/sound_effects.dart';

import 'src/voice_files.dart';

Future<void> main(List<String> args) async {
  final key = setting('ELEVENLABS_API_KEY') ?? '';
  if (key.isEmpty) {
    stderr.writeln('Set ELEVENLABS_API_KEY in .env or the environment.');
    exitCode = 64;
    return;
  }
  final config =
      jsonDecode(File('tool/sound_effects.json').readAsStringSync())
          as Map<String, Object?>;
  final effects = config['effects']! as Map<String, Object?>;
  final force = args.contains('--force');
  final i = args.indexOf('--only');
  final only = i >= 0 && i + 1 < args.length
      ? args[i + 1].split(',').toSet()
      : null;

  final temp = Directory.systemTemp.createTempSync('sfx');
  var failed = 0;
  for (final effect in SoundEffect.values) {
    if (only != null && !only.contains(effect.name)) continue;
    final out = File('assets/${effect.asset}');
    if (out.existsSync() && !force && only == null) continue;
    final spec = effects[effect.name] as Map<String, Object?>?;
    if (spec == null) {
      stderr.writeln('✗ ${effect.name}: no prompt in tool/sound_effects.json');
      failed++;
      continue;
    }
    try {
      final raw = File('${temp.path}/${effect.name}.mp3');
      await _generate(key, {
        'text': spec['text'],
        'duration_seconds': spec['seconds'],
        'prompt_influence': config['prompt_influence'],
      }, raw);
      out.parent.createSync(recursive: true);
      await normalizeAudio(raw.path, out.path);
      stdout.writeln('✓ ${out.path}');
    } on Object catch (e) {
      failed++;
      stderr.writeln('✗ ${effect.name}: $e');
    }
  }
  temp.deleteSync(recursive: true);
  if (failed > 0) exitCode = 1;
}

Future<void> _generate(String key, Map<String, Object?> body, File out) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(
      Uri.parse('https://api.elevenlabs.io/v1/sound-generation'),
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
