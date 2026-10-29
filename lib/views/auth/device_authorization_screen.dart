import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_auth_service.dart';
import '../../core/services/sync_service.dart';

/// Device Authorization Screen
///
/// PURPOSE:
///   Allows a new device to join the shared factory database by signing in
///   with the factory Supabase account (owner or manager).
///
/// SECURITY:
///   - Password is used once for signInWithPassword() and NOT stored.
///   - Supabase SDK stores only refresh_token in flutter_secure_storage.
///   - Role is verified server-side via public.profiles.
///   - If role doesn't match what was expected, authorization is denied.
///
/// WHEN TO SHOW:
///   - First setup on a new device (no existing Supabase session).
///   - After session expires and cannot be refreshed (re-authorization).
///   - Accessible from Settings → Authorize This Device.
class DeviceAuthorizationScreen extends StatefulWidget {
  final String role;
  const DeviceAuthorizationScreen({super.key, required this.role});

  @override
  State<DeviceAuthorizationScreen> createState() =>
      _DeviceAuthorizationScreenState();
}

class _DeviceAuthorizationScreenState
    extends State<DeviceAuthorizationScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _success = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _roleLabel =>
      widget.role == 'owner' ? 'مالك المصنع' : 'مدير المصنع';

  Future<void> _handleAuthorize() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'يرجى إدخال بريد إلكتروني صحيح');
      return;
    }
    if (password.length < 6) {
      setState(
          () => _errorMessage = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Sign in + get server-verified role (password NOT stored)
      final result = await SupabaseAuthService.instance.authorizeDevice(
        email: email,
        password: password,
      );

      // Step 2: Verify the server role matches the requested role
      final serverRole = result.role;
      if (serverRole != null && serverRole != widget.role) {
        setState(() {
          _errorMessage =
              'هذا الحساب مخصص لـ "$serverRole" وليس "$_roleLabel".\n'
              'يرجى استخدام الحساب الصحيح لهذا الدور.';
          _isLoading = false;
        });
        // Sign out — wrong account
        await SupabaseAuthService.instance.signOut();
        return;
      }

      if (serverRole == null && result.user.id.isNotEmpty) {
        // Offline: can't verify role server-side — warn but allow
        debugPrint('[DeviceAuth] Server role unverifiable (offline) — accepting');
      }

      // Step 3: Clear password from memory (it's already not stored)
      _passwordController.clear();

      // Step 4: Trigger initial full sync in background
      SyncService.instance.syncNow().then((ok) {
        debugPrint('[DeviceAuth] Initial sync: ${ok ? "OK" : "failed (will retry)"}');
      }).ignore();

      setState(() {
        _success = true;
        _isLoading = false;
      });

      // Return to caller after brief success display
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).pop(true); // true = authorized successfully
    } on SupabaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[DeviceAuth] Unexpected error: $e');
      setState(() {
        _errorMessage =
            'حدث خطأ غير متوقع. يرجى التحقق من الاتصال بالإنترنت والمحاولة مرة أخرى.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('تفويض الجهاز — $_roleLabel'),
        backgroundColor: AppColors.primaryNavy,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _success ? _buildSuccess() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.verified_user_outlined,
            size: 72, color: AppColors.incomeGreen),
        const SizedBox(height: 20),
        const Text(
          'تم تفويض الجهاز بنجاح!',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.incomeGreen),
        ),
        const SizedBox(height: 12),
        const Text(
          'جاري تحميل بيانات المصنع من قاعدة البيانات المشتركة...',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),
        const CircularProgressIndicator(color: AppColors.accentGold),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accentGold.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.cloud_sync_outlined,
                    color: AppColors.accentGold, size: 22),
                const SizedBox(width: 8),
                Text(
                  'ربط الجهاز بقاعدة بيانات المصنع',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentGold),
                ),
              ]),
              const SizedBox(height: 10),
              const Text(
                'أدخل بيانات حساب المصنع على Supabase. '
                'كلمة المرور لن تُحفظ على الجهاز — يتم استخدامها مرة واحدة '
                'فقط للتحقق من الهوية وإنشاء جلسة آمنة.',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textMuted, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Email
        const Text('البريد الإلكتروني لحساب المصنع',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            hintText: 'owner@starshomes.factory',
            prefixIcon:
                const Icon(Icons.email_outlined, color: AppColors.accentGold),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // Password
        const Text('كلمة مرور حساب المصنع',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textDirection: TextDirection.ltr,
          autocorrect: false,
          enableSuggestions: false,
          onSubmitted: (_) => _handleAuthorize(),
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon:
                const Icon(Icons.lock_outline, color: AppColors.accentGold),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textMuted,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),

        // Error message
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.expenseRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.expenseRed),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.expenseRed, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_errorMessage!,
                      style: const TextStyle(
                          color: AppColors.expenseRed, fontSize: 13)),
                ),
              ],
            ),
          ),

        // Authorize Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGold,
            foregroundColor: AppColors.primaryNavy,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isLoading ? null : _handleAuthorize,
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primaryNavy))
              : const Icon(Icons.verified_user_outlined),
          label: Text(
            _isLoading ? 'جاري التحقق...' : 'تفويض هذا الجهاز',
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 20),

        // Security note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.security_outlined,
                  size: 16, color: AppColors.textMuted),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'كلمة المرور لا تُخزَّن على الجهاز. '
                  'الجلسة تُحفظ بشكل آمن عبر Keychain (iOS) أو '
                  'EncryptedSharedPreferences (Android). '
                  'يُنصح بتغيير كلمة المرور إذا فُقد الجهاز.',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
