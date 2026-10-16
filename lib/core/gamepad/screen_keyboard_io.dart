import 'dart:io';

import 'package:cobalagi/core/gamepad/screen_keyboard.dart';

/// On Linux under Steam's Game Mode (the Steam Deck) or Big Picture, opens
/// Steam's keyboard through its `steam://open/keyboard` link.
ShowScreenKeyboard? steamKeyboard() {
  if (!Platform.isLinux) return null;
  final env = Platform.environment;
  if (env['SteamDeck'] != '1' && env['SteamGamepadUI'] != '1') return null;
  // The AppImage's libraries must not leak into Steam's launcher.
  final clean = {...env}..remove('LD_LIBRARY_PATH');
  return () {
    Process.start(
      'steam',
      ['steam://open/keyboard'],
      environment: clean,
      includeParentEnvironment: false,
      mode: ProcessStartMode.detached,
    ).ignore(); // No keyboard is better than a crash.
  };
}
