import 'dart:async';

import 'package:cobalagi/core/gamepad/gamepad_capture.dart';
import 'package:cobalagi/core/gamepad/gamepad_cubit.dart';
import 'package:cobalagi/core/gamepad/gamepad_navigator.dart';
import 'package:cobalagi/core/gamepad/gamepad_shortcut.dart';
import 'package:cobalagi/core/gamepad/pad_badge.dart';
import 'package:cobalagi/core/gamepad/pad_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// A screen with two buttons, Go on X, and a dialog with B on its close.
Future<StreamController<PadCommand>> pumpPad(
  WidgetTester tester, {
  required List<String> log,
  bool capture = false,
}) async {
  final pad = StreamController<PadCommand>();
  addTearDown(pad.close);
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => GamepadCubit(),
      child: MaterialApp(
        builder: (context, child) =>
            GamepadNavigator(commands: pad.stream, child: child!),
        home: Scaffold(
          body: Builder(
            builder: (context) => Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: () => log.add('top'),
                      child: const Text('top'),
                    ),
                    const SizedBox(height: 40),
                    FilledButton(
                      onPressed: () => log.add('bottom'),
                      child: const Text('bottom'),
                    ),
                    const SizedBox(height: 40),
                    GamepadShortcut(
                      button: PadButton.x,
                      onPressed: () => log.add('go'),
                      child: FilledButton(
                        onPressed: () => log.add('go'),
                        child: const Text('go'),
                      ),
                    ),
                    TextButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => const AlertDialog(
                          content: Text('dialog'),
                          actions: [CloseButton()],
                        ),
                      ),
                      child: const Text('open'),
                    ),
                  ],
                ),
                if (capture)
                  Positioned.fill(
                    child: GamepadCapture(
                      onBack: () => log.add('skip'),
                      child: Center(
                        child: FilledButton(
                          autofocus: true,
                          onPressed: () => log.add('next'),
                          child: const Text('next'),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  return pad;
}

Future<void> send(
  WidgetTester tester,
  StreamController<PadCommand> pad,
  PadCommand command,
) async {
  pad.add(command);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the stick moves the highlight and A presses it', (tester) async {
    final log = <String>[];
    final pad = await pumpPad(tester, log: log);
    await send(tester, pad, const PadMove(PadDirection.down));
    await send(tester, pad, const PadPress(PadButton.a));
    expect(log, ['top']);
    await send(tester, pad, const PadMove(PadDirection.down));
    await send(tester, pad, const PadPress(PadButton.a));
    expect(log, ['top', 'bottom']);
    await send(tester, pad, const PadMove(PadDirection.up));
    await send(tester, pad, const PadPress(PadButton.a));
    expect(log, ['top', 'bottom', 'top']);
  });

  testWidgets('a shortcut presses its control and shows its badge', (
    tester,
  ) async {
    final log = <String>[];
    final pad = await pumpPad(tester, log: log);
    expect(find.byType(PadBadge), findsNothing, reason: 'no controller yet');
    await send(tester, pad, const PadPress(PadButton.x));
    expect(log, ['go']);
    expect(find.byType(PadBadge), findsOneWidget);
    expect(find.text('X'), findsOneWidget);

    // Touching the screen hides the badges until the controller is used.
    await tester.tap(find.text('top'));
    await tester.pumpAndSettle();
    expect(find.byType(PadBadge), findsNothing);
  });

  testWidgets('a dialog blocks the screen\'s shortcuts, and B closes it', (
    tester,
  ) async {
    final log = <String>[];
    final pad = await pumpPad(tester, log: log);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await send(tester, pad, const PadPress(PadButton.x));
    expect(log, isEmpty);
    // The dialog takes focus once the highlight moves into it.
    await send(tester, pad, const PadMove(PadDirection.down));
    await send(tester, pad, const PadPress(PadButton.b));
    expect(find.text('dialog'), findsNothing);
    await send(tester, pad, const PadPress(PadButton.x));
    expect(log, ['go']);
  });

  testWidgets('a capture (a tour) keeps the highlight and B skips it', (
    tester,
  ) async {
    final log = <String>[];
    final pad = await pumpPad(tester, log: log, capture: true);
    await send(tester, pad, const PadPress(PadButton.x));
    expect(log, isEmpty, reason: 'shortcuts wait during the tour');
    await send(tester, pad, const PadMove(PadDirection.up));
    await send(tester, pad, const PadPress(PadButton.a));
    expect(log, ['next'], reason: 'the highlight stays on the tour');
    await send(tester, pad, const PadPress(PadButton.b));
    expect(log, ['next', 'skip']);
  });
}
