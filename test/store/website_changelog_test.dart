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

  test('every page has the same menu and footer', () {
    String part(String page, String tag) {
      final html = File('website/$page').readAsStringSync();
      final start = html.indexOf('  <$tag>');
      final end = html.indexOf('  </$tag>');
      expect(start, isNonNegative, reason: '$page has no <$tag>');
      return html.substring(start, end);
    }

    // The home page links to its own sections without leaving the page.
    String asHome(String header) => header
        .replaceAll('href="index.html#', 'href="#')
        .replaceAll(
          '<a class="brand" href="index.html" data-keep-lang',
          '<a class="brand" href="#top"',
        )
        .replaceAllMapped(
          RegExp(r'href="(#[a-z]+)" data-keep-lang'),
          (m) => 'href="${m[1]}"',
        );

    final header = part('privacy.html', 'header');
    final footer = part('privacy.html', 'footer');
    expect(part('changelog.html', 'header'), header);
    expect(part('changelog.html', 'footer'), footer);
    expect(part('index.html', 'header'), asHome(header));
    expect(part('index.html', 'footer'), footer);
  });
}
