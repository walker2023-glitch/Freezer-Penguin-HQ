// App-wide UI settings state.
//
// AppTheme enum renamed to plain descriptive values (FIX 2):
//   arctic  — icy blue palette  (was frozenGlacier)
//   light   — clean white/cream (was crispKitchen)
//   dark    — deep navy/black   (was deepOcean)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────────────────────────

/// Three visual themes inspired by the Freezer Penguin brand palette:
/// icy blues (#D1E6F7 / #00A3FF), crisp white (#FFFFFF), and orange (#F37321).
enum AppTheme { arctic, light, dark }

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
  AppTheme _theme = AppTheme.arctic;
  AppLocale _locale = AppLocale.en;

  AppTheme get theme => _theme;
  AppLocale get locale => _locale;
  Locale get flutterLocale => _locale.toLocale();

  /// True when the Arctic theme is active — drives "Basecamp / Rations / Huddle"
  /// nav labels and the polar icon set.
  bool get isArctic => _theme == AppTheme.arctic;

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
      // ── Dark — deep navy inspired by the penguin's dark feathers ────────
      case AppTheme.dark:
        return ThemeData(
          scaffoldBackgroundColor: AppColors.darkBackground,
          textTheme: GoogleFonts.quicksandTextTheme().apply(
            bodyColor: AppColors.darkText,
            displayColor: AppColors.darkText,
          ),
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            secondary: AppColors.orange,
            surface: AppColors.darkSurface,
          ),
        );
      // ── Light — crisp white belly inspired by the penguin's white chest ─
      case AppTheme.light:
        return ThemeData(
          scaffoldBackgroundColor: AppColors.lightBackground,
          textTheme: GoogleFonts.quicksandTextTheme().apply(
            bodyColor: AppColors.outline,
            displayColor: AppColors.outline,
          ),
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            secondary: AppColors.orange,
            surface: AppColors.lightSurface,
          ),
        );
      // ── Arctic — icy sky blues inspired by the snowflake background ─────
      case AppTheme.arctic:
        return ThemeData(
          scaffoldBackgroundColor: AppColors.arcticBackground,
          textTheme: GoogleFonts.quicksandTextTheme().apply(
            bodyColor: AppColors.outline,
            displayColor: AppColors.outline,
          ),
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            secondary: AppColors.orange,
            surface: AppColors.arcticSurface,
          ),
        );
    }
  }
}
