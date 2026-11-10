import 'dart:convert';
import 'dart:io';

import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/core/widgets/glass_surface.dart';
import 'package:cobalagi/engine/world/level.dart';
import 'package:cobalagi/features/examples/cubit/sorting_cubit.dart';
import 'package:cobalagi/features/examples/view/example_picture.dart';
import 'package:cobalagi/features/examples/view/sorting_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

List<Level> _lessons() {
  final json =
      jsonDecode(File('assets/levels/examples.json').readAsStringSync())
          as Map<String, Object?>;
  return [
    for (final level in (json['levels']! as List).cast<Map<String, Object?>>())
      Level.fromJson(level),
  ];
}

void main() {
  final lessons = _lessons();
  final first = lessons.firstWhere((level) => level.id == 'examples-01');
  final second = lessons.firstWhere((level) => level.id == 'examples-02');

  test('a wrong bin shakes the picture back', () {
    final cubit = SortingCubit(first);
    addTearDown(cubit.close);
    final index = cubit.loose.first;
    cubit.pick(index);
    cubit.place(!first.examples[index].safe);
    expect(cubit.state.placed, isEmpty);
    expect(cubit.state.wobble, index);
    expect(cubit.state.phase, SortingPhase.placing);
  });

  test('lesson 1 is right once the pictures are sorted', () {
    final cubit = SortingCubit(first);
    addTearDown(cubit.close);
    for (final index in first.rounds.first.show) {
      cubit.pick(index);
      cubit.place(first.examples[index].safe);
    }
    expect(cubit.state.phase, SortingPhase.results);
    expect(cubit.guessesRight, isTrue);
  });

  test('lesson 2 is wrong until the pictures are varied', () {
    final cubit = SortingCubit(second);
    addTearDown(cubit.close);
    for (final index in second.rounds.first.show) {
      cubit.pick(index);
      cubit.place(second.examples[index].safe);
    }
    expect(cubit.guessesRight, isFalse);
    cubit.morePictures();
    expect(cubit.state.phase, SortingPhase.placing);
    for (final index in cubit.loose) {
      cubit.pick(index);
      cubit.place(second.examples[index].safe);
    }
    expect(cubit.guessesRight, isTrue);
  });

  testWidgets('sorting the first lesson opens the puzzle', (tester) async {
    var done = false;
    await tester.pumpWidget(
      RepositoryProvider<AudioService>.value(
        value: const SilentAudioService(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SortingScreen(
            level: first,
            homePath: '/child/1',
            onDone: () => done = true,
          ),
        ),
      ),
    );
    await tester.pump();
    final pictures = find.byType(ExamplePicture);
    expect(pictures, findsNWidgets(first.rounds.first.show.length));
    for (final index in first.rounds.first.show) {
      final thing = first.examples[index].thing;
      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is ExamplePicture && widget.thing == thing,
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byType(GlassSurface).at(first.examples[index].safe ? 0 : 1),
      );
      await tester.pump();
    }
    expect(find.text("Let's go!"), findsOneWidget);
    await tester.tap(find.text("Let's go!"));
    await tester.pump();
    expect(done, isTrue);
  });
}
