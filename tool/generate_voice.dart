// Generates the app's voice clips with ElevenLabs text-to-speech.
//
// Put your API key in .env (git-ignored; copy .env.example), or export
// ELEVENLABS_API_KEY in the terminal, which takes priority.
//
//   dart run tool/generate_voice.dart --voices          # list your voices
//   dart run tool/generate_voice.dart --sample          # audition sample lines
//   dart run tool/generate_voice.dart                   # generate missing clips
//   dart run tool/generate_voice.dart --force           # regenerate all clips
//   dart run tool/generate_voice.dart --only cheer_celebrate_1,play_goal
//   dart run tool/generate_voice.dart --lang id         # one language only
//   dart run tool/generate_voice.dart --dry-run         # show what would be sent
//
// Voices, model and settings live in tool/elevenlabs.json. Shipping the clips
// needs an ElevenLabs plan with a commercial license (not the free plan).
// Needs ffmpeg.
import 'dart:convert';
import 'dart:io';

import 'package:cobalagi/core/audio/voice_clips.dart';

import 'src/voice_files.dart';

const _api = 'https://api.elevenlabs.io/v1';

/// A few lines covering a question, a cheer and an instruction.
const _sampleClips = [
  VoiceClips.pretestWelcome,
  VoiceClips.playGoalLoops,
  'cheer_celebrate_1',
  'cheer_encourage_2',
  VoiceClips.decisionReview,
];

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final key = setting('ELEVENLABS_API_KEY') ?? '';
  if (key.isEmpty && !dryRun) {
    stderr.writeln(
      'Set ELEVENLABS_API_KEY in .env (copy .env.example) or the environment.',
    );
    exitCode = 64;
    return;
  }
  if (args.contains('--voices')) return _listVoices(key);

  final config =
      jsonDecode(File('tool/elevenlabs.json').readAsStringSync())
          as Map<String, Object?>;
  final voices = config['voices']! as Map<String, Object?>;
  final languages = switch (_option(args, '--lang')) {
    final String one => [one],
    null => voices.keys.toList(),
  };
  final sample = args.contains('--sample');
  final only = _option(args, '--only')?.split(',').toSet();
  // Clips made by test_voices.dart are placeholders: replace them all.
  final replaceTestVoices = testVoicesMarker.existsSync() && !sample;
  final force = args.contains('--force') || replaceTestVoices;

  final temp = Directory.systemTemp.createTempSync('elevenlabs');
  var made = 0;
  var failed = 0;
  for (final language in languages) {
    final voice = voices[language] as Map<String, Object?>?;
    final voiceId = voice?['voice_id'] as String? ?? '';
    if (voiceId.isEmpty) {
      stderr.writeln(
        'No voice_id for "$language" in tool/elevenlabs.json. '
        'Pick one with --voices.',
      );
      exitCode = 64;
      return;
    }
    final strings = loadStrings(language);
    for (final MapEntry(key: id, value: arbKey) in VoiceClips.all.entries) {
      if (sample && !_sampleClips.contains(id)) continue;
      if (only != null && !only.contains(id)) continue;
      final out = sample
          ? File('build/voice_samples/$language/$id.mp3')
          : clipFile(language, id);
      if (out.existsSync() && !force && !sample && only == null) continue;

      final text = strings[arbKey]! as String;
      final body = {
        'text': text,
        'model_id': config['model_id'],
        'seed': config['seed'],
        'voice_settings': voice!['settings'],
      };
      if (dryRun) {
        stdout.writeln('$language/$id: ${jsonEncode(body)}');
        continue;
      }
      try {
        final raw = '${temp.path}/$language-$id.mp3';
        await _speak(
          key,
          voiceId,
          config['output_format']! as String,
          body,
          File(raw),
        );
        out.parent.createSync(recursive: true);
        await normalizeAudio(raw, out.path);
        made++;
        stdout.writeln('✓ ${out.path}');
      } on Object catch (e) {
        failed++;
        stderr.writeln('✗ $language/$id: $e');
      }
    }
  }
  temp.deleteSync(recursive: true);
  if (dryRun) return;

  stdout.writeln(
    'Generated $made clips${failed > 0 ? ', $failed failed' : ''}.',
  );
  if (sample) {
    stdout.writeln(
      'Samples are in build/voice_samples/ (not used by the app).',
    );
  } else if (replaceTestVoices && failed == 0 && only == null) {
    testVoicesMarker.deleteSync();
    stdout.writeln(
      'Test voices replaced. To commit the clips, delete the two voice-clip '
      'lines in .gitignore.',
    );
  }
  if (failed > 0) exitCode = 1;
}

String? _option(List<String> args, String name) {
  final i = args.indexOf(name);
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
}

Future<void> _speak(
  String key,
  String voiceId,
  String format,
  Map<String, Object?> body,
  File out,
) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(
      Uri.parse('$_api/text-to-speech/$voiceId?output_format=$format'),
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

Future<void> _listVoices(String key) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse('$_api/voices'));
    request.headers.set('xi-api-key', key);
    final response = await request.close();
    final json =
        jsonDecode(await response.transform(utf8.decoder).join())
            as Map<String, Object?>;
    if (response.statusCode != 200) {
      stderr.writeln('HTTP ${response.statusCode}: $json');
      exitCode = 1;
      return;
    }
    for (final voice
        in (json['voices'] as List? ?? const []).cast<Map<String, Object?>>()) {
      final labels = (voice['labels'] as Map?)?.values.join(', ') ?? '';
      stdout.writeln('${voice['voice_id']}  ${voice['name']}  $labels');
    }
  } finally {
    client.close();
  }
}
