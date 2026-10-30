import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _selectedRole = 'owner';
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // First-run setup mode
  bool _isSetupMode = false;
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkSetupRequired();
  }

  void _checkSetupRequired() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    // If neither role has a PIN configured, show first-run setup for owner first
    if (!auth.ownerPinConfigured) {
      setState(() {
        _selectedRole = 'owner';
        _isSetupMode = true;
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      setState(() => _errorMessage = 'يرجى إدخال رمز الدخول');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(_selectedRole, pin);

    if (!mounted) return;

    if (success) {
      _pinController.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() {
        _errorMessage = auth.errorMessage ?? 'بيانات الدخول غير صحيحة';
        _isLoading = false;
        _pinController.clear();
      });
    }
  }

  Future<void> _handleSetupPin() async {
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();
    final displayName = _displayNameController.text.trim();

    if (displayName.isEmpty) {
      setState(() => _errorMessage = 'يرجى إدخال اسم المستخدم');
      return;
    }
    if (pin.length < 4) {
      setState(() => _errorMessage = 'يجب أن يكون الرمز 4 أرقام على الأقل');
      return;
    }
    if (pin != confirmPin) {
      setState(() => _errorMessage = 'الرمزان غير متطابقان');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.setInitialPin(
      role: _selectedRole,
      pin: pin,
      displayName: displayName,
    );

    if (!mounted) return;

    if (success) {
      // Automatically log in with the newly configured PIN
      final loginSuccess = await auth.login(_selectedRole, pin);
      if (!mounted) return;

      if (loginSuccess) {
        _pinController.clear();
        _confirmPinController.clear();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        return;
      }

      _pinController.clear();
      _confirmPinController.clear();
      setState(() {
        _isSetupMode = false;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إعداد رمز الدخول بنجاح. يرجى تسجيل الدخول الآن.'),
          backgroundColor: AppColors.incomeGreen,
        ),
      );
    } else {
      setState(() {
        _errorMessage = auth.errorMessage ?? 'حدث خطأ أثناء إعداد رمز الدخول';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.accentGold, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentGold.withOpacity(0.25),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                        image: const DecorationImage(
                          image: AssetImage('assets/images/logo.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'STARS HOMES',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.4,
                      color: AppColors.accentGold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    AppStrings.appSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textWhite,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isSetupMode ? 'إعداد رمز الدخول الأولي' : AppStrings.systemTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: _isSetupMode ? AppColors.warningAmber : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Role Selection
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        _buildRoleTab('owner', 'مالك المصنع', Icons.admin_panel_settings_outlined),
                        const SizedBox(width: 6),
                        _buildRoleTab('manager', 'مدير المصنع', Icons.manage_accounts_outlined),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Setup mode: display name
                  if (_isSetupMode) ...[
                    const Text(
                      'اسم المستخدم',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _displayNameController,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'مثال: م/ ابراهيم نجم',
                        prefixIcon: Icon(Icons.person_outline, color: AppColors.accentGold),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // PIN Input
                  Text(
                    _isSetupMode ? 'رمز الدخول الجديد (4 أرقام على الأقل)' : 'الرمز السري',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      letterSpacing: 6,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: '••••',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.accentGold),
                      errorText: _errorMessage,
                      errorMaxLines: 4,
                    ),
                    onSubmitted: (_) => _isSetupMode ? _handleSetupPin() : _handleLogin(),
                  ),

                  // Setup mode: confirm PIN
                  if (_isSetupMode) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'تأكيد الرمز السري',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _confirmPinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        letterSpacing: 6,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        hintText: '••••',
                        prefixIcon: Icon(Icons.lock_reset_outlined, color: AppColors.accentGold),
                      ),
                      onSubmitted: (_) => _handleSetupPin(),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Action Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isLoading
                        ? null
                        : (_isSetupMode ? _handleSetupPin : _handleLogin),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryNavy,
                            ),
                          )
                        : Text(
                            _isSetupMode ? 'حفظ رمز الدخول' : 'تسجيل الدخول للمصنع',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isSetupMode
                              ? Icons.info_outline
                              : Icons.offline_bolt_outlined,
                          size: 18,
                          color: AppColors.accentGold,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isSetupMode
                                ? 'تحتاج إلى إعداد رمز الدخول قبل استخدام النظام. اختر رمزاً سرياً آمناً لا يقل عن 4 أرقام.'
                                : 'يعمل النظام دون الحاجة لاتصال بالإنترنت، ويقوم بالمزامنة التلقائية عند عودة الاتصال.',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(String roleKey, String label, IconData icon) {
    final isSelected = _selectedRole == roleKey;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRole = roleKey;
            _errorMessage = null;
            _pinController.clear();
            _confirmPinController.clear();
          });
          // Re-check setup mode for selected role
          final auth = Provider.of<AuthProvider>(context, listen: false);
          setState(() {
            _isSetupMode = roleKey == 'owner'
                ? !auth.ownerPinConfigured
                : !auth.managerPinConfigured;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentGold : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.primaryNavy : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primaryNavy : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
