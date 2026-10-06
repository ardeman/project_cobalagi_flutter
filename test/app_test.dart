import 'dart:async';

import 'package:cobalagi/app/app.dart';
import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/core/entitlement/entitlement_service.dart';
import 'package:cobalagi/core/entitlement/plan.dart';
import 'package:cobalagi/core/settings/settings_repository.dart';
import 'package:cobalagi/features/learning/data/curriculum_repository.dart';
import 'package:cobalagi/features/learning/data/progress_repository.dart';
import 'package:cobalagi/features/profiles/data/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sembast/sembast_memory.dart';

/// Free until [redeem] gets [goodCode].
class CodeEntitlementService extends StaticEntitlementService {
  CodeEntitlementService(this.goodCode) : super(Plan.free);

  final String goodCode;
  final _changes = StreamController<Plan>.broadcast();

  @override
  Stream<Plan> get changes => _changes.stream;

  @override
  Future<bool> redeem(String code) async {
    if (code != goodCode) return false;
    _changes.add(Plan.full);
    return true;
  }
}

Future<void> pumpApp(
  WidgetTester tester, {
  EntitlementService entitlement = const StaticEntitlementService(Plan.free),
}) async {
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
      entitlement: entitlement,
      audio: const SilentAudioService(),
      curriculum: CurriculumRepository(),
      progress: ProgressRepository(db),
    ),
  );
  // Past the splash screen.
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

Future<void> passParentGate(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Parent area'));
  await tester.pumpAndSettle();
  final question = find.textContaining(RegExp(r'What is \d+ × \d+\?'));
  final match = RegExp(
    r'(\d+) × (\d+)',
  ).firstMatch(tester.widget<Text>(question).data!)!;
  final answer = int.parse(match[1]!) * int.parse(match[2]!);
  await tester.enterText(find.byKey(const Key('parentGateAnswer')), '$answer');
  await tester.tap(find.text('OK'));
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

  testWidgets('the parent area shows the app version', (tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'Coba Lagi',
      packageName: 'com.ardeman.cobalagi',
      version: '1.0.0',
      buildNumber: '2',
      buildSignature: '',
    );
    await pumpApp(tester);
    await passParentGate(tester);
    await tester.scrollUntilVisible(find.text('App version 1.0.0 (2)'), 200);
    expect(find.text('App version 1.0.0 (2)'), findsOneWidget);
  });

  testWidgets('an unlock code in the parent area unlocks the supporter plan', (
    tester,
  ) async {
    await pumpApp(tester, entitlement: CodeEntitlementService('GOOD'));
    await passParentGate(tester);
    await tester.tap(find.text('Support Coba Lagi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Have a code?'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'BAD');
    await tester.tap(find.text('Use code'));
    await tester.pumpAndSettle();
    expect(find.textContaining("That code doesn't work"), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'GOOD');
    await tester.tap(find.text('Use code'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Thank you for supporting Coba Lagi!'), findsOneWidget);
  });

  group('progress report', () {
    // rootBundle caches asset loads started in an earlier test's fake clock,
    // which then never finish here.
    setUp(rootBundle.clear);

    Future<void> openProgress(WidgetTester tester, Plan plan) async {
      await pumpApp(tester, entitlement: StaticEntitlementService(plan));
      await tester.tap(find.text('New player'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Ayu');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await passParentGate(tester);
      await tester.tap(find.text('Ayu'));
      await tester.pumpAndSettle();
    }

    testWidgets('is a sponsor feature on the regular plan', (tester) async {
      await openProgress(tester, Plan.free);
      expect(find.text("Ayu's progress"), findsOneWidget);
      expect(find.text('Change starting island'), findsOneWidget);
      expect(find.textContaining('Sponsors see the full'), findsOneWidget);
      expect(find.text('Last 7 days'), findsNothing);
    });

    testWidgets('shows the report on the sponsor plan', (tester) async {
      await openProgress(tester, Plan.full);
      expect(find.text('Last 7 days'), findsOneWidget);
      expect(find.text('0 puzzles solved'), findsNWidgets(2));
      expect(find.text("Hasn't finished a puzzle yet"), findsOneWidget);
      expect(find.textContaining('Not started'), findsNWidgets(4));
      expect(find.textContaining('Sponsors see the full'), findsNothing);
    });
  });

  testWidgets('the app opens on a splash with the version', (tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'Coba Lagi',
      packageName: 'com.ardeman.cobalagi',
      version: '1.0.0',
      buildNumber: '3',
      buildSignature: '',
    );
    final db = await tester.runAsync(
      () => newDatabaseFactoryMemory().openDatabase('splash.db'),
    );
    await tester.pumpWidget(
      CobaLagiApp(
        profiles: ProfileRepository(db!),
        settings: SettingsRepository(db),
        entitlement: const StaticEntitlementService(Plan.free),
        audio: const SilentAudioService(),
        curriculum: CurriculumRepository(),
        progress: ProgressRepository(db),
      ),
    );
    await tester.pump();
    expect(find.text('App version 1.0.0 (3)'), findsOneWidget);
    expect(find.text("Who's playing?"), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text("Who's playing?"), findsOneWidget);
  });
}
