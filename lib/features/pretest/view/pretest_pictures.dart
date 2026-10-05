import 'dart:math';

import 'package:flutter/material.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../engine/world/direction.dart';
import '../../../learning/placement/pretest_question.dart';

// Placeholder pictures until the illustrated set arrives.

const _objectStyles = <String, (IconData, Color)>{
  'sun': (Icons.wb_sunny_rounded, Color(0xFFFFB300)),
  'star': (Icons.star_rounded, Color(0xFFFFC83D)),
  'house': (Icons.house_rounded, Color(0xFF8D6E63)),
  'car': (Icons.directions_car_rounded, Color(0xFFE53935)),
  'tree': (Icons.park_rounded, Color(0xFF43A047)),
  'ball': (Icons.sports_soccer_rounded, Color(0xFF455A64)),
  'flower': (Icons.local_florist_rounded, Color(0xFFEC407A)),
  'boat': (Icons.sailing_rounded, Color(0xFF1E88E5)),
  'bird': (Icons.flutter_dash_rounded, Color(0xFF29B6F6)),
  'cake': (Icons.cake_rounded, Color(0xFFAB47BC)),
};

const _colors = <String, Color>{
  'red': Color(0xFFE53935),
  'blue': Color(0xFF1E88E5),
  'green': Color(0xFF43A047),
  'yellow': Color(0xFFFDD835),
};

/// An object, a pattern shape or a colored version of either.
class PretestPicture extends StatelessWidget {
  const PretestPicture({super.key, required this.picture, required this.size});

  final Picture picture;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _colors[picture.color];
    return switch (picture.object) {
      'circle' => Icon(Icons.circle, size: size, color: color),
      'square' => Icon(Icons.square_rounded, size: size, color: color),
      'heart' => Icon(Icons.favorite_rounded, size: size, color: color),
      'triangle' => Transform.rotate(
        angle: -pi / 2,
        child: Icon(Icons.play_arrow_rounded, size: size, color: color),
      ),
      final object => Icon(
        _objectStyles[object]?.$1 ?? Icons.help_rounded,
        size: size,
        color: color ?? _objectStyles[object]?.$2,
      ),
    };
  }
}

/// An arrow pointing in [direction] (north is up).
class DirectionArrow extends StatelessWidget {
  const DirectionArrow({
    super.key,
    required this.direction,
    required this.size,
    this.color,
  });

  final Direction direction;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: direction.index * pi / 2,
    child: Icon(
      Icons.navigation_rounded,
      size: size,
      color: color ?? const Color(0xFFFF7A59),
    ),
  );
}

/// The written word(s) for a reading question, in the app's language.
String writtenWords(AppLocalizations l10n, Picture picture) {
  final object = _word(l10n, picture.object);
  final color = picture.color;
  return color == null
      ? object
      : l10n.wordsWithColor(_colorWord(l10n, color), object);
}

String _word(AppLocalizations l10n, String id) => switch (id) {
  'sun' => l10n.wordSun,
  'star' => l10n.wordStar,
  'house' => l10n.wordHouse,
  'car' => l10n.wordCar,
  'tree' => l10n.wordTree,
  'ball' => l10n.wordBall,
  'flower' => l10n.wordFlower,
  'boat' => l10n.wordBoat,
  'bird' => l10n.wordBird,
  'cake' => l10n.wordCake,
  _ => id,
};

String _colorWord(AppLocalizations l10n, String id) => switch (id) {
  'red' => l10n.colorRed,
  'blue' => l10n.colorBlue,
  'green' => l10n.colorGreen,
  'yellow' => l10n.colorYellow,
  _ => id,
};
