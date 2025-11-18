import 'package:flutter/material.dart';
import 'package:habit_win/utils/app_colors.dart';

enum AppTheme {
  dark,
  classic,
  pink,
  ocean,
  forest,
  desert,
  oceanBlue,
}

extension AppThemeExtension on AppTheme {
  String get name {
    switch (this) {
      case AppTheme.dark:
        return 'Dark Theme';
      case AppTheme.oceanBlue:
        return 'Ocean Blue 🌊';
      case AppTheme.classic:
        return 'Classic Theme';
      case AppTheme.pink:
        return 'Pink Theme';
      case AppTheme.ocean:
        return 'Ocean Breeze';
      case AppTheme.forest:
        return 'Forest Green';
      case AppTheme.desert:
        return 'Desert Sand';
    }
  }

  ThemeData get themeData {
    switch (this) {
      case AppTheme.dark:
        return ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'Nunito',
          primaryColor: AppColors.primaryPurple,
          hintColor: AppColors.lightPurple,
          scaffoldBackgroundColor: AppColors.darkBackground,
          cardColor: AppColors.cardDark,
          textTheme: TextTheme(
            displayLarge: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 24, color: AppColors.white, letterSpacing: 0.2),
            headlineMedium: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 22, color: AppColors.white, letterSpacing: 0.2),
            titleMedium: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.white, letterSpacing: 0.2),
            bodyMedium: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w400, fontSize: 16, color: AppColors.white, letterSpacing: 0.2),
            labelSmall: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w300, fontSize: 14, color: AppColors.white, letterSpacing: 0.2),
            bodyLarge: const TextStyle(fontFamily: 'Nunito', color: AppColors.white),
            titleLarge: const TextStyle(fontFamily: 'Nunito', color: AppColors.white),
            titleSmall: const TextStyle(fontFamily: 'Nunito', color: AppColors.white),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primaryPurple,
            foregroundColor: AppColors.white,
            elevation: 0,
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: AppColors.primaryPurple,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // Changed to 12.0
            elevation: 8, // More prominent shadow
          ),
          buttonTheme: ButtonThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.cardDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: AppColors.shadowColor.withAlpha((255 * 0.1).round()), width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: AppColors.lightPurple, width: 2.0),
            ),
            labelStyle: TextStyle(color: AppColors.white.withAlpha((255 * 0.7).round())),
            hintStyle: TextStyle(color: AppColors.white.withAlpha((255 * 0.5).round())),
          ),
          cardTheme: CardThemeData(
            elevation: 8, // More prominent shadow
            shadowColor: AppColors.shadowColor.withAlpha((255 * 0.2).round()), // More prominent shadow
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0))), // Keep 16.0 for cards
            margin: EdgeInsets.zero,
          ),
          colorScheme: ColorScheme.dark(
            primary: AppColors.primaryPurple,
            secondary: AppColors.lightPurple,
            onPrimary: AppColors.white,
            onSecondary: AppColors.white,
            onSurface: AppColors.white,
            surface: AppColors.cardDark,
            surfaceContainer: AppColors.darkBackground,
            error: AppColors.redError,
            onError: AppColors.white,
            tertiary: AppColors.lightPurple,
            primaryContainer: AppColors.primaryPurple.withAlpha((255 * 0.1).round()),
            secondaryContainer: AppColors.lightPurple.withAlpha((255 * 0.1).round()),
            tertiaryContainer: AppColors.lightPurple.withAlpha((255 * 0.1).round()),
            surfaceContainerHighest: AppColors.darkBackground,
            outline: AppColors.shadowColor.withAlpha((255 * 0.1).round()),
          ),
        );
      case AppTheme.classic:
        return ThemeData(
          brightness: Brightness.light,
          fontFamily: 'Nunito',
          primaryColor: AppColors.primaryPurple,
          hintColor: AppColors.lightPurple,
          scaffoldBackgroundColor: AppColors.lightBackground,
          cardColor: AppColors.cardLight,
          textTheme: TextTheme(
            displayLarge: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 24, color: AppColors.darkGray, letterSpacing: 0.2),
            headlineMedium: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 22, color: AppColors.darkGray, letterSpacing: 0.2),
            titleMedium: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.darkGray, letterSpacing: 0.2),
            bodyMedium: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w400, fontSize: 16, color: AppColors.darkGray, letterSpacing: 0.2),
            labelSmall: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w300, fontSize: 14, color: AppColors.darkGray, letterSpacing: 0.2),
            bodyLarge: const TextStyle(fontFamily: 'Nunito', color: AppColors.darkGray),
            titleLarge: const TextStyle(fontFamily: 'Nunito', color: AppColors.darkGray),
            titleSmall: const TextStyle(fontFamily: 'Nunito', color: AppColors.darkGray),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primaryPurple,
            foregroundColor: AppColors.white,
            elevation: 0,
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: AppColors.primaryPurple,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // Changed to 12.0
            elevation: 8, // More prominent shadow
          ),
          buttonTheme: ButtonThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.cardLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: AppColors.shadowColor.withAlpha((255 * 0.1).round()), width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: AppColors.lightPurple, width: 2.0),
            ),
            labelStyle: TextStyle(color: AppColors.darkGray.withAlpha((255 * 0.7).round())),
            hintStyle: TextStyle(color: AppColors.darkGray.withAlpha((255 * 0.5).round())),
          ),
          cardTheme: CardThemeData(
            elevation: 8, // More prominent shadow
            shadowColor: AppColors.shadowColor.withAlpha((255 * 0.2).round()), // More prominent shadow
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0))), // Keep 16.0 for cards
            margin: EdgeInsets.zero,
          ),
          colorScheme: ColorScheme.light(
            primary: AppColors.primaryPurple,
            secondary: AppColors.lightPurple,
            onPrimary: AppColors.white,
            onSecondary: AppColors.white,
            onSurface: AppColors.darkGray,
            surface: AppColors.cardLight,
            surfaceContainer: AppColors.lightBackground,
            error: AppColors.redError,
            onError: AppColors.white,
            tertiary: AppColors.lightPurple,
            primaryContainer: AppColors.primaryPurple.withAlpha((255 * 0.1).round()),
            secondaryContainer: AppColors.lightPurple.withAlpha((255 * 0.1).round()),
            tertiaryContainer: AppColors.lightPurple.withAlpha((255 * 0.1).round()),
            surfaceContainerHighest: AppColors.lightBackground,
            outline: AppColors.shadowColor.withAlpha((255 * 0.1).round()),
          ),
        );
      case AppTheme.pink:
        return ThemeData(
          brightness: Brightness.light,
          fontFamily: 'Nunito',
          primaryColor: Colors.pink[300],
          hintColor: Colors.pinkAccent[400],
          scaffoldBackgroundColor: Colors.pink[50],
          cardColor: Colors.pink[100],
          textTheme: TextTheme(
            displayLarge: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 24, color: Colors.black, letterSpacing: 0.2),
            headlineMedium: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 22, color: Colors.black, letterSpacing: 0.2),
            titleMedium: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 18, color: Colors.black, letterSpacing: 0.2),
            bodyMedium: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w400, fontSize: 16, letterSpacing: 0.2),
            labelSmall: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w300, fontSize: 14, color: Colors.black, letterSpacing: 0.2),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.pink[300],
            foregroundColor: Colors.white,
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.pinkAccent[400],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // Changed to 12.0
            elevation: 8, // More prominent shadow
          ),
          colorScheme: ColorScheme.light(
            primary: Colors.pink[300]!,
            secondary: Colors.pinkAccent[400]!,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Colors.black,
            surface: Colors.pink[100]!,
            surfaceContainer: Colors.pink[50],
            tertiary: Colors.pink[400],
            primaryContainer: Colors.pink[100],
            secondaryContainer: Colors.pinkAccent[100],
            tertiaryContainer: Colors.pink[50],
          ),
        );
      case AppTheme.oceanBlue:
        return ThemeData(
          brightness: Brightness.light,
          fontFamily: 'Nunito',
          primaryColor: Colors.blue[800],
          hintColor: Colors.lightBlueAccent[400],
          scaffoldBackgroundColor: Colors.blue[50],
          cardColor: Colors.lightBlue[100],
          textTheme: TextTheme(
            displayLarge: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 24, color: Colors.black, letterSpacing: 0.2),
            headlineMedium: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 22, color: Colors.black, letterSpacing: 0.2),
            titleMedium: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 18, color: Colors.black, letterSpacing: 0.2),
            bodyMedium: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w400, fontSize: 16, color: Colors.black, letterSpacing: 0.2),
            labelSmall: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w300, fontSize: 14, color: Colors.black, letterSpacing: 0.2),
            bodyLarge: const TextStyle(fontFamily: 'Nunito', color: Colors.black),
            titleLarge: const TextStyle(fontFamily: 'Nunito', color: Colors.black),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.lightBlueAccent[400],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // Changed to 12.0
            elevation: 8, // More prominent shadow
          ),
          colorScheme: ColorScheme.light(
            primary: Colors.blue[800]!,
            secondary: Colors.lightBlueAccent[400]!,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Colors.black,
            surface: Colors.lightBlue[100]!,
            surfaceContainer: Colors.blue[50],
            tertiary: Colors.cyan[600],
            primaryContainer: Colors.blue[100],
            secondaryContainer: Colors.lightBlue[200],
            tertiaryContainer: Colors.cyan[100],
          ),
          // Add light wave pattern overlay for calm look.
          // This would typically be implemented with a custom widget or package
          // that reacts to the selected theme.
        );
      case AppTheme.ocean:
        return ThemeData(
          brightness: Brightness.light,
          fontFamily: 'Nunito',
          primaryColor: Colors.blue[600],
          hintColor: Colors.lightBlue[400],
          scaffoldBackgroundColor: Colors.blue[50],
          cardColor: Colors.blue[100],
          textTheme: TextTheme(
            displayLarge: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 24, color: Colors.black, letterSpacing: 0.2),
            headlineMedium: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 22, color: Colors.black, letterSpacing: 0.2),
            titleMedium: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 18, color: Colors.black, letterSpacing: 0.2),
            bodyMedium: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w400, fontSize: 16, letterSpacing: 0.2),
            labelSmall: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w300, fontSize: 14, color: Colors.black, letterSpacing: 0.2),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.lightBlue[400],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            elevation: 8,
          ),
          colorScheme: ColorScheme.light(
            primary: Colors.blue[600]!,
            secondary: Colors.lightBlue[400]!,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Colors.black,
            surface: Colors.blue[100]!,
            surfaceContainer: Colors.blue[50],
            tertiary: Colors.cyan[400],
            primaryContainer: Colors.blue[100],
            secondaryContainer: Colors.lightBlue[100],
            tertiaryContainer: Colors.cyan[50],
          ),
        );
      case AppTheme.forest:
        return ThemeData(
          brightness: Brightness.light,
          fontFamily: 'Nunito',
          primaryColor: Colors.green[800],
          hintColor: Colors.lightGreen[600],
          scaffoldBackgroundColor: Colors.green[50],
          cardColor: Colors.green[100],
          textTheme: TextTheme(
            displayLarge: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 24, color: Colors.black, letterSpacing: 0.2),
            headlineMedium: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 22, color: Colors.black, letterSpacing: 0.2),
            titleMedium: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 18, color: Colors.black, letterSpacing: 0.2),
            bodyMedium: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w400, fontSize: 16, letterSpacing: 0.2),
            labelSmall: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w300, fontSize: 14, color: Colors.black, letterSpacing: 0.2),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.green[800],
            foregroundColor: Colors.white,
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.lightGreen[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            elevation: 8,
          ),
          colorScheme: ColorScheme.light(
            primary: Colors.green[800]!,
            secondary: Colors.lightGreen[600]!,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Colors.black,
            surface: Colors.green[100]!,
            surfaceContainer: Colors.green[50],
            tertiary: Colors.lightGreen[800],
            primaryContainer: Colors.green[100],
            secondaryContainer: Colors.lightGreen[100],
            tertiaryContainer: Colors.lightGreen[50],
          ),
        );
      case AppTheme.desert:
        return ThemeData(
          brightness: Brightness.light,
          fontFamily: 'Nunito',
          primaryColor: Colors.orange[700],
          hintColor: Colors.amber[600],
          scaffoldBackgroundColor: Colors.orange[50],
          cardColor: Colors.amber[100],
          textTheme: TextTheme(
            displayLarge: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 24, color: Colors.black, letterSpacing: 0.2),
            headlineMedium: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 22, color: Colors.black, letterSpacing: 0.2),
            titleMedium: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 18, color: Colors.black, letterSpacing: 0.2),
            bodyMedium: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w400, fontSize: 16, letterSpacing: 0.2),
            labelSmall: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w300, fontSize: 14, color: Colors.black, letterSpacing: 0.2),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.orange[700],
            foregroundColor: Colors.white,
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.amber[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            elevation: 8,
          ),
          colorScheme: ColorScheme.light(
            primary: Colors.orange[700]!,
            secondary: Colors.amber[600]!,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Colors.black,
            surface: Colors.amber[100]!,
            surfaceContainer: Colors.orange[50],
            tertiary: Colors.brown[400],
            primaryContainer: Colors.orange[100],
            secondaryContainer: Colors.amber[100],
            tertiaryContainer: Colors.brown[50],
          ),
        );
    }
  }
}
