// Turns the `SHOT <name> <base64>` lines an on-device test prints
// (integration_test/app_flow_test.dart) back into PNG files.
//
//   dart run tool/collect_screenshots.dart run.log <folder>
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('usage: dart run tool/collect_screenshots.dart <log> <dir>');
    exit(64);
  }
  final parts = <String, StringBuffer>{};
  final shot = RegExp(r'SHOT (\S+) ([A-Za-z0-9+/=]+)\s*$');
  for (final line in File(args[0]).readAsLinesSync()) {
    final match = shot.firstMatch(line);
    if (match == null) continue;
    parts.putIfAbsent(match[1]!, StringBuffer.new).write(match[2]);
  }
  final dir = Directory(args[1])..createSync(recursive: true);
  for (final MapEntry(:key, :value) in parts.entries) {
    File('${dir.path}/$key.png').writeAsBytesSync(base64Decode('$value'));
  }
  stdout.writeln('${parts.length} screenshots in ${dir.path}');
}
