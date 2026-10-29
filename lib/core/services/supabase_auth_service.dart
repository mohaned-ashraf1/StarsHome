import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// SupabaseAuthService — Secure Supabase Auth Integration
///
/// SECURITY DESIGN:
///   Problem with storing passwords: even encrypted passwords in app storage
///   are risky — if the device is rooted or the keystore is compromised,
///   the plaintext factory password is exposed.
///
///   SOLUTION — PKCE token storage only (no passwords stored after login):
///   1. Device operator enters email + password ONCE during device authorization.
///   2. Supabase.auth.signInWithPassword() is called.
///   3. Supabase SDK stores the returned JWT access_token + refresh_token
///      in flutter_secure_storage automatically (supabase_flutter handles this).
///   4. On subsequent app starts, Supabase SDK auto-refreshes the session
///      using the refresh_token — no password needed.
///   5. The email is stored in secure storage ONLY for display (not password).
///   6. The factory account password is NEVER stored after the initial sign-in.
///
///   flutter_secure_storage backend:
///   - Android: EncryptedSharedPreferences (AES-256-GCM)
///   - iOS/macOS: Keychain
///   - Windows: Windows Credential Manager (DPAPI)
///
/// ROLES:
///   Factory has 2 Supabase Auth accounts (owner + manager).
///   Role is verified server-side via public.profiles WHERE id = auth.uid().
///   Flutter local role is used for UI only — never trusted by server.
class SupabaseAuthService {
  static final SupabaseAuthService instance = SupabaseAuthService._internal();
  SupabaseAuthService._internal();

