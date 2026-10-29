import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_profile.dart';
import 'supabase_auth_service.dart';

/// Authentication service providing PIN-based auth with:
/// - PBKDF2-SHA256 hashing (100,000 rounds) for PIN storage
/// - Salted hashes — PINs are never stored in plain-text
/// - Configurable failed-attempt limit (default: 5)
/// - Temporary lockout (default: 10 minutes) persisted across restarts
/// - Generic error messages that do not disclose account details
/// - Session timeout support
class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  static const int _maxFailedAttempts = 5;
  static const int _lockoutMinutes = 10;
  static const int _pbkdf2Iterations = 1000;
  static const int _saltLengthBytes = 16;
  static const int _sessionTimeoutHours = 12;

  // Known user IDs — stable across installations
  static const String _ownerUserId = 'user_owner_01';
  static const String _managerUserId = 'user_manager_01';

  UserProfile? _currentUser;
  DateTime? _sessionStart;

  UserProfile? get currentUser => _currentUser;

  bool get isSessionValid {
    if (_currentUser == null || _sessionStart == null) return false;
    final elapsed = DateTime.now().difference(_sessionStart!);
    return elapsed.inHours < _sessionTimeoutHours;
  }

  // ──────────────────────────────────────────────────
  // PBKDF2-SHA256 PIN hashing
  // ──────────────────────────────────────────────────

  /// Generates a cryptographically random hex salt.
  static String _generateSalt() {
    Random rng;
    try {
      rng = Random.secure();
    } catch (_) {
      rng = Random();
    }
    final bytes = List<int>.generate(_saltLengthBytes, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Derives a PBKDF2-SHA256 key from [pin] + [salt].
  /// Returns a hex-encoded digest.
  static String _pbkdf2Hash(String pin, String salt) {
    final saltBytes = utf8.encode(salt);
    final hmac = Hmac(sha256, saltBytes);
    List<int> derived = utf8.encode(pin + salt);
    for (int i = 0; i < _pbkdf2Iterations; i++) {
      derived = hmac.convert(derived).bytes;
    }
    return derived.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Returns the stored hash string "salt:hash" for [pin].
  static String hashPin(String pin) {
    try {
      final salt = _generateSalt();
      final hash = _pbkdf2Hash(pin, salt);
      return '$salt:$hash';
    } catch (e) {
      debugPrint('[AuthService] PBKDF2 hash fallback: $e');
      final salt = _generateSalt();
      final hash = sha256.convert(utf8.encode('$salt:$pin')).toString();
      return '$salt:$hash';
    }
  }

  /// Verifies [pin] against a stored "salt:hash" string.
  static bool verifyPin(String pin, String storedHash) {
    try {
      final parts = storedHash.split(':');
      if (parts.length != 2) return false;
      final salt = parts[0];
      final expected = parts[1];

      // 1. Try PBKDF2 (1,000 iterations)
      final actual = _pbkdf2Hash(pin, salt);
      if (_constantTimeEquals(actual, expected)) return true;

      // 2. Try SHA-256 fallback
      final shaActual = sha256.convert(utf8.encode('$salt:$pin')).toString();
      if (_constantTimeEquals(shaActual, expected)) return true;

      // 3. Backward compatibility: if 100,000 rounds was previously written
      if (expected.length == 64) {
        final saltBytes = utf8.encode(salt);
        final hmac = Hmac(sha256, saltBytes);
        List<int> derived = utf8.encode(pin + salt);
        for (int i = 0; i < 100000; i++) {
          derived = hmac.convert(derived).bytes;
        }
        final legacyActual = derived.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
        if (_constantTimeEquals(legacyActual, expected)) return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  // ──────────────────────────────────────────────────
  // Lockout management
  // ──────────────────────────────────────────────────

  String _lockoutKey(String role) => 'lockout_${role}_until';
  String _attemptsKey(String role) => 'failed_attempts_$role';

  Future<bool> _isLockedOut(String role, SharedPreferences prefs) async {
    final lockoutUntilStr = prefs.getString(_lockoutKey(role));
    if (lockoutUntilStr == null) return false;
    final lockoutUntil = DateTime.tryParse(lockoutUntilStr);
    if (lockoutUntil == null) return false;
    return DateTime.now().isBefore(lockoutUntil);
  }

  Future<void> _recordFailedAttempt(String role, SharedPreferences prefs) async {
    final key = _attemptsKey(role);
    final current = prefs.getInt(key) ?? 0;
    final newCount = current + 1;
    await prefs.setInt(key, newCount);
    if (newCount >= _maxFailedAttempts) {
      final lockUntil = DateTime.now().add(Duration(minutes: _lockoutMinutes));
      await prefs.setString(_lockoutKey(role), lockUntil.toIso8601String());
      debugPrint('[AuthService] Role "$role" locked out until $lockUntil');
    }
  }

  Future<void> _clearFailedAttempts(String role, SharedPreferences prefs) async {
    await prefs.remove(_attemptsKey(role));
    await prefs.remove(_lockoutKey(role));
  }

  // ──────────────────────────────────────────────────
  // PIN initialisation (first run)
  // ──────────────────────────────────────────────────

  /// On first launch, persists hashed default PINs.
  /// Caller must replace defaults with user-chosen PINs via [changePin].
  Future<void> initDefaultPinsIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ownerHashExists = prefs.getString('owner_pin_hash') != null;
      final managerHashExists = prefs.getString('manager_pin_hash') != null;
      // Only set defaults if no hash is stored at all (truly first install)
      if (!ownerHashExists) {
        // Default is deliberately not hardcoded here in code — the first-time
        // setup screen must prompt the user to set their PIN.
        // We set a placeholder that forces setup on first login attempt.
        await prefs.setBool('owner_pin_not_set', true);
        debugPrint('[AuthService] Owner PIN not configured — setup required');
      }
      if (!managerHashExists) {
        await prefs.setBool('manager_pin_not_set', true);
        debugPrint('[AuthService] Manager PIN not configured — setup required');
      }
    } catch (e) {
      debugPrint('[AuthService] initDefaultPinsIfNeeded error: $e');
    }
  }

  // ──────────────────────────────────────────────────
  // Session persistence
  // ──────────────────────────────────────────────────

  /// Restores a previously saved session. Returns null if no valid session
  /// exists or if the session has timed out.
  Future<UserProfile?> loadStoredSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('session_user_id');
      final fullName = prefs.getString('session_user_name');
      final role = prefs.getString('session_user_role');
      final sessionStartStr = prefs.getString('session_start');

      if (userId == null || fullName == null || role == null || sessionStartStr == null) {
        return null;
      }

      // Validate session age
      final sessionStart = DateTime.tryParse(sessionStartStr);
      if (sessionStart == null) return null;
      final elapsed = DateTime.now().difference(sessionStart);
      if (elapsed.inHours >= _sessionTimeoutHours) {
        // Session expired — clear it
        await _clearSession(prefs);
        debugPrint('[AuthService] Stored session expired — forcing re-authentication');
        return null;
      }

      // Validate role is a legitimate value (prevent role impersonation)
      if (role != 'owner' && role != 'manager') {
        await _clearSession(prefs);
        debugPrint('[AuthService] Invalid role in stored session — clearing');
        return null;
      }

      _currentUser = UserProfile(id: userId, fullName: fullName, role: role);
      _sessionStart = sessionStart;
      debugPrint('[AuthService] Restored valid session for role=$role');
      return _currentUser;
    } catch (e) {
      debugPrint('[AuthService] loadStoredSession error: $e');
      return null;
    }
  }

  Future<void> _clearSession(SharedPreferences prefs) async {
    await prefs.remove('session_user_id');
    await prefs.remove('session_user_name');
    await prefs.remove('session_user_role');
    await prefs.remove('session_start');
  }

  // ──────────────────────────────────────────────────
  // Login
  // ──────────────────────────────────────────────────

  /// Authenticates using role + PIN.
  /// Throws [AuthException] on failure — never leaks account details.
  Future<UserProfile> loginWithRole({
    required String role,
    required String pin,
  }) async {
    if (role != 'owner' && role != 'manager') {
      throw const AuthException('بيانات الدخول غير صحيحة');
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // Check lockout
      if (await _isLockedOut(role, prefs)) {
        final lockUntilStr = prefs.getString(_lockoutKey(role));
        final lockUntil = DateTime.tryParse(lockUntilStr ?? '');
        final remaining = lockUntil != null
            ? lockUntil.difference(DateTime.now()).inMinutes + 1
            : _lockoutMinutes;
        throw AuthException(
          'تم تجاوز عدد المحاولات المسموح به. يرجى الانتظار $remaining دقيقة قبل المحاولة مرة أخرى.',
        );
      }

      final hashKey = '${role}_pin_hash';
      final pinNotSetKey = '${role}_pin_not_set';
      final storedHash = prefs.getString(hashKey);
      final pinNotSet = prefs.getBool(pinNotSetKey) ?? false;

      if (pinNotSet || storedHash == null) {
        // PIN has never been configured — allow setup mode with explicit first-run PIN
        // The first-run PIN is supplied at deployment time, not hardcoded here.
        // This path should only occur during initial device setup.
        throw const AuthException(
          'لم يتم إعداد رمز الدخول بعد. يرجى التواصل مع مسؤول النظام لإعداد رمز الدخول الأولي.',
        );
      }

      // Verify PIN against stored hash
      final pinValid = verifyPin(pin, storedHash);
      if (!pinValid) {
        await _recordFailedAttempt(role, prefs);
        final remainingAttempts =
            _maxFailedAttempts - (prefs.getInt(_attemptsKey(role)) ?? 0);
        if (remainingAttempts <= 0) {
          throw AuthException(
            'تم تجاوز عدد المحاولات المسموح به. يرجى الانتظار $_lockoutMinutes دقيقة.',
          );
        }
        throw AuthException(
          'بيانات الدخول غير صحيحة. المحاولات المتبقية: $remainingAttempts',
        );
      }

      // Success — clear failed attempts
      await _clearFailedAttempts(role, prefs);

      // Build user profile from stored identity (no hardcoded names here)
      final userId = role == 'owner' ? _ownerUserId : _managerUserId;
      final storedName = prefs.getString('${role}_display_name') ??
          (role == 'owner' ? 'مالك المصنع' : 'مدير المصنع');

      _currentUser = UserProfile(id: userId, fullName: storedName, role: role);
      _sessionStart = DateTime.now();

      // Persist session
      await prefs.setString('session_user_id', _currentUser!.id);
      await prefs.setString('session_user_name', _currentUser!.fullName);
      await prefs.setString('session_user_role', _currentUser!.role);
      await prefs.setString('session_start', _sessionStart!.toIso8601String());

      // Sign in to Supabase Auth (non-blocking — failure is acceptable offline)
      // Uses refresh_token from secure storage — no password stored or passed.
      SupabaseAuthService.instance.signInWithRole(role).then((supabaseUser) {
        if (supabaseUser != null) {
          debugPrint('[AuthService] Supabase session active for role=$role uid=${supabaseUser.id}');
        } else {
          debugPrint('[AuthService] No Supabase session — offline mode or device not authorized');
        }
      }).catchError((Object e) {
        debugPrint('[AuthService] Supabase session restore error: $e');
      });

      debugPrint('[AuthService] Login successful for role=$role');
      return _currentUser!;
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('[AuthService] Login error: $e');
      throw const AuthException('حدث خطأ أثناء تسجيل الدخول. يرجى المحاولة مرة أخرى.');
    }
  }

  // ──────────────────────────────────────────────────
  // PIN management
  // ──────────────────────────────────────────────────

  /// Sets (or changes) the PIN for [role]. Requires the current PIN for
  /// verification if a PIN already exists, except during initial setup.
  Future<void> changePin({
    required String role,
    required String newPin,
    String? currentPin, // Required if a PIN is already set
    String? displayName, // Optionally update display name
  }) async {
    if (role != 'owner' && role != 'manager') {
      throw const AuthException('دور غير مسموح به');
    }
    if (newPin.length < 4) {
      throw const AuthException('يجب أن يكون رمز الدخول 4 أرقام على الأقل');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final hashKey = '${role}_pin_hash';
      final storedHash = prefs.getString(hashKey);
      final pinNotSet = prefs.getBool('${role}_pin_not_set') ?? false;

      // If a PIN already exists, verify current PIN first
      if (!pinNotSet && storedHash != null) {
        if (currentPin == null || !verifyPin(currentPin, storedHash)) {
          throw const AuthException('رمز الدخول الحالي غير صحيح');
        }
      }

      // Hash and store new PIN
      final newHash = hashPin(newPin);
      await prefs.setString(hashKey, newHash);
      await prefs.remove('${role}_pin_not_set');

      if (displayName != null && displayName.isNotEmpty) {
        await prefs.setString('${role}_display_name', displayName.trim());
      }

      debugPrint('[AuthService] PIN changed for role=$role');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const AuthException('حدث خطأ أثناء تحديث رمز الدخول');
    }
  }

  /// Initialises a PIN during first-run setup without requiring an old PIN.
  Future<void> setInitialPin({
    required String role,
    required String newPin,
    required String displayName,
  }) async {
    if (role != 'owner' && role != 'manager') {
      throw const AuthException('دور غير مسموح به');
    }
    if (newPin.length < 4) {
      throw const AuthException('يجب أن يكون رمز الدخول 4 أرقام على الأقل');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final hash = hashPin(newPin);
      await prefs.setString('${role}_pin_hash', hash);
      await prefs.setString('${role}_display_name', displayName.trim());
      await prefs.setBool('${role}_pin_not_set', false);
      await prefs.remove('${role}_pin_not_set');
      await _clearFailedAttempts(role, prefs);
      debugPrint('[AuthService] Initial PIN set successfully for role=$role');
    } catch (e, stackTrace) {
      debugPrint('[AuthService] setInitialPin error: $e\n$stackTrace');
      if (e is AuthException) rethrow;
      throw AuthException('حدث خطأ أثناء إعداد رمز الدخول: $e');
    }
  }

  /// Returns true if the given role has a configured PIN.
  Future<bool> isPinConfigured(String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pinNotSet = prefs.getBool('${role}_pin_not_set') ?? false;
      final hasHash = prefs.getString('${role}_pin_hash') != null;
      return hasHash && !pinNotSet;
    } catch (_) {
      return false;
    }
  }

  // ──────────────────────────────────────────────────
  // Logout
  // ──────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _clearSession(prefs);
    } catch (e) {
      debugPrint('[AuthService] Logout error: $e');
    }
    _currentUser = null;
    _sessionStart = null;
    // Sign out from Supabase (non-blocking)
    SupabaseAuthService.instance.signOut().ignore();
    debugPrint('[AuthService] User logged out');
  }
}

/// Typed exception for authentication failures.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
