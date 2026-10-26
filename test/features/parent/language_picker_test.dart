import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/settings/app_language.dart';
import 'package:cobalagi/core/settings/settings_cubit.dart';
import 'package:cobalagi/core/settings/settings_repository.dart';
import 'package:cobalagi/features/parent/view/language_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  testWidgets('lists the device, then Indonesian and English, then regional '
      'languages, and saves the choice', (tester) async {
    final db = await tester.runAsync(
      () => newDatabaseFactoryMemory().openDatabase('language.db'),
    );
    final cubit = SettingsCubit(SettingsRepository(db!));
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(body: LanguagePicker()),
        ),
      ),
    );
    expect(find.text('Same as device'), findsOneWidget);

    final regional = [
      for (final language in AppLanguage.offered)
        if (language.fallback != null) language.code,
    ];
    await tester.tap(find.byType(LanguagePicker));
    await tester.pumpAndSettle();
    final names = [
      'Same as device',
      for (final code in ['id', 'en', ...regional]) AppLanguage.of(code)!.name,
    ];
    final tops = [
      for (final name in names) tester.getTopLeft(find.text(name).last).dy,
    ];
    expect(tops, [...tops]..sort());
    expect(find.byType(Divider), findsNWidgets(2));

    await tester.tap(find.text('English').last);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(cubit.state, const Locale('en'));
    expect(find.text('English'), findsOneWidget);
  });
}
