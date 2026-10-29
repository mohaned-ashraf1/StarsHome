import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import '../core/services/supabase_auth_service.dart';
import '../models/user_profile.dart';

/// Auth states used to drive navigation.
enum AuthState {
  loading,
  unauthenticated,
  authenticated,
  setupRequired, // First-run: no PIN configured yet
  error,
}

class AuthProvider with ChangeNotifier {
  UserProfile? _currentUser;
  AuthState _authState = AuthState.loading;
  String? _errorMessage;

  // Tracks whether each role has a configured PIN
  bool _ownerPinConfigured = false;
  bool _managerPinConfigured = false;

  UserProfile? get currentUser => _currentUser;
  AuthState get authState => _authState;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _authState == AuthState.loading;
  bool get isAuthenticated => _authState == AuthState.authenticated && _currentUser != null;
  bool get isOwner => _currentUser?.isOwner ?? false;
  bool get isManager => _currentUser?.isManager ?? false;
  bool get ownerPinConfigured => _ownerPinConfigured;
  bool get managerPinConfigured => _managerPinConfigured;

  // Supabase Auth state — true when this device can sync with the cloud
  bool get isSupabaseSignedIn => SupabaseAuthService.instance.isSignedIn;

  Future<bool> hasSupabaseCredentials(String role) =>
      SupabaseAuthService.instance.hasCredentials(role);

  Future<String?> getSupabaseEmail(String role) =>
      SupabaseAuthService.instance.getStoredEmail(role);

  /// Returns server-verified role — null if offline or not signed in.
  Future<String?> getServerVerifiedRole() =>
      SupabaseAuthService.instance.getServerVerifiedRole();

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _authState = AuthState.loading;
    notifyListeners();

    try {
      // Initialize default PIN state flags if needed
      await AuthService.instance.initDefaultPinsIfNeeded();

      // Check PIN configuration status
      _ownerPinConfigured = await AuthService.instance.isPinConfigured('owner');
      _managerPinConfigured = await AuthService.instance.isPinConfigured('manager');

      // Attempt to restore a valid session
      final restoredUser = await AuthService.instance.loadStoredSession();

      if (restoredUser != null && AuthService.instance.isSessionValid) {
        _currentUser = restoredUser;
        _authState = AuthState.authenticated;
        debugPrint('[AuthProvider] Session restored for role=${_currentUser!.role}');
        // Re-sign in to Supabase if session restored (non-blocking)
        SupabaseAuthService.instance
            .signInWithRole(_currentUser!.role)
            .then((_) => notifyListeners())
            .ignore();
      } else {
        _currentUser = null;
        _authState = AuthState.unauthenticated;
        debugPrint('[AuthProvider] No valid session — showing login screen');
      }
    } catch (e) {
      debugPrint('[AuthProvider] Init error: $e');
      _currentUser = null;
      _authState = AuthState.unauthenticated;
    }

    notifyListeners();
  }

  /// Attempts login with the given [role] and [pin].
  /// Returns true on success, false on failure.
  /// Sets [errorMessage] with a user-friendly (non-leaking) error on failure.
  Future<bool> login(String role, String pin) async {
    _authState = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await AuthService.instance.loginWithRole(role: role, pin: pin);
      _authState = AuthState.authenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _currentUser = null;
      _authState = AuthState.unauthenticated;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _currentUser = null;
      _authState = AuthState.unauthenticated;
      _errorMessage = 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
      notifyListeners();
      return false;
    }
  }

  /// Changes the PIN for [role]. Requires [currentPin] if a PIN is already set.
  Future<bool> changePin({
    required String role,
    required String newPin,
    String? currentPin,
    String? displayName,
  }) async {
    try {
      await AuthService.instance.changePin(
        role: role,
        newPin: newPin,
        currentPin: currentPin,
        displayName: displayName,
      );
      // Refresh PIN configuration status
      _ownerPinConfigured = await AuthService.instance.isPinConfigured('owner');
      _managerPinConfigured = await AuthService.instance.isPinConfigured('manager');
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'حدث خطأ أثناء تحديث رمز الدخول';
      notifyListeners();
      return false;
    }
  }

  /// Sets the initial PIN during first-run setup.
  Future<bool> setInitialPin({
    required String role,
    required String pin,
    required String displayName,
  }) async {
    try {
      await AuthService.instance.setInitialPin(
        role: role,
        newPin: pin,
        displayName: displayName,
      );
      _ownerPinConfigured = await AuthService.instance.isPinConfigured('owner');
      _managerPinConfigured = await AuthService.instance.isPinConfigured('manager');
      _errorMessage = null;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء إعداد رمز الدخول: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await AuthService.instance.logout();
    _currentUser = null;
    _authState = AuthState.unauthenticated;
    _errorMessage = null;
    notifyListeners();
    debugPrint('[AuthProvider] User logged out');
  }

  /// Clears Supabase credentials for [role] from this device.
  Future<void> removeDeviceAuthorization(String role) async {
    await SupabaseAuthService.instance.clearCredentials(role);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
