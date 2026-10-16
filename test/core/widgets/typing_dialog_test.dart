import 'dart:async';

import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/gamepad/gamepad_cubit.dart';
import 'package:cobalagi/core/gamepad/gamepad_navigator.dart';
import 'package:cobalagi/core/gamepad/pad_input.dart';
import 'package:cobalagi/core/gamepad/screen_keyboard.dart';
import 'package:cobalagi/core/widgets/typing_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// A typing dialog under the controller, logging its buttons and every
/// keyboard request.
Future<StreamController<PadCommand>> pumpDialog(
  WidgetTester tester,
  List<String> log,
) async {
  final pad = StreamController<PadCommand>();
  addTearDown(pad.close);
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => GamepadCubit(),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => GamepadNavigator(
          commands: pad.stream,
          child: ScreenKeyboardOnFocus(
            keyboard: ScreenKeyboard(
              show: () => log.add('keyboard'),
              hide: () => log.add('keyboard closed'),
              covers: 0.5,
            ),
            child: child!,
          ),
        ),
        home: Scaffold(
          body: TypingDialog(
            title: const Text('Name'),
            content: const TextField(),
            confirmLabel: 'Save',
            onConfirm: () => log.add('save'),
            onCancel: () => log.add('cancel'),
          ),
        ),
      ),
    ),
  );
  return pad;
}

void main() {
  testWidgets('X saves and B cancels', (tester) async {
    final log = <String>[];
    final pad = await pumpDialog(tester, log);
    pad.add(const PadPress(PadButton.x));
    await tester.pumpAndSettle();
    pad.add(const PadPress(PadButton.b));
    await tester.pumpAndSettle();
    expect(log, ['save', 'cancel']);
  });

  testWidgets('focusing the text field asks for the keyboard once', (
    tester,
  ) async {
    final log = <String>[];
    await pumpDialog(tester, log);
    expect(log, isEmpty);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(log, ['keyboard']);
  });

  testWidgets('leaving the text field closes the keyboard', (tester) async {
    final log = <String>[];
    await pumpDialog(tester, log);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    FocusManager.instance.primaryFocus!.unfocus();
    await tester.pump();
    expect(log, ['keyboard', 'keyboard closed']);
  });

  testWidgets('the dialog moves above the keyboard while it shows', (
    tester,
  ) async {
    await pumpDialog(tester, []);
    final height =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('Save')).bottom, lessThan(height / 2));
    FocusManager.instance.primaryFocus!.unfocus();
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('Save')).bottom, greaterThan(height / 2));
  });
}
