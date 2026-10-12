// Generates the game's sound effects with ElevenLabs' sound-effects model.
//
//   dart run tool/generate_sfx.dart              # generate missing effects
//   dart run tool/generate_sfx.dart --force      # regenerate all effects
//   dart run tool/generate_sfx.dart --only star,goal
//
// Prompts live in tool/sound_effects.json; names match SoundEffect. An
// effect with "slice" keeps only that many seconds of the generated sound,
// its steadiest stretch, faded in and out, so a steady sound (Koba rolling)
// lasts exactly as long as its animation and sounds the same every time; "gain_db" then
// sets its loudness against the others. Uses the
// same API key as tool/generate_voice.dart (.env or ELEVENLABS_API_KEY).
// Needs ffmpeg.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

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
      final slice = (spec['slice'] as num?)?.toDouble();
      final gain = (spec['gain_db'] as num?)?.toDouble() ?? 0;
      if (slice == null && gain == 0) {
        await normalizeAudio(raw.path, out.path);
      } else {
        final even = File('${temp.path}/${effect.name}-even.wav');
        await normalizeAudio(raw.path, even.path);
        await _shape(even, out, slice: slice, gain: gain);
      }
      stdout.writeln('✓ ${out.path}');
    } on Object catch (e) {
      failed++;
      stderr.writeln('✗ ${effect.name}: $e');
    }
  }
  temp.deleteSync(recursive: true);
  if (failed > 0) exitCode = 1;
}

/// Cuts [slice] seconds from [input], where its loudness changes least, with
/// short fades (or
/// keeps it whole), and changes its loudness by [gain] dB.
Future<void> _shape(
  File input,
  File out, {
  required double? slice,
  required double gain,
}) async {
  final probe = await Process.run('ffprobe', [
    '-v',
    'error',
    '-show_entries',
    'format=duration',
    '-of',
    'csv=p=0',
    input.path,
  ]);
  final length = double.parse('${probe.stdout}'.trim());
  final keep = slice ?? length;
  final start = slice == null ? 0.0 : await _steadiest(input, keep);
  await runChecked('ffmpeg', [
    '-y',
    '-loglevel',
    'error',
    '-i',
    input.path,
    '-af',
    // Cut by samples (seeking into compressed audio can start on silence).
    'atrim=start=$start:duration=$keep,asetpts=PTS-STARTPTS,'
        'afade=t=in:d=0.02,afade=t=out:st=${keep - 0.03}:d=0.03,'
        'volume=${gain}dB',
    '-ac',
    '1',
    '-ar',
    '22050',
    '-b:a',
    '64k',
    out.path,
  ]);
}

/// Where in [input] a stretch of [seconds] is steadiest: its loudness, in
/// chunks of 1/20 s, spreads least, among stretches no quieter than 12 dB
/// below the loudest.
Future<double> _steadiest(File input, double seconds) async {
  const chunk = 0.05;
  final result = await Process.run('ffmpeg', [
    '-hide_banner',
    '-i',
    input.path,
    '-af',
    'asetnsamples=n=${(22050 * chunk).round()},'
        'astats=metadata=1:reset=1,'
        'ametadata=print:key=lavfi.astats.Overall.RMS_level',
    '-f',
    'null',
    '-',
  ]);
  final levels = [
    for (final m in RegExp(
      r'RMS_level=(-?[\d.]+|-inf)',
    ).allMatches('${result.stderr}'))
      m.group(1) == '-inf' ? -120.0 : double.parse(m.group(1)!),
  ];
  final span = (seconds / chunk).round();
  if (levels.length <= span) return 0;
  final loudest = levels.reduce(max);
  var best = 0;
  var bestSpread = double.infinity;
  for (var i = 0; i + span <= levels.length; i++) {
    final window = levels.sublist(i, i + span);
    final spread = window.reduce(max) - window.reduce(min);
    if (window.reduce(min) < loudest - 12 || spread >= bestSpread) continue;
    best = i;
    bestSpread = spread;
  }
  return best * chunk;
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
