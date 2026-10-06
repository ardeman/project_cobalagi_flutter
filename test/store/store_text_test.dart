import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const locales = ['id', 'en-US'];

/// Play's limits, in characters.
const limits = {
  'title.txt': 30,
  'short_description.txt': 80,
  'full_description.txt': 4000,
};
const releaseNotesLimit = 500;

int length(File file) => file.readAsStringSync().trim().runes.length;

void main() {
  for (final locale in locales) {
    for (final MapEntry(key: name, value: max) in limits.entries) {
      test('$locale/$name fits $max characters', () {
        expect(length(File('store/$locale/$name')), lessThanOrEqualTo(max));
      });
    }
  }

  test('every build has release notes in both languages', () {
    Set<String> builds(String locale) => {
      for (final file in Directory('store/$locale/changelogs').listSync())
        file.uri.pathSegments.last,
    };
    expect(builds('id'), builds('en-US'));
    final version = RegExp(
      r'^version: .*\+(\d+)$',
      multiLine: true,
    ).firstMatch(File('pubspec.yaml').readAsStringSync())![1];
    expect(
      builds('id'),
      contains('$version.txt'),
      reason: 'release notes for the current build are missing',
    );
  });

  for (final locale in locales) {
    for (final file in Directory('store/$locale/changelogs').listSync()) {
      final name = file.uri.pathSegments.last;
      test('$locale/changelogs/$name fits $releaseNotesLimit characters', () {
        expect(length(File(file.path)), lessThanOrEqualTo(releaseNotesLimit));
      });
    }
  }
}
