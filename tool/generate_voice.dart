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
//   dart run tool/generate_voice.dart --speaker koba --force
//                                     # re-record one speaker's clips
//   dart run tool/generate_voice.dart --dry-run         # show what would be sent
//   dart run tool/generate_voice.dart --sample --only pretest_turn_left --model eleven_v4
//                                     # audition one clip with another model
//
// Each clip's speaker (VoiceClips.speakerOf) picks its voice:
// voices.<speaker>.<lang>. A voice that needs a different model sets
// voices.<speaker>.<lang>.model_id, and a single clip can be pinned in
// voices.<speaker>.<lang>.clip_models (e.g. Indonesian lines that sound
// Malay: eleven_multilingual_v2 ignores language_code).
//
// A language ElevenLabs can't speak (Acehnese, Minangkabau) sets
// voices.<speaker>.<lang>.recordings: its clips are a native speaker's
// recordings (tool/record_voice.dart) turned into the speaker's voice with
// speech-to-speech; a line not recorded yet is skipped, so the app plays
// the Indonesian clip instead.
//
// Voices, model and settings live in tool/elevenlabs.json. Shipping the clips
// needs an ElevenLabs plan with a commercial license (not the free plan).
// Needs ffmpeg.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cobalagi/core/audio/voice_clips.dart';

import 'src/voice_files.dart';

const _api = 'https://api.elevenlabs.io/v1';

/// Models that reject `language_code`; they guess the language from the text.
const _ignoresLanguageCode = {'eleven_multilingual_v2'};

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
  final speakers = config['voices']! as Map<String, Object?>;
  final languages = switch (_option(args, '--lang')) {
    final String one => [one],
    null => ['id', 'en'],
  };
  final onlySpeaker = switch (_option(args, '--speaker')) {
    final String name => Speaker.values.byName(name),
    null => null,
  };
  final sample = args.contains('--sample');
  final only = _option(args, '--only')?.split(',').toSet();
  // Clips made by test_voices.dart are placeholders: replace them all.
  final replaceTestVoices = testVoicesMarker.existsSync() && !sample;
  final force = args.contains('--force') || replaceTestVoices;

  final temp = Directory.systemTemp.createTempSync('elevenlabs');
  var made = 0;
  var failed = 0;
  var unrecorded = 0;
  for (final language in languages) {
    final strings = loadStrings(language);
    for (final MapEntry(key: id, value: arbKey) in VoiceClips.all.entries) {
      // Samples: the given clips, or a default few.
      if (sample && only == null && !_sampleClips.contains(id)) continue;
      if (only != null && !only.contains(id)) continue;
      final speaker = VoiceClips.speakerOf(id);
      if (onlySpeaker != null && speaker != onlySpeaker) continue;
      final voice =
          (speakers[speaker.name] as Map?)?[language] as Map<String, Object?>?;
      final voiceId = voice?['voice_id'] as String? ?? '';
      if (voiceId.isEmpty) {
        stderr.writeln(
          'No voice_id for ${speaker.name}/$language in tool/elevenlabs.json. '
          'Pick one with --voices.',
        );
        exitCode = 64;
        return;
      }
      final out = sample
          ? File('build/voice_samples/$language/$id.mp3')
          : clipFile(language, id);
      if (out.existsSync() && !force && !sample && only == null) continue;

      final recordings = voice!['recordings'] == true;
      final recording = recordingFile(language, id);
      if (recordings && !recording.existsSync()) {
        unrecorded++;
        continue;
      }
      final text = strings[arbKey]! as String;
      // Some clips sound better on another model, e.g. when the default
      // model drifts into Malay: voices.<lang>.model_id or clip_models.
      final clipModels =
          (voice['clip_models'] as Map?)?.cast<String, String>() ?? const {};
      final model =
          _option(args, '--model') ??
          clipModels[id] ??
          voice['model_id'] as String? ??
          config['model_id']! as String;
      final body = {
        'text': text,
        'model_id': model,
        'seed': config['seed'],
        'voice_settings': voice['settings'],
        // Forces the language, e.g. Indonesian rather than Malay.
        if (voice['language_code'] case final String code
            when !_ignoresLanguageCode.contains(model))
          'language_code': code,
      };
      if (dryRun) {
        final source = recordings ? recording.path : jsonEncode(body);
        stdout.writeln('$language/$id (${speaker.name}): $source');
        continue;
      }
      try {
        final raw = '${temp.path}/$language-$id.mp3';
        final format = config['output_format']! as String;
        if (recordings) {
          final trimmed = '${temp.path}/$language-$id.wav';
          await trimSilence(recording.path, trimmed);
          await _convert(
            key,
            voiceId,
            format,
            model,
            voice,
            File(trimmed),
            File(raw),
          );
        } else {
          await _speak(key, voiceId, format, body, File(raw));
        }
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
  if (unrecorded > 0) {
    stdout.writeln(
      '$unrecorded lines have no recording yet (tool/record_voice.dart).',
    );
  }
  if (sample) {
    stdout.writeln(
      'Samples are in build/voice_samples/ (not used by the app).',
    );
  } else if (replaceTestVoices && failed == 0 && only == null) {
    testVoicesMarker.deleteSync();
    stdout.writeln('Test voices replaced; the clips can now be committed.');
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

/// Speech-to-speech: [recording] spoken again in [voiceId]'s voice.
Future<void> _convert(
  String key,
  String voiceId,
  String format,
  String model,
  Map<String, Object?> voice,
  File recording,
  File out,
) async {
  final boundary = 'cobalagi${DateTime.now().microsecondsSinceEpoch}';
  final body = BytesBuilder();
  void field(String name, String value) => body.add(
    utf8.encode(
      '--$boundary\r\nContent-Disposition: form-data; name="$name"\r\n\r\n'
      '$value\r\n',
    ),
  );
  field('model_id', model);
  if (voice['settings'] case final Map<String, Object?> settings) {
    field('voice_settings', jsonEncode(settings));
  }
  body
    ..add(
      utf8.encode(
        '--$boundary\r\nContent-Disposition: form-data; name="audio"; '
        'filename="clip.wav"\r\nContent-Type: audio/wav\r\n\r\n',
      ),
    )
    ..add(recording.readAsBytesSync())
    ..add(utf8.encode('\r\n--$boundary--\r\n'));

  final client = HttpClient();
  try {
    final request = await client.postUrl(
      Uri.parse('$_api/speech-to-speech/$voiceId?output_format=$format'),
    );
    request.headers
      ..set('xi-api-key', key)
      ..set('content-type', 'multipart/form-data; boundary=$boundary');
    request.add(body.takeBytes());
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
