import 'dart:io';

import 'package:cobalagi/core/gamepad/screen_keyboard.dart';

/// On Linux under Steam's Game Mode (the Steam Deck) or Big Picture, opens
/// and closes Steam's keyboard through its `steam://open/keyboard` and
/// `steam://close/keyboard` links.
ScreenKeyboard? steamKeyboard() {
  if (!Platform.isLinux) return null;
  final env = Platform.environment;
  if (env['SteamDeck'] != '1' && env['SteamGamepadUI'] != '1') return null;
  // The AppImage's libraries must not leak into Steam's launcher.
  final clean = {...env}..remove('LD_LIBRARY_PATH');
  void open(String link) => Process.start(
    'steam',
    [link],
    environment: clean,
    includeParentEnvironment: false,
    mode: ProcessStartMode.detached,
  ).ignore(); // No keyboard is better than a crash.
  return ScreenKeyboard(
    show: () => open('steam://open/keyboard'),
    hide: () => open('steam://close/keyboard'),
    // Half the screen: more than Steam's keyboard takes on the Deck, so
    // nothing ends up under it.
    covers: 0.5,
  );
}
