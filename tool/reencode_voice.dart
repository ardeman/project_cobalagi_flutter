// Re-encodes bundled voice clips to the format in tool/elevenlabs.json.
//
//   dart run tool/reencode_voice.dart            # every bundled language
//   dart run tool/reencode_voice.dart --lang id  # one language
//   dart run tool/reencode_voice.dart --check    # report, and decode, only
//
// New clips are already encoded that way (tool/generate_voice.dart). This
// brings clips made earlier in line, without trimming or re-levelling them.
// A clip already at the format is left as it is, so running twice does not
// encode it again. Needs ffmpeg.
import 'dart:convert';
import 'dart:io';

import 'src/voice_files.dart';

Future<void> main(List<String> args) async {
  if (testVoicesMarker.existsSync()) {
    stderr.writeln(
      'assets/audio/ holds test voices. '
      'Remove them with: dart run tool/test_voices.dart --clean',
    );
    exitCode = 1;
    return;
  }
  final check = args.contains('--check');
  final format = VoiceFormat.load();
  final only = _option(args, '--lang');
  final languages = bundledVoiceLanguages();
  if (only != null && !languages.contains(only)) {
    stderr.writeln(
      'No voice clips at assets/audio/$only/. '
      'Bundled languages: ${languages.join(', ')}.',
    );
    exitCode = 64;
    return;
  }

  final jobs = <Future<_ClipOutcome> Function()>[];
  for (final language in languages) {
    if (only != null && language != only) continue;
    final dir = Directory('assets/audio/$language');
    for (final entity in dir.listSync()) {
      if (entity is! File || !entity.path.endsWith('.mp3')) continue;
      jobs.add(() => _one(entity, format, check: check));
    }
  }
  if (jobs.isEmpty) {
    stderr.writeln('No voice clips to re-encode.');
    exitCode = 1;
    return;
  }

  final outcomes = <_ClipOutcome>[];
  await _pool(8, [
    for (final job in jobs) () async => outcomes.add(await job()),
  ]);

  final byLanguage = <String, List<_ClipOutcome>>{};
  for (final outcome in outcomes) {
    byLanguage.putIfAbsent(outcome.language, () => []).add(outcome);
  }
  var before = 0;
  var after = 0;
  var reencoded = 0;
  var failed = 0;
  var maxDeltaMs = 0.0;
  for (final language in byLanguage.keys.toList()..sort()) {
    final clips = byLanguage[language]!;
    final langBefore = clips.fold<int>(0, (sum, clip) => sum + clip.before);
    final langAfter = clips.fold<int>(0, (sum, clip) => sum + clip.after);
    final langFailed = clips.where((clip) => clip.error != null).length;
    before += langBefore;
    after += langAfter;
    reencoded += clips.where((clip) => clip.reencoded).length;
    failed += langFailed;
    for (final clip in clips) {
      if (clip.durationDeltaMs > maxDeltaMs) maxDeltaMs = clip.durationDeltaMs;
    }
    stdout.writeln(
      '$language: ${clips.length} clips, '
      '${_mb(langBefore)} MB to ${_mb(langAfter)} MB'
      '${langFailed == 0 ? '' : ', $langFailed failed'}',
    );
  }
  for (final outcome in outcomes) {
    if (outcome.error != null) {
      stderr.writeln('✗ ${outcome.language}/${outcome.id}: ${outcome.error}');
    }
  }
  final done = check ? outcomes.length - failed : reencoded;
  stdout.writeln(
    '${check ? 'Checked' : 'Re-encoded'} $done of ${outcomes.length} '
    'clips at ${format.name}. '
    'Longest duration change ${maxDeltaMs.toStringAsFixed(3)} ms. '
    'Voice audio ${_mb(before)} MB to ${_mb(after)} MB '
    '($before to $after bytes).',
  );
  if (failed > 0) exitCode = 1;
}

String? _option(List<String> args, String name) {
  final index = args.indexOf(name);
  return index >= 0 && index + 1 < args.length ? args[index + 1] : null;
}

String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(2);

Future<void> _pool(int width, List<Future<void> Function()> jobs) async {
  var next = 0;
  Future<void> worker() async {
    while (true) {
      final index = next;
      if (index >= jobs.length) return;
      next = index + 1;
      await jobs[index]();
    }
  }

  final workers = width < jobs.length ? width : jobs.length;
  await Future.wait([for (var i = 0; i < workers; i++) worker()]);
}

class _ClipOutcome {
  _ClipOutcome({
    required this.language,
    required this.id,
    required this.before,
    required this.after,
    required this.reencoded,
    this.durationDeltaMs = 0,
    this.error,
  });

  final String language;
  final String id;
  final int before;
  final int after;
  final bool reencoded;
  final double durationDeltaMs;
  final String? error;
}

