// Designs Koba's voice with ElevenLabs Voice Design.
//
//   dart run tool/design_voice.dart                 # previews in both languages
//   dart run tool/design_voice.dart --lang id       # one language only
//   dart run tool/design_voice.dart --model eleven_ttv_v3
//                                                   # another design model
//   dart run tool/design_voice.dart --save <generated_voice_id> --lang id
//                                                   # keep a preview as a voice
//
// Previews land in build/voice_samples/koba/<lang>/ (not used by the app).
// Saving prints the new voice_id; put it under voices.koba in
// tool/elevenlabs.json. Uses the API key from .env, like generate_voice.dart.
import 'dart:convert';
import 'dart:io';

import 'src/voice_files.dart';

const _api = 'https://api.elevenlabs.io/v1';
const _model = 'eleven_multilingual_ttv_v2';

const _description =
    'A small, friendly robot who is the best friend of children aged three to '
    'six. Gentle, calm and warm, soft and patient like a kind friend, speaking '
    'slowly and clearly with a bright, happy smile in the voice. Only a very '
    'light robotic shimmer, no harsh or metallic sound, easy for young '
    'children to understand. Childlike but not squeaky, never shouting.';

/// How each language must sound, so Indonesian doesn't drift into Malay.
const _accent = {
  'id':
      ' Speaks standard Indonesian with a natural Jakarta accent, like a '
      "children's TV presenter in Indonesia; never a Malay or Malaysian "
      'accent.',
  'en': '',
};

/// Koba's own lines, long enough for Voice Design (100 characters or more).
const _text = {
  'id':
      'Hai, aku Koba! Ayo bantu aku sampai ke bendera. Wah, hebat sekali! '
      'Hmm, ada batu di jalan. Tidak apa-apa, ayo kita coba lagi bersama-sama.',
  'en':
      "Hi, I'm Koba! Help me reach the flag. Wow, great job! Hmm, there's a "
      "rock in the way. That's okay, let's try again together.",
};

Future<void> main(List<String> args) async {
  final key = setting('ELEVENLABS_API_KEY') ?? '';
  if (key.isEmpty) {
    stderr.writeln('Set ELEVENLABS_API_KEY in .env or the environment.');
    exitCode = 64;
    return;
  }
  final save = _option(args, '--save');
  if (save != null) {
    final language = _option(args, '--lang') ?? 'en';
    final voice = await _post(key, '/text-to-voice', {
      'voice_name': language == 'en' ? 'Koba' : 'Koba ($language)',
      'voice_description': '$_description${_accent[language]}',
      'generated_voice_id': save,
    });
    stdout.writeln('Saved Koba: voice_id ${voice['voice_id']}');
    return;
  }
  final model = _option(args, '--model') ?? _model;
  final languages = switch (_option(args, '--lang')) {
    final String one => [one],
    null => _text.keys.toList(),
  };
  for (final language in languages) {
    final result = await _post(key, '/text-to-voice/design', {
      'voice_description': '$_description${_accent[language]}',
      'model_id': model,
      'text': _text[language],
    });
    final dir = Directory('build/voice_samples/koba/$language')
      ..createSync(recursive: true);
    for (final preview
        in (result['previews']! as List).cast<Map<String, Object?>>()) {
      final id = preview['generated_voice_id']! as String;
      final file = File('${dir.path}/$id.mp3')
        ..writeAsBytesSync(base64Decode(preview['audio_base_64']! as String));
      stdout.writeln('✓ ${file.path}');
    }
  }
  stdout.writeln('Keep one with --save <generated_voice_id> (the file name).');
}

String? _option(List<String> args, String name) {
  final i = args.indexOf(name);
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
}

Future<Map<String, Object?>> _post(
  String key,
  String path,
  Map<String, Object?> body,
) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse('$_api$path'));
    request.headers
      ..set('xi-api-key', key)
      ..contentType = ContentType.json;
    request.write(jsonEncode(body));
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode}: $text');
    }
    return jsonDecode(text) as Map<String, Object?>;
  } finally {
    client.close();
  }
}
