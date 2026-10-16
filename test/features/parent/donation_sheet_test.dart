import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/entitlement/entitlement_cubit.dart';
import 'package:cobalagi/core/entitlement/entitlement_service.dart';
import 'package:cobalagi/core/entitlement/plan.dart';
import 'package:cobalagi/core/entitlement/store_rules.dart';
import 'package:cobalagi/features/parent/view/donation_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openSheet(WidgetTester tester, StoreRules rules) async {
  final cubit = EntitlementCubit(const StaticEntitlementService(Plan.free));
  addTearDown(cubit.close);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: RepositoryProvider.value(
        value: rules,
        child: BlocProvider.value(
          value: cubit,
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showDonationSheet(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Google Play and GitHub builds offer donations and codes', (
    tester,
  ) async {
    await openSheet(tester, const StoreRules(appStore: false));
    expect(find.textContaining('A donation of any size'), findsOneWidget);
    expect(find.text('Restore an earlier donation'), findsOneWidget);
    expect(find.text('Have a code?'), findsOneWidget);
  });

  testWidgets('App Store builds say tips and offer no unlock code', (
    tester,
  ) async {
    await openSheet(tester, const StoreRules(appStore: true));
    expect(find.textContaining('A tip of any size'), findsOneWidget);
    expect(find.text('Tips aren\'t available on this device.'), findsOneWidget);
    expect(find.text('Restore purchases'), findsOneWidget);
    expect(find.text('Have a code?'), findsNothing);
    expect(
      find.textContaining(RegExp('donat', caseSensitive: false)),
      findsNothing,
    );
  });

  test('iOS builds follow App Store rules; Android builds do not', () {
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(StoreRules.current().allowsUnlockCodes, isFalse);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(StoreRules.current().allowsUnlockCodes, isTrue);
  });

  test('store billing: Google Play and the App Stores only', () {
    const github = StoreRules(appStore: false);
    const appStore = StoreRules(appStore: true);
    expect(github.storeBilling(TargetPlatform.android), isTrue);
    expect(github.storeBilling(TargetPlatform.macOS), isFalse);
    expect(github.storeBilling(TargetPlatform.windows), isFalse);
    expect(github.storeBilling(TargetPlatform.linux), isFalse);
    expect(appStore.storeBilling(TargetPlatform.iOS), isTrue);
    expect(appStore.storeBilling(TargetPlatform.macOS), isTrue);
  });
}
