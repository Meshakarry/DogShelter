import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const seedColor = Color(0xFF2E7D5B);
  static const successColor = Color(0xFF2E7D5B);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
      appBarTheme: const AppBarTheme(centerTitle: false),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      // Default (non-error) SnackBar background - success/info messages never pass an
      // explicit backgroundColor, so this is what they render with.
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: successColor,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }
}
