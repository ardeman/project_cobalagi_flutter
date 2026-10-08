import 'package:flutter/material.dart';

/// The space friends a child can pick, by the index saved in their profile.
/// Keep the count and order: a profile stores only the index.
const avatarStyles = <(IconData, Color)>[
  (Icons.rocket_launch_rounded, Color(0xFFFF8A65)),
  (Icons.smart_toy_rounded, Color(0xFFBA68C8)),
  (Icons.public_rounded, Color(0xFF4FC3F7)),
  (Icons.satellite_alt_rounded, Color(0xFF81C784)),
  (Icons.nightlight_round, Color(0xFFFFC83D)),
  (Icons.auto_awesome_rounded, Color(0xFF4DB6AC)),
];

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.avatar, this.size = 96});

  final int avatar;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = avatarStyles[avatar % avatarStyles.length];
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
