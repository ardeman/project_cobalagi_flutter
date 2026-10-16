import 'dart:async';

import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/gamepad/gamepad_cubit.dart';
import 'package:cobalagi/core/gamepad/gamepad_navigator.dart';
import 'package:cobalagi/core/gamepad/pad_badge.dart';
import 'package:cobalagi/core/gamepad/pad_input.dart';
import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/features/editors/blocks/cubit/blocks_cubit.dart';
import 'package:cobalagi/features/editors/blocks/view/block_editor.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cobalagi/features/editors/blocks/data/block.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'block_editor_test.dart' show pumpEditor;

/// Every control the highlight can reach from the first one with up, down,
/// left and right, as a controller's d-pad moves it.
Future<Set<FocusNode>> reachable(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pumpAndSettle();
  final start = FocusManager.instance.primaryFocus!;
  final seen = {start};
  final queue = [start];
  while (queue.isNotEmpty) {
    final node = queue.removeLast();
    for (final direction in TraversalDirection.values) {
      node.requestFocus();
      await tester.pump();
      FocusManager.instance.primaryFocus!.focusInDirection(direction);
      await tester.pumpAndSettle();
      final next = FocusManager.instance.primaryFocus!;
      if (seen.add(next)) queue.add(next);
    }
  }
  return seen;
}

/// The focus node of the tap target around a placed block.
FocusNode focusOf(WidgetTester tester, String blockId) => Focus.of(
  tester.element(
    find
        .descendant(
          of: find.byKey(ValueKey(blockId)).first,
          matching: find.byType(Icon),
        )
        .first,
  ),
);

const frame = Duration(milliseconds: 16);

