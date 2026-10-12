import 'package:flutter_test/flutter_test.dart';

import '../../tool/marketing/youtube_text.dart';

void main() {
  final copy = loadCopy();
  final version = appVersion();

  test('there is YouTube text for every promo video, in both languages', () {
    expect(videos(copy).toSet(), {
      'promo-en',
      'promo-id',
      'short-en',
      'short-id',
    });
  });

  for (final video in videos(copy)) {
    test('$video: the title carries the app version and fits', () {
      final title = titleOf(copy, video, version);
      expect(title, contains('Coba Lagi $version'));
      expect(title.length, lessThanOrEqualTo(titleLimit));
      expect(title, isNot(matches(RegExp('[<>]'))), reason: 'YouTube refuses');
    });

    for (final live in [false, true]) {
      test('$video: the description fits (${live ? 'live' : 'soon'})', () {
        final description = descriptionOf(copy, video, live);
        expect(description.length, lessThanOrEqualTo(descriptionLimit));
        expect(description, isNot(contains('{')), reason: 'all filled in');
        expect(description, isNot(matches(RegExp('[<>]'))));
        expect(
          description.contains('play.google.com'),
          live,
          reason: 'the store link only once the app is public',
        );
      });
    }

    test('$video: every setting is filled in', () {
      final text = youtubeText(copy, video, version: version, live: false);
      expect(text, isNot(contains('{')));
      expect(text, contains('$video.srt'));
    });
  }
}
