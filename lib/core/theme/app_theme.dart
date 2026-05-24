import 'package:flutter/material.dart';

class AppTheme {
  static const _sakura = Color(0xFFB85C74);
  static const _ume = Color(0xFF934355);
  static const _matcha = Color(0xFF52684F);
  static const _vermilion = Color(0xFFA95736);
  static const _paper = Color(0xFFFFF8F1);
  static const _paperWhite = Color(0xFFFFFCF8);
  static const _washi = Color(0xFFF6E8DC);
  static const _sakuraMist = Color(0xFFF5D8DD);
  static const _ink = Color(0xFF2D2421);
  static const _softInk = Color(0xFF695C56);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: _sakura).copyWith(
      primary: _ume,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFF8D5DC),
      onPrimaryContainer: const Color(0xFF381018),
      secondary: _matcha,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFDCE8D8),
      onSecondaryContainer: const Color(0xFF111F12),
      tertiary: _vermilion,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFFFDBCC),
      onTertiaryContainer: const Color(0xFF351205),
      surface: _paper,
      onSurface: _ink,
      surfaceContainerLowest: _paperWhite,
      surfaceContainerLow: const Color(0xFFFFF3E8),
      surfaceContainer: const Color(0xFFFCEDE1),
      surfaceContainerHigh: _washi,
      surfaceContainerHighest: const Color(0xFFF0DED1),
      onSurfaceVariant: _softInk,
      outline: const Color(0xFFAA958A),
      outlineVariant: _sakuraMist,
    );
    return _build(scheme);
  }

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: _sakura,
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFFF1A9B7),
          onPrimary: const Color(0xFF4D1724),
          primaryContainer: const Color(0xFF6E2B3B),
          onPrimaryContainer: const Color(0xFFFFD9DF),
          secondary: const Color(0xFFB9CFB2),
          onSecondary: const Color(0xFF243422),
          secondaryContainer: const Color(0xFF3B4D38),
          onSecondaryContainer: const Color(0xFFD5EBCF),
          tertiary: const Color(0xFFFFB694),
          onTertiary: const Color(0xFF52210D),
          tertiaryContainer: const Color(0xFF78371E),
          onTertiaryContainer: const Color(0xFFFFDBCC),
          surface: const Color(0xFF1D1716),
          onSurface: const Color(0xFFF5E7DE),
          surfaceContainerLowest: const Color(0xFF171211),
          surfaceContainerLow: const Color(0xFF251E1C),
          surfaceContainer: const Color(0xFF2B2321),
          surfaceContainerHigh: const Color(0xFF352C29),
          surfaceContainerHighest: const Color(0xFF413633),
          onSurfaceVariant: const Color(0xFFD7C3BA),
          outline: const Color(0xFF9D877F),
          outlineVariant: const Color(0xFF574842),
        );
    return _build(scheme);
  }

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
    );
    final textTheme = base.textTheme
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface)
        .copyWith(
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          titleSmall: base.textTheme.titleSmall?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w800,
          ),
          labelLarge: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.5),
        );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        margin: EdgeInsets.zero,
        shadowColor: _ink.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.error),
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.72),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}
