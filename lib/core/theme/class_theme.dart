// Keep compatibility with Flutter stable's built-in Material library.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

abstract final class ClassSpacing {
  static const small = 8.0;
  static const medium = 16.0;
  static const large = 24.0;
  static const touchTarget = 48.0;
}

class ClassPalette {
  const ClassPalette._({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.accent,
    required this.success,
    required this.warning,
    required this.error,
    required this.textPrimary,
    required this.textSecondary,
  });

  final Color background, surface, surfaceAlt, border, primary, onPrimary;
  final Color primaryContainer, onPrimaryContainer, accent, success, warning;
  final Color error, textPrimary, textSecondary;
  static const whatsapp = Color(0xff25d366);

  static const light = ClassPalette._(
    background: Color(0xfff7f5fc),
    surface: Color(0xffffffff),
    surfaceAlt: Color(0xffefeafb),
    border: Color(0xffe3ddf2),
    primary: Color(0xff6b3fd4),
    onPrimary: Color(0xffffffff),
    primaryContainer: Color(0xffe6dcfb),
    onPrimaryContainer: Color(0xff2a1466),
    accent: Color(0xfff5a524),
    success: Color(0xff1e9e6a),
    warning: Color(0xffe58a00),
    error: Color(0xffd93c4a),
    textPrimary: Color(0xff1b1530),
    textSecondary: Color(0xff5e5875),
  );

  static const dark = ClassPalette._(
    background: Color(0xff120e1f),
    surface: Color(0xff1b1530),
    surfaceAlt: Color(0xff251d3f),
    border: Color(0xff352c55),
    primary: Color(0xffb79cff),
    onPrimary: Color(0xff1b0f3d),
    primaryContainer: Color(0xff3b2a78),
    onPrimaryContainer: Color(0xfff1edfb),
    accent: Color(0xffffc15a),
    success: Color(0xff4fd1a0),
    warning: Color(0xffffb454),
    error: Color(0xffff8a94),
    textPrimary: Color(0xfff1edfb),
    textSecondary: Color(0xffb2a9cc),
  );

  ThemeData theme(Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: brightness,
        ).copyWith(
          primary: primary,
          onPrimary: onPrimary,
          primaryContainer: primaryContainer,
          onPrimaryContainer: onPrimaryContainer,
          surface: surface,
          onSurface: textPrimary,
          onSurfaceVariant: textSecondary,
          outlineVariant: border,
        );
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primaryContainer,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontFamily: 'Plus Jakarta Sans',
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontFamily: 'Plus Jakarta Sans',
        ),
      ),
    );
  }
}
