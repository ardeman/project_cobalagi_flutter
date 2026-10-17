import 'dart:math';
import 'dart:ui';

import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/engine/program/program.dart';
import 'package:cobalagi/engine/world/direction.dart';
import 'package:cobalagi/engine/world/grid_point.dart';
import 'package:cobalagi/engine/world/level.dart';
import 'package:cobalagi/features/play/cubit/play_cubit.dart';
import 'package:cobalagi/features/play/view/world/world_components.dart';
import 'package:cobalagi/features/play/view/world/world_game.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

final level = Level.fromRows(
  id: 'roll',
  concept: 'sequencing',
  rows: ['S.*.G'],
  startFacing: Direction.east,
  palette: {InstructionKind.move},
);

Future<Image> _image() {
  final recorder = PictureRecorder();
  Canvas(recorder).drawRect(
    const Rect.fromLTWH(0, 0, 4, 4),
    Paint()..color = const Color(0xFF00FFFF),
  );
  return recorder.endRecording().toImage(4, 4);
}

void main() {
  test(
    'Koba rolls on through steps in a row, a star included, and stops only '
    'at the end, leaning back as it sets off and forward as it brakes',
    () async {
      final play = PlayCubit(level);
      addTearDown(play.close);
      final game = await initializeGame(
        () => WorldGame(level: level, onEventShown: play.eventShown),
      );
      final subscription = play.stream.listen(game.apply);
      addTearDown(subscription.cancel);
      play.run(const Program([Move(), Move(), Move(), Move()]));
      final xs = <double>[];
      final leans = <double>[];
      for (var i = 0; i < 400 && play.state.phase == PlayPhase.running; i++) {
        await Future<void>.delayed(Duration.zero);
        game.update(1 / 60);
        final actor = game.world.children.whereType<ActorComponent>().single;
        xs.add(actor.position.x);
        leans.add(actor.lean);
      }
      expect(play.state.phase, PlayPhase.succeeded);
      // Between setting off and arriving it never stands still: no frame
      // without moving while it is between the start and the flag.
      final start = xs.first, end = xs.last;
      for (var i = 1; i < xs.length; i++) {
        if (xs[i - 1] > start + 0.2 && xs[i - 1] < end - 0.2) {
          expect(xs[i] - xs[i - 1], greaterThan(0.02), reason: 'frame $i');
        }
      }
      expect(leans.reduce(min), lessThan(-0.03));
      expect(leans.reduce(max), greaterThan(0.03));
    },
  );

  test('part way round a turn Koba shows a turning frame', () async {
    final sprite = Sprite(await _image());
    final actor = ActorComponent(
      const GridPoint(0, 0),
      Direction.east,
      sprite: sprite,
      backSprite: sprite,
      frontSprite: sprite,
    )..turnFrames = await _image();
    for (var a = 0.0; a < 2 * pi; a += 0.1) {
      actor
        ..angle = a
        ..update(1 / 60);
      expect(() => actor.render(Canvas(PictureRecorder())), returnsNormally);
    }
  });
}
