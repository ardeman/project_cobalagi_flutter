import 'dart:convert';
import 'dart:io';

import 'package:cobalagi/app/fallback_localizations.dart';
import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/core/settings/app_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Set<String> keysOf(String code) {
    final arb =
        jsonDecode(File('lib/app/l10n/app_$code.arb').readAsStringSync())
            as Map<String, Object?>;
    return arb.keys.where((key) => !key.startsWith('@')).toSet();
  }

  for (final language in AppLanguage.values) {
    test('${language.name} has every text', () {
      expect(keysOf(language.code), keysOf('en'));
      expect(
        AppLocalizations.supportedLocales,
        contains(Locale(language.code)),
      );
    });
  }

  test('every language file is in the picker', () {
    final codes = [
      for (final file in Directory('lib/app/l10n').listSync())
        ?RegExp(r'app_(\w+)\.arb$').firstMatch(file.path)?.group(1),
    ];
    expect(codes.toSet(), {
      for (final language in AppLanguage.values) language.code,
    });
  });

  testWidgets('a regional language shows Indonesian system texts', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ace'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: appLocalizationsDelegates,
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(MaterialLocalizations.of(context).backButtonTooltip, 'Kembali');
    final l10n = AppLocalizations.of(context);
    expect(l10n.nextIslandSoon(2, 'Arah'), contains('2'));
    expect(l10n.nextIslandSoon(1, 'Arah'), isNot(contains('1')));
  });

  test('a regional language speaks Indonesian until it has its own clip', () {
    expect(voiceClipPaths('tourGo', 'ace'), [
      'audio/ace/tourGo.mp3',
      'audio/id/tourGo.mp3',
    ]);
    expect(voiceClipPaths('tourGo', 'en'), ['audio/en/tourGo.mp3']);
  });
}
