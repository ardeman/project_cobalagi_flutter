import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/website_changelog.dart';

void main() {
  test('the website changelog matches the store release notes', () {
    expect(
      File(pagePath).readAsStringSync(),
      buildChangelogPage(),
      reason: 'Run: dart run tool/website_changelog.dart',
    );
  });

  test('every build has release notes and an entry in store/releases.json', () {
    final notes = Directory('store/en-US/changelogs')
        .listSync()
        .map((f) => f.uri.pathSegments.last)
        .where((name) => name.endsWith('.txt'))
        .map((name) => int.parse(name.replaceAll('.txt', '')))
        .toSet();
    final page = buildChangelogPage();
    for (final build in notes) {
      expect(page, contains('id="build-$build"'), reason: 'build $build');
    }
  });
}
