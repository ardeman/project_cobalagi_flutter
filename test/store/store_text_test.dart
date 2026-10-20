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

/// The App Store's limits, in characters.
const appStoreLimits = {
  'name.txt': 30,
  'subtitle.txt': 30,
  'keywords.txt': 100,
  'promotional_text.txt': 170,
  'description.txt': 4000,
};

/// Words Apple rejects in its listing: other platforms (guideline 2.3.10)
/// and donations, which only nonprofits may take (3.2.2).
final appStoreBanned = RegExp(
  r'google|android|donasi|donation',
  caseSensitive: false,
);

int length(File file) => file.readAsStringSync().trim().runes.length;

void main() {
  for (final locale in locales) {
    for (final MapEntry(key: name, value: max) in limits.entries) {
      test('$locale/$name fits $max characters', () {
        expect(
          length(File('store/google_play/$locale/$name')),
          lessThanOrEqualTo(max),
        );
      });
    }
  }

  test('every build has release notes in both languages', () {
    Set<String> builds(String locale) => {
      for (final file in Directory(
        'store/google_play/$locale/changelogs',
      ).listSync())
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
    for (final file in Directory(
      'store/google_play/$locale/changelogs',
    ).listSync()) {
      final name = file.uri.pathSegments.last;
      test('$locale/changelogs/$name fits $releaseNotesLimit characters', () {
        expect(length(File(file.path)), lessThanOrEqualTo(releaseNotesLimit));
      });
    }
  }

  for (final locale in locales) {
    for (final MapEntry(key: name, value: max) in appStoreLimits.entries) {
      final file = File('store/app_store/$locale/$name');
      test('app_store/$locale/$name fits $max characters', () {
        expect(length(file), lessThanOrEqualTo(max));
      });
      test('app_store/$locale/$name names no other store or donations', () {
        expect(file.readAsStringSync(), isNot(contains(appStoreBanned)));
      });
    }
  }
}