Future<_ClipOutcome> _one(
  File file,
  VoiceFormat format, {
  required bool check,
}) async {
  final language = file.parent.path.split(Platform.pathSeparator).last;
  final id = file.uri.pathSegments.last.replaceFirst('.mp3', '');
  _ClipOutcome fail(String message, {int? before}) => _ClipOutcome(
    language: language,
    id: id,
    before: before ?? file.lengthSync(),
    after: before ?? file.lengthSync(),
    reencoded: false,
    error: message,
  );
  late final _Probed before;
  late final int beforeSamples;
  try {
    before = await _probe(file.path);
    beforeSamples = await _sampleCount(file.path);
  } on Object catch (error) {
    return fail('$error');
  }
  if (before.matches(format)) {
    return _ClipOutcome(
      language: language,
      id: id,
      before: before.size,
      after: before.size,
      reencoded: false,
    );
  }
  if (check) {
    return fail(
      'is ${before.channels} ch, ${before.sampleRate} Hz, '
      '${before.bitrate} bps; expected mono ${format.name}',
      before: before.size,
    );
  }

  final temp = File('${Directory.systemTemp.path}/cobalagi-$language-$id.mp3');
  try {
    await runChecked('ffmpeg', [
      '-y',
      '-loglevel',
      'error',
      '-i',
      file.path,
      ...monoMp3Args(
        sampleRate: format.sampleRate,
        bitrateKbps: format.bitrateKbps,
      ),
      temp.path,
    ]);
    final after = await _probe(temp.path);
    final afterSamples = await _sampleCount(temp.path);
    if (!after.matches(format)) {
      return fail(
        'encoded to ${after.channels} ch, ${after.sampleRate} Hz, '
        '${after.bitrate} bps',
        before: before.size,
      );
    }
    if (afterSamples != beforeSamples) {
      return fail(
        'decoded length changed from $beforeSamples to $afterSamples samples',
        before: before.size,
      );
    }
    final deltaMs = (after.duration - before.duration).abs() * 1000;
    if (deltaMs > 1) {
      return fail(
        'duration changed by ${deltaMs.toStringAsFixed(3)} ms',
        before: before.size,
      );
    }
    final staging = File('${file.path}.reencoding');
    await temp.copy(staging.path);
    await staging.rename(file.path);
    return _ClipOutcome(
      language: language,
      id: id,
      before: before.size,
      after: after.size,
      reencoded: true,
      durationDeltaMs: deltaMs,
    );
  } on Object catch (error) {
    return fail('$error', before: before.size);
  } finally {
    if (temp.existsSync()) temp.deleteSync();
    final staging = File('${file.path}.reencoding');
    if (staging.existsSync()) staging.deleteSync();
  }
}

class _Probed {
  const _Probed({
    required this.duration,
    required this.sampleRate,
    required this.channels,
    required this.bitrate,
    required this.size,
  });

  final double duration;
  final int sampleRate;
  final int channels;
  final int bitrate;
  final int size;

  bool matches(VoiceFormat format) =>
      channels == 1 &&
      sampleRate == format.sampleRate &&
      bitrate == format.bitrateKbps * 1000;
}

Future<_Probed> _probe(String path) async {
  final result = await Process.run('ffprobe', [
    '-v',
    'error',
    '-select_streams',
    'a:0',
    '-show_entries',
    'stream=sample_rate,channels,bit_rate,duration',
    '-show_entries',
    'format=duration,size',
    '-of',
    'json',
    path,
  ]);
  if (result.exitCode != 0) {
    throw ProcessException(
      'ffprobe',
      [path],
      '${result.stderr}',
      result.exitCode,
    );
  }
  final json = jsonDecode('${result.stdout}') as Map<String, Object?>;
  final streams = json['streams'] as List<Object?>? ?? const [];
  if (streams.isEmpty) {
    throw FormatException('no audio stream in $path');
  }
  final stream = streams.first! as Map<String, Object?>;
  final container = json['format'] as Map<String, Object?>? ?? const {};
  return _Probed(
    duration: double.parse('${stream['duration'] ?? container['duration']}'),
    sampleRate: int.parse('${stream['sample_rate']}'),
    channels: int.parse('${stream['channels']}'),
    bitrate: int.parse('${stream['bit_rate']}'),
    size: int.parse('${container['size']}'),
  );
}

/// Decoded PCM frames. ffmpeg honours the encoder-delay tag, so this is the
/// length a player reports, and a failed decode throws.
Future<int> _sampleCount(String path) async {
  final result = await Process.run('ffmpeg', [
    '-v',
    'error',
    '-i',
    path,
    '-f',
    's16le',
    '-acodec',
    'pcm_s16le',
    '-ac',
    '1',
    'pipe:1',
  ], stdoutEncoding: null);
  if (result.exitCode != 0) {
    throw ProcessException(
      'ffmpeg',
      [path],
      '${result.stderr}',
      result.exitCode,
    );
  }
  final bytes = result.stdout as List<int>;
  if (bytes.length.isOdd) {
    throw FormatException('$path decoded to an odd number of bytes');
  }
  if (bytes.isEmpty) throw FormatException('$path decoded to silence');
  return bytes.length ~/ 2;
}
