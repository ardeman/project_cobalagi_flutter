import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show IconData;

/// The ship's four pictures (`assets/images/ship_<view>.webp`, exported from
/// `branding/ship/` by `tool/ship/export.sh`).
enum ShipView {
  /// On the ground, engine off.
  landed,

  /// Taking off, with a big flame.
  launch,

  /// Coming down, with a small flame.
  landing,

  /// Flying nose to the right (mirror it to fly left).
  flying,
}

/// Where things are on a ship picture, in its 512 pixels: half of
/// `branding/ship/ship.json`, since the app's pictures are half the size of
/// the renders (a test keeps them in step).
final class ShipGeometry {
  const ShipGeometry({
    required this.base,
    required this.tankBottom,
    required this.tankTop,
    required this.tankWidth,
    required this.cockpit,
    required this.cockpitRadius,
    required this.emblem,
    required this.emblemRadius,
  });

  /// The middle of the engine, on the ground.
  final Offset base;

  /// The tank's fill axis, from empty to full, and its width.
  final Offset tankBottom;
  final Offset tankTop;
  final double tankWidth;

  /// The round cockpit window, where Koba sits.
  final Offset cockpit;
  final double cockpitRadius;

  /// Where the commander's emblem is painted on the hull, beside the
  /// windows. Picked by eye, not from `ship.json`.
  final Offset emblem;
  final double emblemRadius;

  static ShipGeometry of(ShipView view) => switch (view) {
    ShipView.landed => const ShipGeometry(
      base: Offset(256.0, 400.8),
      tankBottom: Offset(231.75, 322.6),
      tankTop: Offset(231.4, 285.25),
      tankWidth: 32.2,
      cockpit: Offset(234.25, 231.6),
      cockpitRadius: 22.4,
      emblem: Offset(293, 262),
      emblemRadius: 20,
    ),
    ShipView.launch => const ShipGeometry(
      base: Offset(256.0, 361.45),
      tankBottom: Offset(231.75, 283.25),
      tankTop: Offset(231.4, 245.9),
      tankWidth: 32.2,
      cockpit: Offset(234.25, 192.25),
      cockpitRadius: 22.4,
      emblem: Offset(293, 222.65),
      emblemRadius: 20,
    ),
    ShipView.landing => const ShipGeometry(
      base: Offset(256.0, 393.5),
      tankBottom: Offset(231.75, 315.3),
      tankTop: Offset(231.4, 277.95),
      tankWidth: 32.2,
      cockpit: Offset(234.25, 224.3),
      cockpitRadius: 22.4,
      emblem: Offset(293, 254.7),
      emblemRadius: 20,
    ),
    ShipView.flying => const ShipGeometry(
      base: Offset(145.6, 270.65),
      tankBottom: Offset(228.25, 239.5),
      tankTop: Offset(263.75, 225.5),
      tankWidth: 32.2,
      cockpit: Offset(313.6, 205.6),
      cockpitRadius: 22.4,
      emblem: Offset(292, 264),
      emblemRadius: 16,
    ),
  };

  /// The picture's size in pixels.
  static const picture = 512.0;
}

/// The story's pictures, decoded once and shared by every scene and the
/// map's flight. Scenes paint without them until they are loaded.
final class StoryArt {
  StoryArt._(
    this.ships,
    this.tanks,
    this.robot,
    this.robotFront, [
    this.emblem,
  ]);

  final Map<ShipView, ui.Image> ships;

  /// White where each view's tank window shows.
  final Map<ShipView, ui.Image> tanks;

  /// Koba from the side, facing right (`robot.png`), and facing the child.
  final ui.Image robot;
  final ui.Image robotFront;

  /// The commander's emblem (their avatar's icon and colour), painted on the
  /// ship's hull: it is the child's ship too. None paints a plain hull.
  final (IconData, Color)? emblem;

  /// The same pictures with [emblem] on the ship.
  StoryArt withEmblem((IconData, Color)? emblem) => emblem == this.emblem
      ? this
      : StoryArt._(ships, tanks, robot, robotFront, emblem);

  static Future<StoryArt>? _loading;

  /// The pictures, loaded on first use.
  static Future<StoryArt> load() =>
      _loading ??= _load(rootBundle).catchError((Object error) {
        _loading = null;
        throw error;
      });

  static Future<StoryArt> _load(AssetBundle bundle) async {
    Future<ui.Image> image(String name) async {
      final data = await bundle.load('assets/images/$name');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      return (await codec.getNextFrame()).image;
    }

    return StoryArt._(
      {for (final v in ShipView.values) v: await image('ship_${v.name}.webp')},
      {
        for (final v in ShipView.values)
          v: await image('ship_${v.name}_tank.webp'),
      },
      await image('robot.png'),
      await image('robot_front.png'),
    );
  }
}
