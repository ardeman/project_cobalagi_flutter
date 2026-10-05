import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _seed = Color(0xFF00A6A6);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  /// Large, rounded, high-contrast controls sized for small fingers.
  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(24)),
    );
    const buttonSize = Size(64, 64);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    const buttonText = TextStyle(fontSize: 22, fontWeight: FontWeight.w700);

    return ThemeData(
      colorScheme: scheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      cardTheme: const CardThemeData(shape: shape, elevation: 2),
      dialogTheme: const DialogThemeData(shape: shape),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: shape,
          textStyle: buttonText,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: buttonSize),
      ),
    );
  }
}
