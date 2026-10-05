import 'package:cobalagi/app/app.dart';
import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/core/entitlement/entitlement_service.dart';
import 'package:cobalagi/core/entitlement/plan.dart';
import 'package:cobalagi/core/settings/settings_repository.dart';
import 'package:cobalagi/features/profiles/data/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

Future<void> pumpApp(WidgetTester tester) async {
  // Landscape tablet, the primary target.
  tester.view.physicalSize = const Size(2560, 1600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final db = await tester.runAsync(
    () => newDatabaseFactoryMemory().openDatabase('test.db'),
  );
  await tester.pumpWidget(
    CobaLagiApp(
      profiles: ProfileRepository(db!),
      settings: SettingsRepository(db),
      entitlement: const StaticEntitlementService(Plan.free),
      audio: const SilentAudioService(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('free plan: add one player, then the add tile is locked', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text("Who's playing?"), findsOneWidget);

    await tester.tap(find.text('New player'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ayu');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Ayu'), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsOneWidget);

    await tester.tap(find.text('New player'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.textContaining('room for one player'), findsOneWidget);
  });

  testWidgets('parent gate blocks a wrong answer and admits the right one', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Parent area'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('parentGateAnswer')), '1');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Not quite. Try again.'), findsOneWidget);

    final question = find.textContaining(RegExp(r'What is \d+ × \d+\?'));
    final match = RegExp(
      r'(\d+) × (\d+)',
    ).firstMatch(tester.widget<Text>(question).data!)!;
    final answer = int.parse(match[1]!) * int.parse(match[2]!);
    await tester.enterText(
      find.byKey(const Key('parentGateAnswer')),
      '$answer',
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
  });
}
