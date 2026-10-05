import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/audio/voice_clips.dart';
import 'package:cobalagi/core/feedback/cheers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final language in ['en', 'id']) {
    test('every clip has words to record in $language', () {
      final arb =
          jsonDecode(File('lib/app/l10n/app_$language.arb').readAsStringSync())
              as Map<String, Object?>;
      for (final MapEntry(key: id, value: key) in VoiceClips.all.entries) {
        expect(arb[key], isA<String>(), reason: '$id → $key');
      }
    });
  }

  test('cheer clips are all registered', () {
    final picker = CheerPicker(Random(4));
    final l10n = lookupAppLocalizations(const Locale('id'));
    for (var i = 0; i < 200; i++) {
      for (final mood in CheerMood.values) {
        expect(VoiceClips.all, contains(picker.next(l10n, mood).clip));
      }
    }
  });
}
