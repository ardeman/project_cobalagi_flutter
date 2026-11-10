import 'dart:convert';
import 'dart:io';

import 'package:cobalagi/app/fallback_localizations.dart';
import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/core/audio/voice_clips.dart';
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

  // Children learn to read with the Indonesian alphabet, so regional
  // languages skip spelling marks such as é or ô.
  for (final language in AppLanguage.values) {
    test('${language.name} uses only letters taught in Indonesian', () {
      final arb =
          jsonDecode(
                File(
                  'lib/app/l10n/app_${language.code}.arb',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      final marked = [
        for (final MapEntry(:key, :value) in arb.entries)
          if (!key.startsWith('@') &&
              value is String &&
              RegExp('[À-ÖØ-öø-ÿ]').hasMatch(value))
            key,
      ];
      expect(marked, isEmpty);
    });
  }
  // The picker names each language in its own words, with the same letters.
  test('language names use only letters taught in Indonesian', () {
    for (final language in AppLanguage.values) {
      expect(language.name, isNot(matches('[À-ÖØ-öø-ÿ]')));
    }
  });

  test('every language file is in the picker', () {
    final codes = [
      for (final file in Directory('lib/app/l10n').listSync())
        ?RegExp(r'app_(\w+)\.arb$').firstMatch(file.path)?.group(1),
    ];
    expect(codes.toSet(), {
      for (final language in AppLanguage.values) language.code,
    });
  });

  for (final language in AppLanguage.values) {
    test('${language.name} is offered once its voice is finished', () {
      final missing = [
        for (final id in VoiceClips.all.keys)
          if (!VoiceClips.pending.contains(id) &&
              !File('assets/audio/${language.code}/$id.mp3').existsSync())
            id,
      ];
      final bundled = File(
        'pubspec.yaml',
      ).readAsStringSync().contains('- assets/audio/${language.code}/');
      expect(
        language.voiced,
        missing.isEmpty && bundled,
        reason: missing.isEmpty
            ? 'Voiced: set voiced and list assets/audio/${language.code}/ '
                  'in pubspec.yaml.'
            : '${missing.length} clips missing, e.g. ${missing.first}.',
      );
    });
  }

  test(
    'generated regional voices are offered alongside Indonesian and English',
    () {
      expect(AppLanguage.offered, [
        AppLanguage.indonesian,
        AppLanguage.javanese,
        AppLanguage.sundanese,
        AppLanguage.english,
      ]);
    },
  );

  test('English comes first, for device languages the app does not offer', () {
    expect(offeredLocales.first, const Locale('en'));
    expect(offeredLocales.toSet(), {
      for (final language in AppLanguage.offered) Locale(language.code),
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

  test('clips still to record are named and not bundled yet', () {
    expect(VoiceClips.pending, isNotEmpty);
    for (final id in VoiceClips.pending) {
      expect(VoiceClips.all, contains(id), reason: id);
      for (final language in AppLanguage.values.where((l) => l.voiced)) {
        expect(
          File('assets/audio/${language.code}/$id.mp3').existsSync(),
          isFalse,
          reason: '$id is bundled for ${language.code}',
        );
      }
    }
  });

  test('a regional language speaks Indonesian until it has its own clip', () {
    expect(voiceClipPaths('tourGo', 'ace'), [
      'audio/ace/tourGo.mp3',
      'audio/id/tourGo.mp3',
    ]);
    expect(voiceClipPaths('tourGo', 'en'), ['audio/en/tourGo.mp3']);
  });
}
