import 'dart:io';

import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/app/theme/app_theme.dart';
import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/features/editors/blocks/cubit/blocks_cubit.dart';
import 'package:cobalagi/features/editors/blocks/data/block.dart';
import 'package:cobalagi/features/editors/blocks/view/block_editor.dart';
import 'package:cobalagi/features/tutorial/data/tutorial.dart';
import 'package:cobalagi/features/tutorial/view/tutorial_view.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the voice clips the demo asks for.
class _Voices extends SilentAudioService {
  final played = <String>[];

  @override
  Future<void> playVoice(
    String clipId, {
    required String languageCode,
    bool queue = false,
  }) async => played.add(clipId);
}

final _tutorials = parseTutorials(
  File('assets/config/tutorials.json').readAsStringSync(),
);

Future<void> _pump(
  WidgetTester tester,
  Tutorial tutorial, {
  required VoidCallback onDone,
  AudioService audio = const SilentAudioService(),
}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: RepositoryProvider<AudioService>.value(
        value: audio,
        child: TutorialView(tutorial: tutorial, onDone: onDone),
      ),
    ),
  );
}

/// Lets the demo play: timers, world animations and all.
Future<void> _watch(WidgetTester tester, {int seconds = 40}) async {
  for (var i = 0; i < seconds * 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

BlocksCubit _blocks(WidgetTester tester) =>
    tester.element(find.byType(BlockEditor)).read<BlocksCubit>();

void main() {
  testWidgets('the Fix it! demo runs, fixes the turn and offers to play', (
    tester,
  ) async {
    var done = 0;
    final voices = _Voices();
    await _pump(
      tester,
      _tutorials['debugging']!,
      onDone: () => done++,
      audio: voices,
    );
    expect(find.text('Watch me! Fix it!'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    // It opens with the bugged blocks and the island's explanation.
    expect(_blocks(tester).state.main.map((b) => b.type), [
      BlockType.forward,
      BlockType.forward,
      BlockType.turnLeft,
      BlockType.forward,
    ]);
    await tester.pump();
    expect(voices.played, ['tutorial_debugging']);
    await _watch(tester);
    // The wrong turn was swapped for the right one, in place.
    expect(_blocks(tester).state.main.map((b) => b.type), [
      BlockType.forward,
      BlockType.forward,
      BlockType.turnRight,
      BlockType.forward,
    ]);
    expect(find.text('Watch again'), findsOneWidget);
    await tester.tap(find.text("Let's play!"));
    expect(done, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('watch again starts the demo over from empty', (tester) async {
    await _pump(tester, _tutorials['loops']!, onDone: () {});
    await _watch(tester);
    expect(_blocks(tester).state.main, hasLength(1));
    await tester.tap(find.text('Watch again'));
    await tester.pump();
    await tester.pump();
    expect(_blocks(tester).state.main, isEmpty);
    expect(find.text('Skip'), findsOneWidget);
    await _watch(tester);
    expect(find.text('Watch again'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(1280, 800), Size(412, 915)]) {
    testWidgets('the end of the demo moves nothing ($size)', (tester) async {
      await _pump(tester, _tutorials['variables']!, onDone: () {});
      tester.view.physicalSize = size;
      await tester.pump(const Duration(seconds: 1));
      Rect world() =>
          tester.getRect(find.byWidgetPredicate((w) => w is GameWidget).first);
      Rect editor() => tester.getRect(find.byType(BlockEditor).first);
      final worldBefore = world();
      final editorBefore = editor();
      // The end buttons wait hidden: they can't be tapped yet.
      expect(find.text("Let's play!").hitTestable(), findsNothing);
      await _watch(tester);
      expect(find.text("Let's play!").hitTestable(), findsOneWidget);
      expect(world(), worldBefore);
      // The editor grows with the demo's blocks, but stays where it was.
      expect(editor().topLeft, editorBefore.topLeft);
      // The demo's Go, only for show, has faded away.
      final go = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.text('Go!'),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(go.opacity, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('skip leaves at once', (tester) async {
    var done = 0;
    await _pump(tester, _tutorials['directions']!, onDone: () => done++);
    await tester.tap(find.text('Skip'));
    expect(done, 1);
    // Leaving mid-demo stops the script without errors.
    await tester.pumpWidget(const SizedBox());
    await _watch(tester, seconds: 5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving while the robot rolls ends quietly', (tester) async {
    await _pump(tester, _tutorials['loops']!, onDone: () {});
    // Long enough for the hand to press Go, not for the walk to end.
    for (var i = 0; i < 70; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpWidget(const SizedBox());
    await _watch(tester, seconds: 10);
    expect(tester.takeException(), isNull);
  });
}
