import 'dart:math';

import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/feedback/cheers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  for (final mood in CheerMood.values) {
    test('${mood.name} cheers vary and never repeat back to back', () {
      final picker = CheerPicker(Random(1));
      final texts = <String>[];
      for (var i = 0; i < 200; i++) {
        final cheer = picker.next(l10n, mood);
        expect(cheer.clip, startsWith('cheer_${mood.name}_'));
        texts.add(cheer.text);
      }
      for (var i = 1; i < texts.length; i++) {
        expect(texts[i], isNot(texts[i - 1]));
      }
      expect(texts.toSet().length, greaterThanOrEqualTo(5));
    });
  }

  test('celebrating and encouraging use different words', () {
    final picker = CheerPicker(Random(2));
    final celebrate = {
      for (var i = 0; i < 100; i++) picker.next(l10n, CheerMood.celebrate).text,
    };
    final encourage = {
      for (var i = 0; i < 100; i++) picker.next(l10n, CheerMood.encourage).text,
    };
    expect(celebrate.intersection(encourage), isEmpty);
  });
}
