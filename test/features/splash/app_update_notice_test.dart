import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/app/theme/app_theme.dart';
import 'package:cobalagi/features/splash/cubit/app_update_cubit.dart';
import 'package:cobalagi/features/splash/data/app_update_service.dart';
import 'package:cobalagi/features/splash/view/app_update_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final language in ['en', 'id']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$language notice fits a narrow phone at text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        var continued = false;
        var requested = false;
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: AppUpdateNotice(
                    state: const AppUpdateState(
                      status: UpdateStatus.ready,
                      update: AvailableUpdate(buildNumber: 6),
                    ),
                    onUpdate: () => requested = true,
                    onContinue: () => continued = true,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final button in [
          find.byType(FilledButton),
          find.byType(TextButton),
        ]) {
          expect(tester.getSize(button).height, greaterThanOrEqualTo(64));
          expect(tester.getTopLeft(button).dx, greaterThanOrEqualTo(0));
          expect(tester.getTopRight(button).dx, lessThanOrEqualTo(320));
        }
        await tester.ensureVisible(find.byType(TextButton));
        await tester.tap(find.byType(TextButton));
        expect(continued, isTrue);
        expect(requested, isFalse);
      });
    }
  }
}
