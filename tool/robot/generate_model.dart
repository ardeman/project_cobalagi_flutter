// Builds a 3D model of the robot with fal.ai from its pictures, so every
// angle comes from one model instead of being redrawn.
//
//   dart run tool/robot/generate_model.dart side
//       draws the robot's left side from its front and three-quarter
//       pictures (Nano Banana, about $0.04), as a view for the 3D models
//   dart run tool/robot/generate_model.dart [tripo|hunyuan]
//       [--front F] [--back B] [--left L] [--right R] [--seed N]
//       builds the model from those views (about $0.20-0.40); front and back
//       default to assets/images/robot_front.png and robot_back.png
//
// Results go to build/robot3d/<what>-<time>.* for review. Put FAL_API_KEY in
// .env (see .env.example).
import 'dart:convert';
import 'dart:io';

import '../src/voice_files.dart' show setting;

const _endpoints = {
  'side': 'fal-ai/nano-banana/edit',
  'tripo': 'tripo3d/tripo/v2.5/multiview-to-3d',
  'hunyuan': 'fal-ai/hunyuan3d-v3/image-to-3d',
};

const _sidePrompt =
    'Draw this exact robot character seen from its left side, a pure '
    'profile view at 90 degrees: the round helmet head in profile with the '
    'yellow ear disc in the middle, the dark screen visible only as a thin '
    'edge at the front, the antenna on top, one yellow ribbed arm, the '
    'wheels seen from the side. Keep the same colours, outlines and flat '
    'cartoon style, and the same proportions as the front picture. Plain '
    'white background, no ground shadow, no face on the screen.';

Future<void> main(List<String> args) async {
  final key = setting('FAL_API_KEY') ?? '';
  final what = args.firstWhere(
    (a) => !a.startsWith('--'),
    orElse: () => 'tripo',
  );
  final endpoint = _endpoints[what];
  if (key.isEmpty || endpoint == null) {
    stderr.writeln(
      'Usage: set FAL_API_KEY; dart run tool/robot/generate_model.dart '
      '[side|tripo|hunyuan] [--front F] [--back B] [--left L] [--right R] '
      '[--seed N]',
    );
    exit(1);
  }
  String? option(String name) {
    final i = args.indexOf('--$name');
    return i >= 0 ? args[i + 1] : null;
  }

  final seed = int.tryParse(option('seed') ?? '');
  final views = {
    'front': option('front') ?? 'assets/images/robot_front.png',
    'back': option('back') ?? 'assets/images/robot_back.png',
    'left': ?option('left'),
    'right': ?option('right'),
  };

  final client = HttpClient();
  Future<Map<String, dynamic>> call(
    String method,
    String url, [
    Object? body,
  ]) async {
    final request = await client.openUrl(method, Uri.parse(url));
    request.headers.set('Authorization', 'Key $key');
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    if (response.statusCode >= 300) {
      // fal echoes the input back; keep the message short.
      final short = text.length > 600 ? '${text.substring(0, 600)}…' : text;
      throw HttpException('${response.statusCode}: $short');
    }
    return jsonDecode(text) as Map<String, dynamic>;
  }

  Future<void> download(String url, String path) async {
    final response = await (await client.getUrl(Uri.parse(url))).close();
    await response.pipe(File(path).openWrite());
    stdout.writeln(path);
  }

  // The 3D models only read images by URL, so they go to fal's storage first.
  Future<String> upload(String path) async {
    final target = await call(
      'POST',
      'https://rest.alpha.fal.ai/storage/upload/initiate?storage_type=fal-cdn-v3',
      {'content_type': 'image/png', 'file_name': path.split('/').last},
    );
    final request = await client.putUrl(
      Uri.parse(target['upload_url']! as String),
    );
    request.headers.contentType = ContentType('image', 'png');
    request.add(File(path).readAsBytesSync());
    final response = await request.close();
    await response.drain<void>();
    if (response.statusCode >= 300) {
      throw HttpException('upload ${response.statusCode}');
    }
    return target['file_url']! as String;
  }

  try {
    stdout.write('$what: uploading… ');
    final Map<String, Object> input;
    if (what == 'side') {
      input = {
        'prompt': _sidePrompt,
        'image_urls': [
          await upload('assets/images/robot_front.png'),
          await upload('assets/images/robot.png'),
        ],
        'num_images': 2,
        'output_format': 'png',
      };
    } else {
      final urls = {
        for (final MapEntry(key: view, value: path) in views.entries)
          view: await upload(path),
      };
      input = what == 'tripo'
          ? {
              for (final MapEntry(key: view, value: url) in urls.entries)
                '${view}_image_url': url,
              'texture': 'HD',
              'texture_alignment': 'original_image',
              'seed': ?seed,
            }
          : {
              'input_image_url': urls['front']!,
              for (final MapEntry(key: view, value: url) in urls.entries)
                if (view != 'front') '${view}_image_url': url,
              'enable_pbr': false,
            };
    }
    stdout.write('sending… ');
    final queued = await call('POST', 'https://queue.fal.run/$endpoint', input);
    stdout.writeln('queued');
    while (true) {
      await Future<void>.delayed(const Duration(seconds: 5));
      final status = await call('GET', queued['status_url']! as String);
      if (status['status'] == 'COMPLETED') break;
      stdout.write('.');
    }
    stdout.writeln();
    final result = await call('GET', queued['response_url']! as String);
    final out = Directory('build/robot3d')..createSync(recursive: true);
    final name = '${out.path}/$what-${DateTime.now().millisecondsSinceEpoch}';
    File(
      '$name.json',
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(result));
    final files = <String, Object?>{
      if (result['images'] case final List images)
        for (final (i, image) in images.indexed) '$i.png': image,
      'glb': result['pbr_model'] ?? result['model_mesh'] ?? result['model_glb'],
      'png': result['rendered_image'] ?? result['thumbnail'],
    };
    for (final MapEntry(key: ext, value: file) in files.entries) {
      if (file is Map && file['url'] is String) {
        await download(file['url']! as String, '$name.$ext');
      }
    }
  } finally {
    client.close();
  }
}
