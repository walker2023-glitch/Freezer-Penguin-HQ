// App-wide UI settings state — Phase 5 extraction.
//
// Moved out of main.dart so screens in lib/screens/ (e.g. ConsumeScreen)
// can import AppTheme / AppSettings without creating a circular dependency
// against main.dart.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────────────────────────

enum AppTheme { frozenGlacier, crispKitchen, deepOcean }

/// UI locale selector. Maps to a Flutter [Locale] via [toLocale()].
enum AppLocale { en, yue, es }

extension AppLocaleExtension on AppLocale {
  Locale toLocale() {
    switch (this) {
      case AppLocale.yue: return const Locale('zh', 'HK');
      case AppLocale.es:  return const Locale('es');
      case AppLocale.en:  return const Locale('en');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP SETTINGS — central ChangeNotifier
// ─────────────────────────────────────────────────────────────────────────────

class AppSettings extends ChangeNotifier {
  AppTheme _theme = AppTheme.frozenGlacier;
  AppLocale _locale = AppLocale.en;

  AppTheme get theme => _theme;
  AppLocale get locale => _locale;
  Locale get flutterLocale => _locale.toLocale();

  /// Returns true when the active theme is the Frozen Glacier / Arctic preset.
  /// Used by nav and screens to switch between Standard and Arctic labels/icons.
  bool get isArctic => _theme == AppTheme.frozenGlacier;

  void setTheme(AppTheme t) {
    if (_theme == t) return;
    _theme = t;
    notifyListeners();
  }

  void setLocale(AppLocale l) {
    if (_locale == l) return;
    _locale = l;
    notifyListeners();
  }

  ThemeData buildTheme() {
    switch (_theme) {
      case AppTheme.deepOcean:
        return ThemeData(
          scaffoldBackgroundColor: AppColors.deepOceanBackground,
          textTheme: GoogleFonts.quicksandTextTheme().apply(
            bodyColor: AppColors.deepOceanText,
            displayColor: AppColors.deepOceanText,
          ),
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            secondary: AppColors.orange,
            surface: AppColors.deepOceanSurface,
          ),
        );
      case AppTheme.crispKitchen:
        return ThemeData(
          scaffoldBackgroundColor: AppColors.crispKitchenBackground,
          textTheme: GoogleFonts.quicksandTextTheme().apply(
            bodyColor: AppColors.outline,
            displayColor: AppColors.outline,
          ),
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            secondary: AppColors.orange,
            surface: AppColors.crispKitchenSurface,
          ),
        );
      case AppTheme.frozenGlacier:
        return ThemeData(
          scaffoldBackgroundColor: AppColors.antarcticBackground,
          textTheme: GoogleFonts.quicksandTextTheme().apply(
            bodyColor: AppColors.outline,
            displayColor: AppColors.outline,
          ),
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            secondary: AppColors.orange,
            surface: AppColors.antarcticSurface,
          ),
        );
    }
  }
}
