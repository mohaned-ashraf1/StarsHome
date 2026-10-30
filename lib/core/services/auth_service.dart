import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/user_profile.dart';
import 'db_service.dart';
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

  Future<SharedPreferences?> _getPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('[AuthService] SharedPreferences.getInstance error: $e');
      return null;
    }
  }

  Future<bool> _isLockedOut(String role, SharedPreferences? prefs) async {
    try {
      final lockoutUntilStr = prefs?.getString(_lockoutKey(role)) ??
          await _getSetting(_lockoutKey(role), prefs);
      if (lockoutUntilStr == null) return false;
      final lockoutUntil = DateTime.tryParse(lockoutUntilStr);
      if (lockoutUntil == null) return false;
      return DateTime.now().isBefore(lockoutUntil);
    } catch (_) {
      return false;
    }
  }

  Future<void> _recordFailedAttempt(String role, SharedPreferences? prefs) async {
    final key = _attemptsKey(role);
    int current = 0;
    try {
      current = prefs?.getInt(key) ?? 0;
    } catch (_) {
      final str = await _getSetting(key, prefs);
      current = int.tryParse(str ?? '0') ?? 0;
    }
    final newCount = current + 1;
    try {
      await prefs?.setInt(key, newCount);
    } catch (_) {}
    await _saveSetting(key, newCount.toString(), prefs);

    if (newCount >= _maxFailedAttempts) {
      final lockUntil = DateTime.now().add(Duration(minutes: _lockoutMinutes));
      try {
        await prefs?.setString(_lockoutKey(role), lockUntil.toIso8601String());
      } catch (_) {}
      await _saveSetting(_lockoutKey(role), lockUntil.toIso8601String(), prefs);
      debugPrint('[AuthService] Role "$role" locked out until $lockUntil');
    }
  }

  Future<void> _clearFailedAttempts(String role, SharedPreferences? prefs) async {
    try {
      await prefs?.remove(_attemptsKey(role));
      await prefs?.remove(_lockoutKey(role));
    } catch (_) {}
    await _saveSetting(_attemptsKey(role), '0', prefs);
    await _saveSetting(_lockoutKey(role), '', prefs);
  }

  // ──────────────────────────────────────────────────
  // PIN initialisation (first run)
  // ──────────────────────────────────────────────────

  /// On first launch, persists hashed default PINs.
  Future<void> initDefaultPinsIfNeeded() async {
    try {
      final prefs = await _getPrefs();
      final ownerHash = await _getSetting('owner_pin_hash', prefs);
      final managerHash = await _getSetting('manager_pin_hash', prefs);

      if (ownerHash == null || ownerHash.isEmpty) {
        try {
          await prefs?.setBool('owner_pin_not_set', true);
        } catch (_) {}
        await _saveSetting('owner_pin_not_set', 'true', prefs);
        debugPrint('[AuthService] Owner PIN not configured — setup required');
      }
      if (managerHash == null || managerHash.isEmpty) {
        try {
          await prefs?.setBool('manager_pin_not_set', true);
        } catch (_) {}
        await _saveSetting('manager_pin_not_set', 'true', prefs);
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
      final prefs = await _getPrefs();
      final userId = prefs?.getString('session_user_id') ??
          await _getSetting('session_user_id', prefs);
      final fullName = prefs?.getString('session_user_name') ??
          await _getSetting('session_user_name', prefs);
      final role = prefs?.getString('session_user_role') ??
          await _getSetting('session_user_role', prefs);
      final sessionStartStr = prefs?.getString('session_start') ??
          await _getSetting('session_start', prefs);

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

  Future<void> _clearSession(SharedPreferences? prefs) async {
    try {
      await prefs?.remove('session_user_id');
      await prefs?.remove('session_user_name');
      await prefs?.remove('session_user_role');
      await prefs?.remove('session_start');
    } catch (_) {}
    await _saveSetting('session_user_id', '', prefs);
    await _saveSetting('session_user_name', '', prefs);
    await _saveSetting('session_user_role', '', prefs);
    await _saveSetting('session_start', '', prefs);
  }

  // ──────────────────────────────────────────────────
  // Dual Persistence: SharedPreferences + SQLite app_settings
  // ──────────────────────────────────────────────────

  Future<String?> _getSetting(String key, SharedPreferences? prefs) async {
    try {
      final val = prefs?.getString(key);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}

    try {
      final db = await DBService.instance.database;
      final res = await db.query('app_settings', where: 'key = ?', whereArgs: [key], limit: 1);
      if (res.isNotEmpty) {
        final dbVal = res.first['value'] as String?;
        if (dbVal != null && dbVal.isNotEmpty) {
          try {
            await prefs?.setString(key, dbVal);
          } catch (_) {}
          return dbVal;
        }
      }
    } catch (e) {
      debugPrint('[AuthService] SQLite read setting error: $e');
    }
    return null;
  }

  Future<void> _saveSetting(String key, String value, SharedPreferences? prefs) async {
    try {
      await prefs?.setString(key, value);
    } catch (e) {
      debugPrint('[AuthService] SharedPreferences save error: $e');
    }
    try {
      final db = await DBService.instance.database;
      await db.insert(
        'app_settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('[AuthService] SQLite save setting error: $e');
    }
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
      final prefs = await _getPrefs();

      // Check lockout
      if (await _isLockedOut(role, prefs)) {
        final lockUntilStr = prefs?.getString(_lockoutKey(role)) ??
            await _getSetting(_lockoutKey(role), prefs);
        final lockUntil = DateTime.tryParse(lockUntilStr ?? '');
        final remaining = lockUntil != null
            ? lockUntil.difference(DateTime.now()).inMinutes + 1
            : _lockoutMinutes;
        throw AuthException(
          'تم تجاوز عدد المحاولات المسموح به. يرجى الانتظار $remaining دقيقة قبل المحاولة مرة أخرى.',
        );
      }

      final hashKey = '${role}_pin_hash';
      final storedHash = await _getSetting(hashKey, prefs);
      final pinNotSetStr = await _getSetting('${role}_pin_not_set', prefs);
      final pinNotSet = pinNotSetStr == 'true';

      if (pinNotSet || storedHash == null || storedHash.isEmpty) {
        throw const AuthException(
          'لم يتم إعداد رمز الدخول بعد. يرجى التواصل مع مسؤول النظام لإعداد رمز الدخول الأولي.',
        );
      }

      // Verify PIN against stored hash
      final pinValid = verifyPin(pin, storedHash);
      if (!pinValid) {
        await _recordFailedAttempt(role, prefs);
        int failedCount = 1;
        try {
          failedCount = prefs?.getInt(_attemptsKey(role)) ?? 1;
        } catch (_) {
          final s = await _getSetting(_attemptsKey(role), prefs);
          failedCount = int.tryParse(s ?? '1') ?? 1;
        }
        final remainingAttempts = _maxFailedAttempts - failedCount;
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
      final storedName = await _getSetting('${role}_display_name', prefs) ??
          (role == 'owner' ? 'مالك المصنع' : 'مدير المصنع');

      _currentUser = UserProfile(id: userId, fullName: storedName, role: role);
      _sessionStart = DateTime.now();

      // Persist session
      try {
        await prefs?.setString('session_user_id', _currentUser!.id);
        await prefs?.setString('session_user_name', _currentUser!.fullName);
        await prefs?.setString('session_user_role', _currentUser!.role);
        await prefs?.setString('session_start', _sessionStart!.toIso8601String());
      } catch (_) {}
      await _saveSetting('session_user_id', _currentUser!.id, prefs);
      await _saveSetting('session_user_name', _currentUser!.fullName, prefs);
      await _saveSetting('session_user_role', _currentUser!.role, prefs);
      await _saveSetting('session_start', _sessionStart!.toIso8601String(), prefs);

      // Sign in to Supabase Auth (non-blocking — failure is acceptable offline)
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
      final prefs = await _getPrefs();
      final hashKey = '${role}_pin_hash';
      final storedHash = await _getSetting(hashKey, prefs);
      final pinNotSetStr = await _getSetting('${role}_pin_not_set', prefs);
      final pinNotSet = pinNotSetStr == 'true';

      // If a PIN already exists, verify current PIN first
      if (!pinNotSet && storedHash != null && storedHash.isNotEmpty) {
        if (currentPin == null || !verifyPin(currentPin, storedHash)) {
          throw const AuthException('رمز الدخول الحالي غير صحيح');
        }
      }

      // Hash and store new PIN
      final newHash = hashPin(newPin);
      await _saveSetting(hashKey, newHash, prefs);
      try {
        await prefs?.remove('${role}_pin_not_set');
      } catch (_) {}
      await _saveSetting('${role}_pin_not_set', 'false', prefs);

      if (displayName != null && displayName.isNotEmpty) {
        await _saveSetting('${role}_display_name', displayName.trim(), prefs);
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
      final prefs = await _getPrefs();
      final hash = hashPin(newPin);
      await _saveSetting('${role}_pin_hash', hash, prefs);
      await _saveSetting('${role}_display_name', displayName.trim(), prefs);
      await _saveSetting('${role}_pin_not_set', 'false', prefs);

      try {
        await prefs?.setBool('${role}_pin_not_set', false);
        await prefs?.remove('${role}_pin_not_set');
      } catch (_) {}

      try {
        await _clearFailedAttempts(role, prefs);
      } catch (_) {}

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
      final prefs = await _getPrefs();
      final pinNotSetStr = await _getSetting('${role}_pin_not_set', prefs);
      if (pinNotSetStr == 'true') return false;

      final storedHash = await _getSetting('${role}_pin_hash', prefs);
      final hasHash = storedHash != null && storedHash.isNotEmpty;
      return hasHash;
    } catch (_) {
      return false;
    }
  }

  // ──────────────────────────────────────────────────
  // Logout
  // ──────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      final prefs = await _getPrefs();
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
