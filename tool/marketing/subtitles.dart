// Writes a video's subtitles (SubRip, .srt) from its narration: the words of
// each voice clip, from the app's ARB file, at the time the clip plays.
// Called by tool/marketing/lib.sh when it finishes a video:
//   dart run tool/marketing/subtitles.dart <out.srt> <start|seconds|lang|clipId>...
// A clip id is snake_case and its words are under the camelCase ARB key
// (tutorial_loops → tutorialLoops), as in VoiceClips.
import 'dart:convert';
import 'dart:io';

/// Longest subtitle line, in characters; two lines per cue at most.
const _lineLength = 42;

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/marketing/subtitles.dart '
      '<out.srt> <start|seconds|lang|clipId>...',
    );
    exit(64);
  }
  final cues = <(double, double, String)>[];
  for (final entry in args.skip(1)) {
    final [start, seconds, lang, clip] = entry.split('|');
    final arb =
        jsonDecode(File('lib/app/l10n/app_$lang.arb').readAsStringSync())
            as Map<String, dynamic>;
    final key = clip.replaceAllMapped(
      RegExp('_([a-z])'),
      (m) => m[1]!.toUpperCase(),
    );
    final text = arb[key] as String?;
    if (text == null) throw StateError('No "$key" in app_$lang.arb');
    cues.addAll(_split(text, double.parse(start), double.parse(seconds)));
  }
  final srt = StringBuffer();
  for (var i = 0; i < cues.length; i++) {
    final (from, to, text) = cues[i];
    srt
      ..writeln(i + 1)
      ..writeln('${_time(from)} --> ${_time(to)}')
      ..writeln(text)
      ..writeln();
  }
  File(args.first).writeAsStringSync(srt.toString());
}

/// Splits [text] into cues of at most two short lines, sharing [seconds]
/// from [start] by their length.
List<(double, double, String)> _split(
  String text,
  double start,
  double seconds,
) {
  final chunks = <String>[];
  for (final sentence in text.split(RegExp(r'(?<=[.!?])\s+'))) {
    final lines = _wrap(sentence);
    for (var i = 0; i < lines.length; i += 2) {
      chunks.add(lines.skip(i).take(2).join('\n'));
    }
  }
  final total = chunks.fold(0, (sum, c) => sum + c.length);
  var at = start;
  return [
    for (final chunk in chunks)
      (at, at += seconds * chunk.length / total, chunk),
  ];
}

List<String> _wrap(String sentence) {
  final lines = <String>[];
  var line = '';
  for (final word in sentence.split(' ')) {
    if (line.isNotEmpty && line.length + 1 + word.length > _lineLength) {
      lines.add(line);
      line = word;
    } else {
      line = line.isEmpty ? word : '$line $word';
    }
  }
  if (line.isNotEmpty) lines.add(line);
  return lines;
}

String _time(double seconds) {
  final ms = (seconds * 1000).round();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(ms ~/ 3600000)}:${two(ms ~/ 60000 % 60)}:'
      '${two(ms ~/ 1000 % 60)},${(ms % 1000).toString().padLeft(3, '0')}';
}
