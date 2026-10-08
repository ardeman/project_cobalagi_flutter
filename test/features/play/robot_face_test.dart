import 'dart:ui';

import 'package:cobalagi/engine/world/direction.dart';
import 'package:cobalagi/engine/world/grid_point.dart';
import 'package:cobalagi/features/play/view/world/world_components.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'the robot draws every face, facing every way, idle and rolling',
    () async {
      final recorder = PictureRecorder();
      Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 4, 4),
        Paint()..color = const Color(0xFF00FFFF),
      );
      final image = await recorder.endRecording().toImage(4, 4);
      final sprite = Sprite(image);
      for (final facing in Direction.values) {
        final actor = ActorComponent(
          const GridPoint(0, 0),
          facing,
          sprite: sprite,
          backSprite: sprite,
          frontSprite: sprite,
        );
        for (final face in RobotFace.values) {
          for (final rolling in [false, true]) {
            actor
              ..face = face
              ..rolling = rolling
              ..update(1.7);
            final canvas = Canvas(PictureRecorder());
            expect(() => actor.render(canvas), returnsNormally);
          }
        }
      }
    },
  );
}