void main() {
  testWidgets('the d-pad reaches every block, inside a repeat too', (
    tester,
  ) async {
    final cubit = await pumpEditor(tester);
    cubit
      ..add(BlockType.forward)
      ..add(BlockType.repeat);
    final repeat = cubit.state.main.last.id;
    cubit
      ..add(BlockType.turnLeft, parentId: repeat)
      ..add(BlockType.forward, parentId: repeat)
      ..add(BlockType.turnRight);
    await tester.pumpAndSettle();

    final seen = await reachable(tester);
    final placed = [
      for (final b in cubit.state.main) ...b.selfAndDescendants,
    ].where((b) => !b.type.isContainer);
    for (final block in placed) {
      expect(seen, contains(focusOf(tester, block.id)), reason: '$block');
    }
  });

  testWidgets('the d-pad reaches the Magic Block row and its blocks', (
    tester,
  ) async {
    final cubit = await pumpEditor(tester, star: true);
    cubit
      ..add(BlockType.forward, parentId: BlocksCubit.starRow)
      ..add(BlockType.turnLeft, parentId: BlocksCubit.starRow)
      ..add(BlockType.star)
      ..add(BlockType.forward);
    await tester.pumpAndSettle();

    final seen = await reachable(tester);
    for (final block in [...cubit.state.star, ...cubit.state.main]) {
      expect(seen, contains(focusOf(tester, block.id)), reason: '$block');
    }
  });

  testWidgets('A on a palette block adds it; on a placed block picks it', (
    tester,
  ) async {
    final cubit = await pumpEditor(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(cubit.state.main, hasLength(1));

    final placed = cubit.state.main.single.id;
    focusOf(tester, placed).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(cubit.state.pickedBlock, placed);
  });

  testWidgets('holding R2 carries a block; letting go puts it down', (
    tester,
  ) async {
    final pad = StreamController<PadCommand>();
    addTearDown(pad.close);
    final programKey = GlobalKey();
    final cubit = BlocksCubit()
      ..add(BlockType.forward)
      ..add(BlockType.turnLeft)
      ..add(BlockType.turnRight);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => GamepadCubit(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              GamepadNavigator(commands: pad.stream, child: child!),
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: SizedBox(
                width: 600,
                height: 500,
                child: BlockEditor(
                  programKey: programKey,
                  palette: {
                    InstructionKind.move,
                    InstructionKind.turnLeft,
                    InstructionKind.turnRight,
                  },
                  blockSize: 64,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Future<void> send(PadCommand command) async {
      pad.add(command);
      await tester.pumpAndSettle();
    }

    String order() => cubit.state.main.map((b) => b.type.name).join(' ');
    final first = cubit.state.main.first.id;

    // A on the program picks it and steps inside, onto its first block.
    Focus.of(
      tester.element(
        find
            .descendant(
              of: find.byKey(programKey),
              matching: find.byType(GestureDetector),
            )
            .first,
      ),
    ).requestFocus();
    await send(const PadPress(PadButton.a));
    expect(FocusManager.instance.primaryFocus, focusOf(tester, first));

    // Hold R2 on a block: it lifts. Let go: it lands.
    expect(find.text('R2'), findsOneWidget, reason: 'the ring shows R2');
    await send(const PadPress(PadButton.rightTrigger));
    expect(cubit.state.carrying, isTrue);
    await send(const PadMove(PadDirection.right));
    await send(const PadMove(PadDirection.right));
    expect(order(), 'turnLeft turnRight forward');
    // The highlight stays on the carried block as it moves.
    expect(
      FocusManager.instance.primaryFocus?.rect.center.dx,
      greaterThan(150),
    );
    await send(const PadRelease(PadButton.rightTrigger));
    expect(cubit.state.carrying, isFalse);
    expect(order(), 'turnLeft turnRight forward');

    // Carry again and change your mind: B puts it back.
    await send(const PadPress(PadButton.rightTrigger));
    await send(const PadMove(PadDirection.left));
    expect(order(), 'turnLeft forward turnRight');
    await send(const PadPress(PadButton.b));
    expect(order(), 'turnLeft turnRight forward');
    expect(cubit.state.carrying, isFalse);
    await send(const PadRelease(PadButton.rightTrigger));
    expect(order(), 'turnLeft turnRight forward');
    expect(find.byType(PadBadge), findsWidgets);
  });

  testWidgets('with R2 held, the stick drags freely, like a finger', (
    tester,
  ) async {
    final pad = StreamController<PadCommand>();
    addTearDown(pad.close);
    final cubit = BlocksCubit()
      ..add(BlockType.forward)
      ..add(BlockType.turnLeft)
      ..add(BlockType.turnRight);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => GamepadCubit(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              GamepadNavigator(commands: pad.stream, child: child!),
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: const SizedBox(
                width: 600,
                height: 500,
                child: BlockEditor(
                  palette: {
                    InstructionKind.move,
                    InstructionKind.turnLeft,
                    InstructionKind.turnRight,
                  },
                  blockSize: 64,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    String order() => cubit.state.main.map((b) => b.type.name).join(' ');
    Future<void> hold(Offset aim, Duration time) async {
      pad.add(PadAim(aim.dx, aim.dy));
      for (var t = Duration.zero; t < time; t += frame) {
        await tester.pump(frame);
      }
      pad.add(const PadAim(0, 0));
      await tester.pump(frame);
    }

    // A placed block, dragged right past the others.
    focusOf(tester, cubit.state.main.first.id).requestFocus();
    await tester.pump();
    pad.add(const PadPress(PadButton.rightTrigger));
    await tester.pump(frame);
    await hold(const Offset(1, 0), const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.touch_app_rounded), findsOneWidget);
    pad.add(const PadRelease(PadButton.rightTrigger));
    await tester.pumpAndSettle();
    expect(order(), 'turnLeft turnRight forward');
    expect(find.byIcon(Icons.touch_app_rounded), findsNothing);

    // A palette block, dragged down into the program.
    final palette = tester.getCenter(
      find.byIcon(Icons.turn_left_rounded).first,
    );
    final program = tester.getCenter(find.byIcon(Icons.turn_left_rounded).last);
    Focus.of(
      tester.element(find.byIcon(Icons.turn_left_rounded).first),
    ).requestFocus();
    await tester.pump();
    pad.add(const PadPress(PadButton.rightTrigger));
    await tester.pump(frame);
    final down = (program.dy - palette.dy) / 900;
    await hold(
      const Offset(0, 1),
      Duration(milliseconds: (down * 1000).round()),
    );
    pad.add(const PadRelease(PadButton.rightTrigger));
    await tester.pumpAndSettle();
    expect(cubit.state.main, hasLength(4));

    // A new block drags on from where it showed up in the program, even
    // with the highlight left on the palette: never a second new block.
    final paletteBlock = find.byIcon(Icons.turn_right_rounded).first;
    Focus.of(tester.element(paletteBlock)).requestFocus();
    await tester.pump();
    pad.add(const PadPress(PadButton.rightTrigger));
    await tester.pump(frame);
    expect(cubit.state.main, hasLength(5));
    Focus.of(tester.element(paletteBlock)).requestFocus();
    await tester.pump();
    await hold(const Offset(-1, 0), const Duration(milliseconds: 200));
    pad.add(const PadRelease(PadButton.rightTrigger));
    await tester.pumpAndSettle();
    expect(cubit.state.main, hasLength(5));
  });
}
