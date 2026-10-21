import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cobalagi/core/audio/voice_clips.dart';
import 'package:cobalagi/features/story/data/story_art.dart';
import 'package:cobalagi/features/story/data/story_scene.dart';
import 'package:cobalagi/engine/interpreter/run_event.dart';
import 'package:cobalagi/features/story/view/arrival_scenes.dart';
import 'package:cobalagi/features/story/view/board_arrival.dart';
import 'package:cobalagi/features/story/view/ending_scenes.dart';
import 'package:cobalagi/features/story/view/story_screen.dart';
import 'package:cobalagi/learning/learner_state.dart';
import 'package:cobalagi/learning/story.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the ship, Koba and obstacles stand on one level line', () {
    final stage = ArrivalStage(
      Canvas(ui.PictureRecorder()),
      const Rect.fromLTWH(0, 0, 1600, 900),
      const StoryFrame(beat: 0, t: 0, time: 0),
      null,
    );
    for (final fx in [0.0, 0.14, 0.36, 0.5, 0.97]) {
      expect(stage.on(fx).dy, stage.ground, reason: 'at $fx');
    }
  });

  test("a board scene's blocks solve its own board", () {
    for (final scene in arrivalScenes.values.whereType<BoardArrival>()) {
      expect(scene.play.run.outcome, RunOutcome.success, reason: scene.concept);
      expect(scene.play.steps, isNotEmpty);
    }
  });

  test("Fix it!'s muddled blocks bump, then the fixed ones run", () {
    final play = arrivalScenes['debugging']! as BoardArrival;
    final kinds = play.play.steps.map((s) => s.kind).toList();
    expect(
      kinds,
      containsAllInOrder([
        BoardStepKind.bump,
        BoardStepKind.fix,
        BoardStepKind.back,
        BoardStepKind.go,
      ]),
    );
    expect(
      play.play.fixedId,
      play.play.steps[kinds.indexOf(BoardStepKind.bump)].block,
    );
  });

  test("the Magic Block's blocks light the call running them", () {
    final play = (arrivalScenes['functions']! as BoardArrival).play;
    expect(
      [for (final step in play.steps) step.call],
      ['m0', 'm0', 'm0', 'm1', 'm1', 'm1', null, null],
    );
  });

  test('every planet has an arrival scene', () {
    final skills = jsonDecode(
      File('assets/config/skills.json').readAsStringSync(),
    );
    final concepts = [
      for (final s in (skills as Map)['concepts'] as List) (s as Map)['id'],
    ];
    expect(arrivalScenes.keys, concepts);
    expect(arrivalScenes.keys, VoiceClips.arrivalConcepts);
    for (final MapEntry(:key, :value) in arrivalScenes.entries) {
      expect(value.concept, key);
    }
  });

  test('the narrator sets the scene, then Koba speaks', () {
    for (final scene in arrivalScenes.values) {
      final [setting, koba] = scene.beats;
      expect(VoiceClips.speakerOf(setting.clip), Speaker.narrator);
      expect(VoiceClips.speakerOf(koba.clip), Speaker.koba);
    }
  });

  test('every planet thanks the commander for its skill, in its own '
      'words', () {
    for (final concept in arrivalScenes.keys) {
      final [_, thanks] = FullAgainScene(concept).beats;
      expect(thanks.clip, VoiceClips.storyThanks(concept));
      expect(VoiceClips.speakerOf(thanks.clip), Speaker.koba);
      expect(VoiceClips.all, contains(thanks.clip), reason: concept);
    }
  });

  test('the map plays the intro, then a new planet scene, then an ending', () {
    const learner = LearnerState(currentConcept: 'otherwise');
    String? due(Set<String> seen, String last, {bool done = false}) =>
        StoryScreen.dueOnMap(
          learner.copyWith(tutorialsSeen: seen),
          last,
          mapComplete: done,
        );
    expect(due({}, 'otherwise', done: true), 'ending-otherwise');
    expect(due({}, 'otherwise'), isNull);
    final ended = {Story.fullTank('otherwise')};
    expect(due(ended, 'otherwise', done: true), isNull);
    expect(due(ended, 'until', done: true), 'new-planet-until');
    expect(
      due({...ended, Story.newPlanet('until')}, 'until', done: true),
      'full-again-until',
    );
    for (final name in [
      'ending-otherwise',
      'new-planet-until',
      'full-again-until',
    ]) {
      expect(StoryScreen.scenes, contains(name));
    }
  });

  testWidgets('every moment of every arrival and ending paints', (
    tester,
  ) async {
    final art = await tester.runAsync(StoryArt.load);
    for (final scene in [
      ...arrivalScenes.values,
      const EndingScene('otherwise'),
      const FullAgainScene('variables'),
      const NewPlanetScene('until'),
    ]) {
      for (final pictures in [art, null]) {
        for (var beat = 0; beat < scene.beats.length; beat++) {
          for (var t = 0.0; t <= 1; t += 0.05) {
            final recorder = ui.PictureRecorder();
            scene.paint(
              Canvas(recorder),
              const Rect.fromLTWH(0, 0, 800, 500),
              StoryFrame(beat: beat, t: t, time: t * 5),
              pictures,
            );
            recorder.endRecording().dispose();
          }
        }
      }
    }
  });
}
