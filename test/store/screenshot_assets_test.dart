import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

const _screenshots = {
  '1-adventure-map.png',
  '2-play-loops.png',
  '3-code.png',
  '4-play-functions.png',
  '5-fix-it.png',
  '6-solved.png',
  '7-until.png',
  '8-parents.png',
};

void main() {
  for (final locale in ['id', 'en-US']) {
    for (final (folder, width, height) in [
      ('screenshots', 1920, 1080),
      ('phone_screenshots', 1080, 1920),
    ]) {
      test('$locale/$folder has matching coverage and correct dimensions', () {
        final files = Directory('store/$locale/$folder')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.png'));
        expect(
          files.map((file) => file.uri.pathSegments.last).toSet(),
          _screenshots,
        );
        for (final file in files) {
          final bytes = file.readAsBytesSync();
          expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
          final data = ByteData.sublistView(bytes);
          expect(data.getUint32(16), width, reason: file.path);
          expect(data.getUint32(20), height, reason: file.path);
        }
      });
    }
  }
}
