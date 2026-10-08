import 'dart:async';

import 'package:cobalagi/app/app.dart';
import 'package:cobalagi/features/splash/data/app_update_service.dart';
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

/// Remembers the music and effects settings the app applies.
class RecordingAudio extends SilentAudioService {
  bool? music;
  bool? effects;

  @override
  set musicOn(bool on) => music = on;

  @override
  set effectsOn(bool on) => effects = on;
}

Future<void> pumpApp(
  WidgetTester tester, {
  AudioService audio = const SilentAudioService(),
  EntitlementService entitlement = const StaticEntitlementService(Plan.free),
  AppUpdateService updates = const NoAppUpdateService(),
  Size size = const Size(2560, 1600),
}) async {
  // Landscape tablet, the primary target.
  tester.view.physicalSize = size;
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
      updates: updates,
      audio: audio,
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

class AvailableUpdateService implements AppUpdateService {
  var opened = 0;

  @override
  Future<AvailableUpdate?> check() async =>
      const AvailableUpdate(buildNumber: 6);

  @override
  Future<bool> openUpdate(AvailableUpdate update) async {
    opened++;
    return true;
  }
}

void main() {
  testWidgets('launch update can be skipped without opening a store', (
    tester,
  ) async {
    final updates = AvailableUpdateService();
    await pumpApp(tester, updates: updates);
    expect(find.text('An update is available'), findsOneWidget);
    expect(find.textContaining('A newer version of Coba Lagi'), findsOneWidget);
    await tester.tap(find.text('Continue playing'));
    await tester.pumpAndSettle();
    expect(find.text("Who's playing?"), findsOneWidget);
    expect(updates.opened, 0);
  });

  testWidgets('launch notice can be skipped on a small portrait phone', (
    tester,
  ) async {
    final updates = AvailableUpdateService();
    await pumpApp(tester, updates: updates, size: const Size(640, 1200));
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Continue playing'));
    await tester.tap(find.text('Continue playing'));
    await tester.pumpAndSettle();
    expect(find.text("Who's playing?"), findsOneWidget);
    expect(updates.opened, 0);
  });

  testWidgets('launch update requires a successful parent gate', (
    tester,
  ) async {
    final updates = AvailableUpdateService();
    await pumpApp(tester, updates: updates);
    await tester.tap(find.text('Ask a grown-up to update'));
    await tester.pumpAndSettle();
    expect(updates.opened, 0);
    await tester.enterText(find.byKey(const Key('parentGateAnswer')), '0');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(updates.opened, 0);
    final question = tester
        .widget<TextField>(find.byType(TextField))
        .decoration!
        .labelText!;
    final numbers = RegExp(r'(\d+) × (\d+)').firstMatch(question)!;
    final answer = int.parse(numbers[1]!) * int.parse(numbers[2]!);
    await tester.enterText(
      find.byKey(const Key('parentGateAnswer')),
      '$answer',
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(updates.opened, 1);
    await tester.tap(find.text('Continue playing'));
    await tester.pumpAndSettle();
  });

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
    // The first heading starts below the glass app bar, not under it.
    expect(
      tester.getTopLeft(find.text('Language')).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.byType(AppBar)).dy),
    );
  });

  testWidgets('music and effects settings apply at launch', (tester) async {
    final audio = RecordingAudio();
    await pumpApp(tester, audio: audio);
    // Before anyone opens the parent area.
    expect(audio.music, isTrue);
    expect(audio.effects, isTrue);
  });

  testWidgets('a parent can set a break reminder, even on a small phone', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(720, 1280));
    await passParentGate(tester);
    // Scroll it to the middle, clear of the glass bar over the page.
    await tester.scrollUntilVisible(find.text('30 min'), 200);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 min'));
    await tester.pumpAndSettle();
    final picked = tester.widget<SegmentedButton<int>>(
      find.byType(SegmentedButton<int>),
    );
    expect(picked.selected, {30});
    expect(tester.takeException(), isNull);
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
      await tester.scrollUntilVisible(find.text('Ayu'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ayu'));
      await tester.pumpAndSettle();
    }

    testWidgets('is a sponsor feature on the regular plan', (tester) async {
      await openProgress(tester, Plan.free);
      expect(find.text("Ayu's progress"), findsOneWidget);
      expect(find.text('Change starting planet'), findsOneWidget);
      expect(find.textContaining('Sponsors see the full'), findsOneWidget);
      expect(find.text('Last 7 days'), findsNothing);
    });

    testWidgets('a parent can turn on the Code tab', (tester) async {
      await openProgress(tester, Plan.free);
      expect(find.text('Code tab'), findsOneWidget);
      await tester.tap(find.text('Code tab'));
      await tester.pumpAndSettle();
      final tile = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Code tab'),
      );
      expect(tile.value, isTrue);
    });

    testWidgets('shows the report on the sponsor plan', (tester) async {
      await openProgress(tester, Plan.full);
      expect(find.text('Last 7 days'), findsOneWidget);
      expect(find.text('0 puzzles solved'), findsNWidgets(2));
      expect(find.text("Hasn't finished a puzzle yet"), findsOneWidget);
      // Every coding island; the Warm-up island isn't on the report.
      expect(find.textContaining('Not started'), findsNWidgets(9));
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
