import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cobalagi/core/audio/voice_clips.dart';
import 'package:cobalagi/features/story/data/story_art.dart';
import 'package:cobalagi/features/story/data/story_scene.dart';
import 'package:cobalagi/features/story/view/arrival_scenes.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('planets 1 to 5 each have an arrival scene', () {
    final skills = jsonDecode(
      File('assets/config/skills.json').readAsStringSync(),
    );
    final concepts = [
      for (final s in (skills as Map)['concepts'] as List) (s as Map)['id'],
    ];
    expect(arrivalScenes.keys, concepts.take(5));
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

  testWidgets('every moment of every arrival paints', (tester) async {
    final art = await tester.runAsync(StoryArt.load);
    for (final scene in arrivalScenes.values) {
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
