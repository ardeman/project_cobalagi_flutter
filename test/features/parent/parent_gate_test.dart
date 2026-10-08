import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/features/parent/view/parent_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a phone held sideways with the keyboard up can still answer', (
    tester,
  ) async {
    // 800 × 360 dp, with a keyboard taking 230 dp.
    tester.view.physicalSize = const Size(2400, 1080);
    tester.view.devicePixelRatio = 3;
    tester.view.viewInsets = const FakeViewPadding(bottom: 690);
    addTearDown(tester.view.reset);
    bool? passed;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async => passed = await showParentGate(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // No overflow: the dialog scrolls instead, with the field in view above
    // the keyboard (360 - 230 = 130 dp left).
    expect(tester.takeException(), isNull);
    final field = tester.getRect(find.byKey(const Key('parentGateAnswer')));
    expect(field.top, greaterThanOrEqualTo(0));
    expect(field.bottom, lessThanOrEqualTo(130));
    final label = tester
        .widget<TextField>(find.byKey(const Key('parentGateAnswer')))
        .decoration!
        .labelText!;
    final [a, b] = [
      for (final m in RegExp(r'\d+').allMatches(label)) int.parse(m[0]!),
    ];
    await tester.enterText(
      find.byKey(const Key('parentGateAnswer')),
      '${a * b}',
    );
    await tester.ensureVisible(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(passed, isTrue);
  });
}
