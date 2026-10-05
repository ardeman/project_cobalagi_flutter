import 'package:flutter/material.dart';

/// Placeholder avatars until the Rive characters arrive.
const avatarStyles = <(IconData, Color)>[
  (Icons.pets, Color(0xFFFF8A65)),
  (Icons.cruelty_free, Color(0xFFBA68C8)),
  (Icons.flutter_dash, Color(0xFF4FC3F7)),
  (Icons.emoji_nature, Color(0xFFAED581)),
  (Icons.rocket_launch, Color(0xFFFFD54F)),
  (Icons.star, Color(0xFF4DB6AC)),
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
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.55, color: Colors.white),
    );
  }
}
