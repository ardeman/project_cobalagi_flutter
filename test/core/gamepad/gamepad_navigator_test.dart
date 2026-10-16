import 'dart:async';

import 'package:cobalagi/core/gamepad/gamepad_capture.dart';
import 'package:cobalagi/core/gamepad/gamepad_cubit.dart';
import 'package:cobalagi/core/gamepad/gamepad_navigator.dart';
import 'package:cobalagi/core/gamepad/gamepad_shortcut.dart';
import 'package:cobalagi/core/gamepad/pad_badge.dart';
import 'package:cobalagi/core/gamepad/pad_input.dart';
import 'package:cobalagi/core/widgets/glass_app_bar.dart';
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FilledButton(
                              autofocus: true,
                              onPressed: () => log.add('next'),
                              child: const Text('next'),
                            ),
                            GamepadShortcut(
                              button: PadButton.menu,
                              onPressed: () => log.add('listen'),
                              child: IconButton(
                                onPressed: () => log.add('listen'),
                                icon: const Icon(Icons.volume_up),
                              ),
                            ),
                          ],
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

    // Go has its own button (X), so the highlight skips it.
    await send(tester, pad, const PadMove(PadDirection.down));
    await send(tester, pad, const PadMove(PadDirection.down));
    await send(tester, pad, const PadPress(PadButton.a));
    expect(log, ['top', 'bottom', 'top'], reason: 'it opened the dialog');
    expect(find.text('dialog'), findsOneWidget);
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

  testWidgets('the back arrow an app bar adds by itself is on B', (
    tester,
  ) async {
    final pad = StreamController<PadCommand>();
    addTearDown(pad.close);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => GamepadCubit(),
        child: MaterialApp(
          navigatorKey: navigator,
          builder: (context, child) =>
              GamepadNavigator(commands: pad.stream, child: child!),
          home: const Scaffold(body: Text('home')),
        ),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const Scaffold(appBar: GlassAppBar(title: Text('parent area'))),
      ),
    );
    await tester.pumpAndSettle();
    // Any controller input shows the badges.
    await send(tester, pad, const PadMove(PadDirection.down));
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.byType(PadBadge)),
      findsOneWidget,
    );
    expect(find.text('B'), findsOneWidget);
    await send(tester, pad, const PadPress(PadButton.b));
    expect(find.text('parent area'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('a capture (a tour) keeps the highlight and B skips it', (
    tester,
  ) async {
    final log = <String>[];
    final pad = await pumpPad(tester, log: log, capture: true);
    await send(tester, pad, const PadPress(PadButton.x));
    expect(log, isEmpty, reason: 'shortcuts wait during the tour');
    expect(find.text('X'), findsNothing, reason: 'a paused badge hides');
    expect(find.byType(PadBadge), findsOneWidget, reason: "the tour's own");
    await send(tester, pad, const PadMove(PadDirection.up));
    await send(tester, pad, const PadPress(PadButton.a));
    expect(log, ['next'], reason: 'the highlight stays on the tour');
    // Its own shortcuts work.
    await send(tester, pad, const PadPress(PadButton.menu));
    expect(log, ['next', 'listen']);
    await send(tester, pad, const PadPress(PadButton.b));
    expect(log, ['next', 'listen', 'skip']);
  });

  testWidgets('the right stick scrolls the list the highlight is in', (
    tester,
  ) async {
    final pad = StreamController<PadCommand>();
    addTearDown(pad.close);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => GamepadCubit(),
        child: MaterialApp(
          builder: (context, child) =>
              GamepadNavigator(commands: pad.stream, child: child!),
          home: Scaffold(
            body: ListView(
              controller: controller,
              children: [
                for (var i = 0; i < 40; i++)
                  TextButton(onPressed: () {}, child: Text('item $i')),
              ],
            ),
          ),
        ),
      ),
    );
    pad.add(const PadScroll(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final scrolled = controller.offset;
    expect(scrolled, greaterThan(300));
    pad.add(const PadScroll(0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(controller.offset, scrolled, reason: 'it stops when let go');
  });
}
