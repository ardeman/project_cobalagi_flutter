import 'package:flutter/foundation.dart';
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
      side: BorderSide(color: Color(0x99FFFFFF), width: 1.2),
    );
    const buttonSize = Size(64, 64);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    // Based on the platform's label style, so buttons use the app's font.
    final typography = Typography.material2021(platform: defaultTargetPlatform);
    final buttonText =
        (brightness == Brightness.light ? typography.black : typography.white)
            .labelLarge!
            .copyWith(fontSize: 22, fontWeight: FontWeight.w700);

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarThemeData(
        backgroundColor: scheme.surface.withValues(alpha: 0.7),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        shape: shape,
        elevation: 0,
        color: scheme.surface.withValues(alpha: 0.8),
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        shape: shape,
        backgroundColor: scheme.surface.withValues(alpha: 0.97),
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: shape,
        backgroundColor: scheme.surface.withValues(alpha: 0.97),
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface.withValues(alpha: 0.72),
        side: const BorderSide(color: Color(0x99FFFFFF)),
        shape: shape,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: shape,
          textStyle: buttonText,
        ).copyWith(backgroundBuilder: _buttonGlass),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: buttonSize,
          shape: shape,
        ).copyWith(backgroundBuilder: _buttonGlass),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: shape,
        ).copyWith(backgroundBuilder: _buttonGlass),
      ),
    );
  }

  /// Button highlights have no blur, keeping frequently repeated controls
  /// cheap to paint while preserving Material focus, ink and disabled states.
  static Widget _buttonGlass(
    BuildContext context,
    Set<WidgetState> states,
    Widget? child,
  ) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(
            alpha: states.contains(WidgetState.disabled) ? 0.06 : 0.22,
          ),
          Colors.white.withValues(alpha: 0.02),
          Colors.black.withValues(alpha: 0.06),
        ],
      ),
    ),
    child: child,
  );
}
