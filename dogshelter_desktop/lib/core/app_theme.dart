import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const seedColor = Color(0xFF2E7D5B);
  static const sidebarBackground = Color(0xFF16232B);
  static const sidebarForeground = Color(0xFFE7ECEE);
  static const sidebarMuted = Color(0xFF8FA0A8);
  static const cardRadius = 12.0;

  static const toolbarActionHeight = 40.0;

  /// Rectangular (not pill-shaped) button matching the height of an adjacent
  /// dense OutlineInputBorder text field - used for list-toolbar actions like "Dodaj".
  static final ButtonStyle toolbarActionButtonStyle = FilledButton.styleFrom(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    minimumSize: const Size(0, toolbarActionHeight),
    maximumSize: const Size(double.infinity, toolbarActionHeight),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}
