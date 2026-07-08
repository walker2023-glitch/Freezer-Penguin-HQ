// Shared application constants and design tokens.
//
// Centralised here so all screen files (LoginScreen, main.dart, etc.)
// share the same backend URL and colour palette without circular imports.

import 'package:flutter/material.dart';

/// HTTP base URL for the Freezer Penguin FastAPI backend.
/// HTTP only — avoids local self-signed TLS certificate validation blocks.
const String backendUrl = 'http://127.0.0.1:8000/api/v1';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// Moved here from main.dart so LoginScreen can reference colours without
// creating a circular import against main.dart.
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  static const Color antarcticBackground    = Color(0xFFD1E6F7);
  static const Color antarcticSurface       = Color(0xFFA9D2F0);
  static const Color crispKitchenBackground = Color(0xFFF4F9FD);
  static const Color crispKitchenSurface    = Color(0xFFE1EFFB);
  static const Color deepOceanBackground    = Color(0xFF0A1628);
  static const Color deepOceanSurface       = Color(0xFF112240);
  static const Color deepOceanText          = Color(0xFFE8F4FD);
  static const Color surfaceLowest          = Color(0xFFFFFFFF);
  static const Color outline                = Color(0xFF05162E);
  static const Color primary                = Color(0xFF00A3FF);
  static const Color orange                 = Color(0xFFF37321);
  static const Color textVariant            = Color(0xFF2D5B88);
}
