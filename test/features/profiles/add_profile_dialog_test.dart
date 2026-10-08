import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/features/profiles/view/add_profile_dialog.dart';
import 'package:cobalagi/features/profiles/view/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Enter after the name leaves time to choose an avatar', (
    tester,
  ) async {
    (String, int)? result;
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showProfileDialog(context);
              closed = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Eclo');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(closed, isFalse);
    expect(find.text('New player'), findsOneWidget);

    await tester.tap(find.byType(ProfileAvatar).at(2));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(result, ('Eclo', 2));
  });

  testWidgets('editing opens with the player\'s name and avatar', (
    tester,
  ) async {
    (String, int)? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showProfileDialog(
              context,
              nickname: 'Eclo',
              avatar: 3,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Edit player'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Eclo'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Gito');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result, ('Gito', 3));
  });
}