  /// flutter_secure_storage with platform-appropriate backends
  /// v11: encryptedSharedPreferences removed (deprecated by Google).
  /// Android now uses AES-GCM via Tink by default — more secure.
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    wOptions: WindowsOptions(
      useBackwardCompatibility: false,
    ),
  );

  // Storage keys — store email ONLY (not password)
  static const _ownerEmailKey = 'sb_auth_owner_email';
  static const _managerEmailKey = 'sb_auth_manager_email';

  // ── Session State ────────────────────────────────────────────────────────

  /// Returns the current Supabase Auth user, or null if not signed in.
  User? get currentUser => _safeCurrentUser();

  User? _safeCurrentUser() {
    try {
      return Supabase.instance.client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// True if there is an active (or auto-restorable) Supabase session.
  bool get isSignedIn => currentUser != null;

  // ── Sign In (called during device authorization — password NOT stored) ───

  /// Signs in to Supabase with email + password.
  /// The Supabase SDK handles secure token persistence (refresh_token only).
  /// The password is used once and NOT stored by this service.
  ///
  /// Returns the authenticated User on success.
  /// Throws [SupabaseAuthException] with user-safe message on failure.
  Future<User> signInWithCredentials({
    required String email,
    required String password,
  }) async {
    try {
      final client = Supabase.instance.client;
      final response = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const SupabaseAuthException('لم يتم التحقق من الحساب على السيرفر');
      }

      // Store email for display purposes ONLY — password is never stored
      final emailKey =
          await _getRoleForUser(user) == 'owner' ? _ownerEmailKey : _managerEmailKey;
      await _secureStorage.write(key: emailKey, value: email.trim());

      debugPrint('[SupabaseAuth] Signed in: ${user.email} uid=${user.id}');
      return user;
    } on AuthException catch (e) {
      debugPrint('[SupabaseAuth] Auth error: ${e.message}');
      throw SupabaseAuthException(_friendlyAuthError(e.message));
    } catch (e) {
      if (e is SupabaseAuthException) rethrow;
      debugPrint('[SupabaseAuth] signInWithCredentials error: $e');
      throw const SupabaseAuthException(
          'تعذر الاتصال بالسيرفر. يرجى التحقق من الاتصال بالإنترنت والمحاولة مرة أخرى.');
    }
  }

  /// Restores the Supabase session on app start using the stored refresh_token.
  /// This is handled automatically by the Supabase SDK — this method only
  /// confirms whether a session was restored.
  Future<User?> restoreSession() async {
    try {
      final client = Supabase.instance.client;
      // Supabase SDK auto-restores session from secure storage on init.
      // We check if the current session is valid.
      final session = client.auth.currentSession;
      if (session == null) return null;

      // Session is expired but refresh_token may be valid — SDK handles refresh
      if (session.isExpired) {
        debugPrint('[SupabaseAuth] Session expired — attempting token refresh');
        try {
          await client.auth.refreshSession();
          return client.auth.currentUser;
        } catch (e) {
          debugPrint('[SupabaseAuth] Token refresh failed: $e — re-authorization required');
          return null;
        }
      }

      debugPrint('[SupabaseAuth] Session restored: uid=${client.auth.currentUser?.id}');
      return client.auth.currentUser;
    } catch (e) {
      debugPrint('[SupabaseAuth] restoreSession error: $e');
      return null;
    }
  }

  /// Signs in using the role that matches the local PIN authentication.
  /// This restores an existing session (no password needed) or returns null
  /// if no valid session exists for this role (user must re-authorize device).
  Future<User?> signInWithRole(String role) async {
    try {
      // First, try to restore existing session from secure storage
      final restored = await restoreSession();
      if (restored != null) {
        // Verify the restored session matches the expected role
        final serverRole = await getServerVerifiedRole();
        if (serverRole == role || serverRole == null) {
          // serverRole null = offline, accept the restored session
          debugPrint('[SupabaseAuth] Session restored for role=$role');
          return restored;
        }
        // Role mismatch — sign out and require re-authorization
        debugPrint(
            '[SupabaseAuth] Role mismatch: expected=$role got=$serverRole — signing out');
        await signOut();
        return null;
      }
      debugPrint('[SupabaseAuth] No stored session for role=$role — device must be authorized');
      return null;
    } catch (e) {
      debugPrint('[SupabaseAuth] signInWithRole error: $e');
      return null;
    }
  }

  // ── Server-Side Role Verification ───────────────────────────────────────

  /// Queries public.profiles to get the server-verified role.
  /// Returns null if offline, not signed in, or profile not found.
  /// CRITICAL: this is the only trusted source of role information.
  Future<String?> getServerVerifiedRole() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final result = await Supabase.instance.client
          .from('profiles')
          .select('role, is_active')
          .eq('id', user.id)
          .maybeSingle();

      if (result == null) {
        debugPrint('[SupabaseAuth] No profile found for uid=${user.id}');
        return null;
      }

      final isActive = result['is_active'] as bool? ?? false;
      if (!isActive) {
        debugPrint('[SupabaseAuth] Account deactivated for uid=${user.id}');
        return null;
      }

      return result['role'] as String?;
    } catch (e) {
      // Offline or network error — cannot verify server-side
      debugPrint('[SupabaseAuth] getServerVerifiedRole offline: $e');
      return null;
    }
  }

  Future<String?> _getRoleForUser(User user) async {
    try {
      final result = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      return result?['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Stored Email (display only) ──────────────────────────────────────────

  /// Returns the stored display email for a role, or null if not set.
  /// This is read from flutter_secure_storage — email only, never password.
  Future<String?> getStoredEmail(String role) async {
    try {
      final key = role == 'owner' ? _ownerEmailKey : _managerEmailKey;
      return await _secureStorage.read(key: key);
    } catch (e) {
      debugPrint('[SupabaseAuth] getStoredEmail error: $e');
      return null;
    }
  }

  /// Returns true if a stored email exists for [role].
  /// This indicates the device was previously authorized for this role.
  Future<bool> hasCredentials(String role) async {
    try {
      final email = await getStoredEmail(role);
      return email != null && email.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ── Device Authorization ─────────────────────────────────────────────────

  /// Validates email + password against Supabase WITHOUT persisting
  /// anything except the session tokens (managed by Supabase SDK).
  /// Use this in DeviceAuthorizationScreen before committing.
  Future<({User user, String? role})> authorizeDevice({
    required String email,
    required String password,
  }) async {
    final user = await signInWithCredentials(email: email, password: password);
    final role = await getServerVerifiedRole();
    return (user: user, role: role);
  }

  /// Removes the stored email for [role] from secure storage.
  /// Does NOT sign out from Supabase — call signOut() separately.
  Future<void> clearStoredEmail(String role) async {
    try {
      final key = role == 'owner' ? _ownerEmailKey : _managerEmailKey;
      await _secureStorage.delete(key: key);
      debugPrint('[SupabaseAuth] Stored email cleared for role=$role');
    } catch (e) {
      debugPrint('[SupabaseAuth] clearStoredEmail error: $e');
    }
  }

  /// Alias for [clearStoredEmail] — used by AuthProvider.
  Future<void> clearCredentials(String role) => clearStoredEmail(role);

  // ── Sign Out ─────────────────────────────────────────────────────────────

  /// Signs out from Supabase and clears the stored email for the current role.
  /// The Supabase SDK removes refresh_tokens from secure storage automatically.
  Future<void> signOut({String? role}) async {
    try {
      if (role != null) await clearStoredEmail(role);
      await Supabase.instance.client.auth.signOut();
      debugPrint('[SupabaseAuth] Signed out');
    } catch (e) {
      debugPrint('[SupabaseAuth] signOut error (non-fatal): $e');
    }
  }

  // ── Utility ──────────────────────────────────────────────────────────────

  /// Returns a masked display string for an email — never exposes the full address.
  static String emailDisplayHash(String email) {
    // Show only domain + first 2 chars of local part
    final parts = email.split('@');
    if (parts.length != 2) return '***@***';
    final local = parts[0];
    final domain = parts[1];
    final masked = local.length > 2 ? '${local.substring(0, 2)}***' : '***';
    return '$masked@$domain';
  }

  static String _friendlyAuthError(String? serverMessage) {
    final msg = serverMessage?.toLowerCase() ?? '';
    if (msg.contains('invalid') || msg.contains('credentials')) {
      return 'بيانات الدخول غير صحيحة. يرجى التحقق من البريد الإلكتروني وكلمة المرور.';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return 'تعذر الاتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'تم تجاوز عدد المحاولات المسموح به. يرجى الانتظار قبل المحاولة مرة أخرى.';
    }
    return 'تعذر تسجيل الدخول. يرجى المحاولة مرة أخرى.';
  }
}

class SupabaseAuthException implements Exception {
  final String message;
  const SupabaseAuthException(this.message);
  @override
  String toString() => 'SupabaseAuthException: $message';
}
