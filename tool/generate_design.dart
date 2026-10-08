// Designs character ideas as vector illustrations with fal.ai's Recraft V3,
// from the prompts in a JSON file ({"designs": {"name": "prompt", ...}}).
// With "image" (a PNG) and "strength" (0-1) in the file, each prompt edits
// that image instead, e.g. new expressions of the same character.
//
//   dart run tool/generate_design.dart build/character/ideas.json [--tries 2]
//
// Results go to build/character/designs/<name>-<n>.<ext> for review. Each
// vector image costs about $0.08. Put FAL_KEY in .env (see .env.example).
import 'dart:convert';
import 'dart:io';

import 'src/voice_files.dart' show setting;

const _fromText = 'https://fal.run/fal-ai/recraft/v3/text-to-image';
const _fromImage = 'https://fal.run/fal-ai/recraft/v3/image-to-image';

Future<void> main(List<String> args) async {
  final key = setting('FAL_KEY') ?? '';
  if (key.isEmpty || args.isEmpty) {
    stderr.writeln(
      'Usage: set FAL_KEY; dart run tool/generate_design.dart <ideas.json>',
    );
    exit(1);
  }
  final i = args.indexOf('--tries');
  final tries = i >= 0 ? int.parse(args[i + 1]) : 1;
  final config = jsonDecode(File(args.first).readAsStringSync()) as Map;
  final designs = (config['designs']! as Map).cast<String, String>();
  final source = config['image'] as String?;
  final imageUrl = source == null
      ? null
      : 'data:image/png;base64,${base64Encode(File(source).readAsBytesSync())}';
  final strength = (config['strength'] as num?)?.toDouble() ?? 0.5;
  final tagIndex = args.indexOf('--tag');
  final tag = tagIndex >= 0 ? '-${args[tagIndex + 1]}' : '';
  final out = Directory('build/character/designs')..createSync(recursive: true);
  final client = HttpClient();
  try {
    for (final MapEntry(key: name, value: prompt) in designs.entries) {
      for (var n = 1; n <= tries; n++) {
        stdout.write('$name ($n/$tries)… ');
        final request = await client.postUrl(
          Uri.parse(imageUrl == null ? _fromText : _fromImage),
        );
        request.headers
          ..set('Authorization', 'Key $key')
          ..contentType = ContentType.json;
        request.write(
          jsonEncode({
            'prompt': prompt,
            'style': 'vector_illustration',
            if (imageUrl == null) 'image_size': 'square_hd',
            if (imageUrl != null) ...{
              'image_url': imageUrl,
              'strength': strength,
            },
          }),
        );
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();
        if (response.statusCode != 200) {
          stdout.writeln('failed (${response.statusCode})');
          stderr.writeln(body);
          continue;
        }
        final image =
            ((jsonDecode(body) as Map)['images']! as List).first as Map;
        final url = image['url']! as String;
        final type = (image['content_type'] as String?) ?? '';
        final ext = type.contains('svg') || url.endsWith('.svg')
            ? 'svg'
            : url.split('.').last.split('?').first;
        final download = await client.getUrl(Uri.parse(url));
        final bytes = await (await download.close()).fold<List<int>>(
          [],
          (all, b) => all..addAll(b),
        );
        final path = '${out.path}/$name$tag-$n.$ext';
        File(path).writeAsBytesSync(bytes);
        stdout.writeln(path);
      }
    }
  } finally {
    client.close();
  }
}
