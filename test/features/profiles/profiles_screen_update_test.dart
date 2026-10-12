import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/entitlement/entitlement_cubit.dart';
import 'package:cobalagi/core/entitlement/entitlement_service.dart';
import 'package:cobalagi/core/entitlement/plan.dart';
import 'package:cobalagi/features/profiles/cubit/profiles_cubit.dart';
import 'package:cobalagi/features/profiles/data/profile_repository.dart';
import 'package:cobalagi/features/profiles/view/profiles_screen.dart';
import 'package:cobalagi/features/splash/cubit/app_update_cubit.dart';
import 'package:cobalagi/features/splash/data/app_update_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

class _Update implements AppUpdateService {
  @override
  Future<AvailableUpdate?> check() async =>
      const AvailableUpdate(buildNumber: 9);

  @override
  Future<bool> openUpdate(AvailableUpdate update) async => false;
}

void main() {
  testWidgets('an update found after the splash is offered on the picker', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (profiles, updates) = (await tester.runAsync(() async {
      final db = await newDatabaseFactoryMemory().openDatabase('t.db');
      final profiles = ProfilesCubit(ProfileRepository(db));
      await profiles.load();
      final updates = AppUpdateCubit(_Update());
      await updates.check();
      return (profiles, updates);
    }))!;
    addTearDown(profiles.close);
    addTearDown(updates.close);
    final entitlement = EntitlementCubit(
      const StaticEntitlementService(Plan.free),
    );
    addTearDown(entitlement.close);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: profiles),
          BlocProvider.value(value: updates),
          BlocProvider.value(value: entitlement),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: ProfilesScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('An update is available'), findsOneWidget);
    await tester.tap(find.text('Continue playing'));
    await tester.pump();
    expect(find.text('An update is available'), findsNothing);
  });
}
