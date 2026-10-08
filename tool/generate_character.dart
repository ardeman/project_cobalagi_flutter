// Makes the character's animations as Lottie files with fal.ai's Omnilottie
// (image to Lottie), from the image and prompts in tool/character.json.
//
//   dart run tool/generate_character.dart                # every animation
//   dart run tool/generate_character.dart --only idle    # one of them
//   dart run tool/generate_character.dart --tries 3      # 3 variants each
//   ... --temperature 0.5   # closer to the image (default 0.9)
//   ... --tag low           # name results <name>-low-<n>.json
//   ... --text              # no image: the AI designs the look (\$0.05)
//   ... --image path.png    # start from another image
//
// Results go to build/character/<name>-<n>.json for review; copy the ones
// you choose into assets yourself. Each try costs about $0.10.
//
// Put FAL_KEY in .env (git-ignored; see .env.example) or export it.
import 'dart:convert';
import 'dart:io';

import 'src/voice_files.dart' show setting;

const _fromImage = 'https://fal.run/fal-ai/omnilottie/image-to-lottie';
const _fromText = 'https://fal.run/fal-ai/omnilottie';

Future<void> main(List<String> args) async {
  final key = setting('FAL_KEY') ?? '';
  if (key.isEmpty) {
    stderr.writeln(
      'Set FAL_KEY in .env (copy .env.example) or the environment.',
    );
    exit(1);
  }
  String? option(String name) {
    final i = args.indexOf(name);
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  final only = option('--only')?.split(',').toSet();
  final tries = int.tryParse(option('--tries') ?? '') ?? 1;
  final temperature = double.tryParse(option('--temperature') ?? '');
  final tag = option('--tag');
  final textOnly = args.contains('--text');
  final config =
      jsonDecode(
            File(
              option('--config') ?? 'tool/character.json',
            ).readAsStringSync(),
          )
          as Map<String, Object?>;
  final image = File(
    option('--image') ?? config['image']! as String,
  ).readAsBytesSync();
  final imageUrl = 'data:image/png;base64,${base64Encode(image)}';
  final animations = (config['animations']! as Map).cast<String, String>();
  final out = Directory('build/character')..createSync(recursive: true);

  final client = HttpClient();
  try {
    for (final MapEntry(key: name, value: prompt) in animations.entries) {
      if (only != null && !only.contains(name)) continue;
      for (var n = 1; n <= tries; n++) {
        stdout.write('$name ($n/$tries)… ');
        final request = await client.postUrl(
          Uri.parse(textOnly ? _fromText : _fromImage),
        );
        request.headers
          ..set('Authorization', 'Key $key')
          ..contentType = ContentType.json;
        request.write(
          jsonEncode({
            'prompt': prompt,
            if (!textOnly) 'image_url': imageUrl,
            'temperature': ?temperature,
          }),
        );
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();
        if (response.statusCode != 200) {
          stdout.writeln('failed (${response.statusCode})');
          stderr.writeln(body);
          continue;
        }
        final file =
            (jsonDecode(body) as Map<String, Object?>)['lottie_file']
                as Map<String, Object?>;
        final download = await client.getUrl(Uri.parse(file['url']! as String));
        final lottie = await (await download.close()).fold<List<int>>(
          [],
          (all, bytes) => all..addAll(bytes),
        );
        final path = '${out.path}/$name${tag == null ? '' : '-$tag'}-$n.json';
        File(path).writeAsBytesSync(lottie);
        stdout.writeln(path);
      }
    }
  } finally {
    client.close();
  }
}
