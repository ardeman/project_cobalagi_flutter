import 'package:flutter/material.dart';

/// The space friends a child can pick, by the index saved in their profile.
/// Keep the order and add new ones at the end: a profile stores only the
/// index.
const avatarStyles = <(IconData, Color)>[
  (Icons.rocket_launch_rounded, Color(0xFFFF8A65)),
  (Icons.smart_toy_rounded, Color(0xFFBA68C8)),
  (Icons.public_rounded, Color(0xFF4FC3F7)),
  (Icons.satellite_alt_rounded, Color(0xFF81C784)),
  (Icons.nightlight_round, Color(0xFFFFC83D)),
  (Icons.auto_awesome_rounded, Color(0xFF4DB6AC)),
  (Icons.star_rounded, Color(0xFFF06292)),
  (Icons.wb_sunny_rounded, Color(0xFFFFB74D)),
  (Icons.bolt_rounded, Color(0xFF7986CB)),
  (Icons.pets_rounded, Color(0xFFA1887F)),
  (Icons.cruelty_free_rounded, Color(0xFF9575CD)),
  (Icons.favorite_rounded, Color(0xFFE57373)),
];

/// The icon and colour of [avatar], also painted as the child's emblem on
/// Koba's ship.
(IconData, Color) avatarEmblem(int avatar) =>
    avatarStyles[avatar % avatarStyles.length];

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.avatar, this.size = 96});

  final int avatar;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = avatarEmblem(avatar);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // Lit from the top left, like the planets on the map.
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.45),
          radius: 1.1,
          colors: [Color.lerp(color, Colors.white, 0.3)!, color],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: size * 0.55, color: Colors.white),
    );
  }
}
