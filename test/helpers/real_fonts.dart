import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the Roboto and Material icons that ship with the Flutter SDK. The
/// test font draws every letter as a square, far wider than real words, so
/// tests that measure whether words fit load these first.
Future<void> loadRealFonts() async {
  final flutter = Platform.resolvedExecutable;
  final fonts =
      '${flutter.substring(0, flutter.indexOf('/bin/cache/'))}'
      '/bin/cache/artifacts/material_fonts';
  for (final (family, files) in const [
    ('Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']),
    ('MaterialIcons', ['MaterialIcons-Regular.otf']),
  ]) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(
        Future.value(
          ByteData.sublistView(File('$fonts/$file').readAsBytesSync()),
        ),
      );
    }
    await loader.load();
  }
}
