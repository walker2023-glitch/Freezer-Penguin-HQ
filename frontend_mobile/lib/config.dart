// Shared application constants and design tokens.
//
// Colour palette is derived from the Freezer Penguin brand icon:
//   • Icy blues  — #C8E6F7 (background), #A8D4EF (surface), #00A3FF (accent)
//   • White      — #FFFFFF (belly / crisp light surfaces)
//   • Dark navy  — #05162E (outline / penguin body)
//   • Orange     — #F37321 (beak / warm accent)
//
// All three themes (arctic / light / dark) reference these tokens.

import 'package:flutter/material.dart';

/// HTTP base URL for the Freezer Penguin FastAPI backend.
/// HTTP only — avoids local self-signed TLS certificate validation blocks.
const String backendUrl = 'http://127.0.0.1:8000/api/v1';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  // ── Arctic theme (icy blue, snowflake background) ──────────────────────────
  static const Color arcticBackground = Color(0xFFC8E6F7); // icy sky blue
  static const Color arcticSurface    = Color(0xFFA8D4EF); // deeper ice

  // ── Light theme (crisp white belly) ────────────────────────────────────────
  static const Color lightBackground  = Color(0xFFF5FAFE); // near-white
  static const Color lightSurface     = Color(0xFFE3F2FD); // pale blue-white

  // ── Dark theme (deep navy penguin feathers) ────────────────────────────────
  static const Color darkBackground   = Color(0xFF0A1628); // deep navy
  static const Color darkSurface      = Color(0xFF112240); // slightly lighter navy
  static const Color darkText         = Color(0xFFE8F4FD); // soft white text

  // ── Legacy aliases kept for backwards compat ─────────────────────────────
  // (any reference to old names like antarcticBackground still compiles)
  static const Color antarcticBackground    = arcticBackground;
  static const Color antarcticSurface       = arcticSurface;
  static const Color crispKitchenBackground = lightBackground;
  static const Color crispKitchenSurface    = lightSurface;
  static const Color deepOceanBackground    = darkBackground;
  static const Color deepOceanSurface       = darkSurface;
  static const Color deepOceanText          = darkText;

  // ── Brand / shared tokens ─────────────────────────────────────────────────
  static const Color surfaceLowest = Color(0xFFFFFFFF);       // pure white
  static const Color outline       = Color(0xFF05162E);       // penguin body navy
  static const Color primary       = Color(0xFF00A3FF);       // icy accent blue
  static const Color orange        = Color(0xFFF37321);       // beak orange
  static const Color textVariant   = Color(0xFF2D5B88);       // muted blue-grey
}
