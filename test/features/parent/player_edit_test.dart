import 'package:cobalagi/app/app.dart';
import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/core/entitlement/entitlement_service.dart';
import 'package:cobalagi/core/entitlement/plan.dart';
import 'package:cobalagi/core/settings/settings_repository.dart';
import 'package:cobalagi/core/widgets/typing_dialog.dart';
import 'package:cobalagi/features/learning/data/curriculum_repository.dart';
import 'package:cobalagi/features/learning/data/progress_repository.dart';
import 'package:cobalagi/features/profiles/data/profile_repository.dart';
import 'package:cobalagi/features/profiles/view/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sembast/sembast_memory.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Opens [path] in the app with one player, Eclo.
Future<void> _open(WidgetTester tester, String path) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = await tester.runAsync(() async {
    final db = await newDatabaseFactoryMemory().openDatabase('edit.db');
    await ProfileRepository(db).add(nickname: 'Eclo', avatar: 0);
    return db;
  });
  await tester.pumpWidget(
    CobaLagiApp(
      profiles: ProfileRepository(db!),
      settings: SettingsRepository(db),
      entitlement: const StaticEntitlementService(Plan.full),
      audio: const SilentAudioService(),
      curriculum: CurriculumRepository(),
      progress: ProgressRepository(db),
    ),
  );
  // Past the splash screen.
  await tester.pump(const Duration(seconds: 2));
  await _settle(tester);
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
  // The page slides in, then loads the player.
  await _settle(tester);
  final loading = find.byType(CircularProgressIndicator);
  for (var i = 0; i < 10 && loading.evaluate().isNotEmpty; i++) {
    await _settle(tester);
  }
}

void main() {
  // Assets cached by an earlier test never finish loading in the next one.
  setUp(rootBundle.clear);

  testWidgets('tapping the name on the progress screen edits the player', (
    tester,
  ) async {
    await _open(tester, '/parent/progress/1');
    await tester.tap(find.text('Eclo').hitTestable().last);
    await _settle(tester);
    expect(find.byType(TypingDialog), findsOneWidget);
  });

  testWidgets('tapping the avatar on the progress screen edits the player', (
    tester,
  ) async {
    await _open(tester, '/parent/progress/1');
    await tester.tap(find.byType(ProfileAvatar).hitTestable());
    await _settle(tester);
    expect(find.byType(TypingDialog), findsOneWidget);
  });

  testWidgets('Edit and Delete sit apart in the parent area', (tester) async {
    await _open(tester, '/parent');
    final edit = tester.getRect(
      find.widgetWithIcon(IconButton, Icons.edit_outlined),
    );
    final delete = tester.getRect(
      find.widgetWithIcon(IconButton, Icons.delete_outline),
    );
    expect(edit.width, greaterThanOrEqualTo(64));
    expect(delete.width, greaterThanOrEqualTo(64));
    expect(delete.left - edit.right, greaterThanOrEqualTo(24));
  });
}
