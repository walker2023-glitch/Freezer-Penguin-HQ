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
  bool _isOfflinePreview = false;
  bool _isKitchenPreview = false;
  int? _userId;
  String? _email;
  String? _token;

  String? get token => _token;

  /// Headers for protected API calls. Preview mode never calls this helper.
  Map<String, String> authHeaders({bool json = false}) {
    final value = _token;
    if (value == null || value.isEmpty) {
      throw StateError('No authenticated API session is available.');
    }
    return {
      'Authorization': 'Bearer $value',
      if (json) 'Content-Type': 'application/json',
    };
  }

  bool get isInitializing => _isInitializing;
  bool get isAuthenticated => _isAuthenticated;
  bool get isOfflinePreview => _isOfflinePreview;
  bool get isKitchenPreview => _isKitchenPreview;
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
    _isOfflinePreview = false;
    _isKitchenPreview = false;
    _userId = userId;
    _email = email;
    _token = token;
    notifyListeners();
  }

  /// Skip the API and open the current (classic) app with mock data.
  /// Remove this path before a store build.
  void enterOfflinePreview() {
    _isAuthenticated = true;
    _isOfflinePreview = true;
    _isKitchenPreview = false;
    _userId = 0;
    _email = 'preview@offline';
    _token = null;
    notifyListeners();
  }

  /// Skip the API and open the Kitchen redesign prototype.
  /// Does not replace the classic offline preview.
  void enterKitchenPreview() {
    _isAuthenticated = true;
    _isOfflinePreview = true;
    _isKitchenPreview = true;
    _userId = 0;
    _email = 'preview@kitchen';
    _token = null;
    notifyListeners();
  }

  /// Clears all session data — called from the Settings sheet Sign Out button.
  void logout() {
    _isAuthenticated = false;
    _isOfflinePreview = false;
    _isKitchenPreview = false;
    _userId = null;
    _email = null;
    _token = null;
    notifyListeners();
  }
}
