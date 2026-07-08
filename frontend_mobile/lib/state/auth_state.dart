// Authentication state — Feature 2.0 Login & Registration Skeleton.
//
// Injected at app root via MultiProvider so both LoginScreen and
// MainNavigationScreen can read/write auth credentials without
// prop-drilling. Lives in its own file to avoid circular imports
// between main.dart and screens/login_screen.dart.

import 'package:flutter/foundation.dart';

class AuthState extends ChangeNotifier {
  // ── Initialisation state ──────────────────────────────────────────────────
  // Starts true so LoadingScreen is shown at launch. LoadingScreen calls
  // setReady() when its entrance animation completes, which flips this to
  // false and causes Consumer<AuthState> to swap to LoginScreen / main nav.
  bool _isInitializing = true;

  // ── Authentication state ──────────────────────────────────────────────────
  bool _isAuthenticated = false;
  int? _userId;
  String? _email;

  // _token is intentionally omitted at skeleton stage.
  // TODO: add String? _token and attach to Authorization header in Phase 5+.

  bool get isInitializing => _isInitializing;
  bool get isAuthenticated => _isAuthenticated;
  int? get userId => _userId;
  String? get email => _email;

  /// Called by [LoadingScreen] when its entrance animation finishes.
  /// Clears the splash gate and hands control to the auth gate.
  void setReady() {
    _isInitializing = false;
    notifyListeners();
  }

  /// Sets auth session after a successful /auth/login response.
  void login({
    required int userId,
    required String email,
    required String token, // retained in signature for future JWT storage
  }) {
    _isAuthenticated = true;
    _userId = userId;
    _email = email;
    notifyListeners();
  }

  /// Clears all session data — called from the Settings sheet Sign Out button.
  void logout() {
    _isAuthenticated = false;
    _userId = null;
    _email = null;
    notifyListeners();
  }
}
