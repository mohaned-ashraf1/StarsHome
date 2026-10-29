import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_auth_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/utils/export_helper.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/auth_provider.dart';
import '../../views/auth/device_authorization_screen.dart';
import '../../views/sync/sync_status_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();

  // PIN change controllers
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  String _pinChangeRole = 'owner';

  bool _isSaving = false;
  bool _isChangingPin = false;
  String? _ownerEmail;
  String? _managerEmail;
  bool _supabaseSignedIn = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadDeviceStatus();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _urlController.text = prefs.getString('supabase_url') ?? SyncService.defaultSupabaseUrl;
        _keyController.text = prefs.getString('supabase_anon_key') ?? SyncService.defaultSupabaseAnonKey;
      });
    } catch (_) {}
  }

  Future<void> _loadDeviceStatus() async {
    try {
      final ownerEmail =
          await SupabaseAuthService.instance.getStoredEmail('owner');
      final managerEmail =
          await SupabaseAuthService.instance.getStoredEmail('manager');
      final signedIn = SupabaseAuthService.instance.isSignedIn;
      if (mounted) {
        setState(() {
          _ownerEmail = ownerEmail;
          _managerEmail = managerEmail;
          _supabaseSignedIn = signedIn;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveSupabaseConfig() async {
    final url = _urlController.text.trim();
    final key = _keyController.text.trim();
    if (url.isEmpty || key.isEmpty) {
      _showSnackBar('يرجى إدخال الرابط والمفتاح', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    await SyncService.instance.configureSupabase(url, key);
    setState(() => _isSaving = false);
    _showSnackBar('تم حفظ إعدادات السحابة بنجاح');
  }

  Future<void> _authorizeDevice(String role) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => DeviceAuthorizationScreen(role: role)),
    );
    if (!mounted) return;
    if (result == true) {
      await _loadDeviceStatus();
      if (mounted) _showSnackBar('تم تفويض الجهاز بنجاح وبدأت المزامنة');
    }
  }

  Future<void> _revokeDeviceRole(String role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text('إلغاء تفويض ${role == "owner" ? "المالك" : "المدير"}؟'),
        content: const Text(
          'سيتم إلغاء الجلسة لهذا الدور على هذا الجهاز. '
          'ستحتاج إلى إعادة التفويض للمزامنة مجدداً.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('إلغاء التفويض',
                  style: TextStyle(color: AppColors.expenseRed))),
        ],
      ),
    );
    if (confirmed != true) return;

    await SupabaseAuthService.instance.signOut(role: role);
    if (!mounted) return;
    await Provider.of<AuthProvider>(context, listen: false)
        .removeDeviceAuthorization(role);
    await _loadDeviceStatus();
    _showSnackBar('تم إلغاء تفويض الجهاز لـ ${role == "owner" ? "المالك" : "المدير"}');
  }

  Future<void> _handleChangePin() async {
    final current = _currentPinController.text.trim();
    final newPin = _newPinController.text.trim();
    final confirm = _confirmPinController.text.trim();

    if (newPin.length < 4) {
      _showSnackBar('الرمز الجديد يجب أن يكون 4 أرقام على الأقل', isError: true);
      return;
    }
    if (newPin != confirm) {
      _showSnackBar('الرمزان الجديدان غير متطابقَين', isError: true);
      return;
    }

    setState(() => _isChangingPin = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.changePin(
      role: _pinChangeRole,
      newPin: newPin,
      currentPin: current.isEmpty ? null : current,
    );
    setState(() => _isChangingPin = false);

    if (success) {
      _currentPinController.clear();
      _newPinController.clear();
      _confirmPinController.clear();
      _showSnackBar('تم تحديث الرمز السري بنجاح');
    } else {
      _showSnackBar(auth.errorMessage ?? 'فشل تحديث الرمز السري', isError: true);
    }
  }

  Future<void> _exportCsv(String type, AccountsProvider accounts) async {
    try {
      String csvData;
      String filename;
      if (type == 'purchases') {
        csvData = ExportHelper.exportPurchasesToCsv(accounts.purchases);
        filename =
            'stars_homes_purchases_${DateTime.now().millisecondsSinceEpoch}.csv';
      } else {
        csvData = ExportHelper.exportIncomesToCsv(accounts.incomes);
        filename =
            'stars_homes_incomes_${DateTime.now().millisecondsSinceEpoch}.csv';
      }
      if (!kIsWeb) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsString(csvData);
        if (mounted) {
          _showSnackBar('تم حفظ الملف: ${file.path}');
        }
      } else {
        _showSnackBar('تم إنشاء ملف البيانات بنجاح');
      }
    } catch (e) {
      _showSnackBar('خطأ أثناء التصدير: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppColors.expenseRed : AppColors.incomeGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = Provider.of<AccountsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('الإعدادات والتزامن'),
        backgroundColor: AppColors.primaryNavy,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Sync Status Quick Card ──────────────────────────────────
            _buildSectionHeader(
                'حالة المزامنة', Icons.cloud_sync_outlined),
            const SizedBox(height: 10),
            _buildSyncStatusCard(),
            const SizedBox(height: 24),

            // ── Supabase Connection ─────────────────────────────────────
            _buildSectionHeader(
                'الاتصال بقاعدة البيانات المشتركة (Supabase)',
                Icons.dns_outlined),
            const SizedBox(height: 10),
            _buildCard(
              children: [
                const Text(
                  'اربط التطبيق مع مشروع Supabase المشترك. '
                  'المفتاح المستخدم هو الـ anon key (عام وآمن للمشاركة).',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _urlController,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'Project URL',
                    hintText: 'https://xyz.supabase.co',
                    prefixIcon:
                        Icon(Icons.link, color: AppColors.accentGold),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _keyController,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'Anon Public Key',
                    hintText: 'eyJhbGci...',
                    prefixIcon: Icon(Icons.vpn_key_outlined,
                        color: AppColors.accentGold),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryNavy))
                      : const Icon(Icons.save),
                  label: const Text('حفظ الإعدادات'),
                  onPressed: _isSaving ? null : _saveSupabaseConfig,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Device Authorization ────────────────────────────────────
            _buildSectionHeader(
                'تفويض الجهاز', Icons.verified_user_outlined),
            const SizedBox(height: 10),
            _buildCard(
              children: [
                const Text(
                  'فوِّض هذا الجهاز للوصول إلى قاعدة البيانات المشتركة. '
                  'كلمة مرور حساب المصنع لا تُحفَظ — الجلسة فقط هي المخزَّنة بشكل آمن.',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),

                // Owner role
                _buildRoleAuthRow(
                  role: 'owner',
                  label: 'مالك المصنع',
                  email: _ownerEmail,
                  isCurrentRole: auth.currentUser?.role == 'owner',
                ),
                const SizedBox(height: 12),

                // Manager role
                _buildRoleAuthRow(
                  role: 'manager',
                  label: 'مدير المصنع',
                  email: _managerEmail,
                  isCurrentRole: auth.currentUser?.role == 'manager',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── PIN Management ──────────────────────────────────────────
            _buildSectionHeader(
                'تغيير الرمز السري', Icons.lock_outlined),
            const SizedBox(height: 10),
            _buildCard(
              children: [
                // Role selector
                Row(children: [
                  const Text('الدور:',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(width: 12),
                  _buildRoleChip('owner', 'مالك المصنع'),
                  const SizedBox(width: 8),
                  _buildRoleChip('manager', 'مدير المصنع'),
                ]),
                const SizedBox(height: 16),
                TextField(
                  controller: _currentPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الرمز الحالي (اتركه فارغاً لأول إعداد)',
                    prefixIcon: Icon(Icons.lock_open_outlined,
                        color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الرمز الجديد (4 أرقام على الأقل)',
                    prefixIcon:
                        Icon(Icons.lock_outline, color: AppColors.accentGold),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'تأكيد الرمز الجديد',
                    prefixIcon: Icon(Icons.lock_reset_outlined,
                        color: AppColors.accentGold),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: _isChangingPin
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryNavy))
                      : const Icon(Icons.lock_reset_outlined),
                  label: const Text('تحديث الرمز السري'),
                  onPressed: _isChangingPin ? null : _handleChangePin,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Data Export ─────────────────────────────────────────────
            _buildSectionHeader(
                'تصدير البيانات (CSV)', Icons.file_download_outlined),
            const SizedBox(height: 10),
            _buildCard(
              children: [
                const Text(
                  'احفظ نسخة احتياطية من السجلات المالية كملفات CSV.',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.table_chart_outlined,
                          color: AppColors.accentGold),
                      label: const Text('مشتريات'),
                      onPressed: () => _exportCsv('purchases', accounts),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.savings_outlined,
                          color: AppColors.incomeGreen),
                      label: const Text('إيرادات'),
                      onPressed: () => _exportCsv('incomes', accounts),
                    ),
                  ),
                ]),
              ],
            ),
            const SizedBox(height: 30),

            // App info
            Center(
              child: Column(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.accentGold, width: 1.2),
                    image: const DecorationImage(
                        image: AssetImage('assets/images/logo.png'),
                        fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('STARS HOMES Factory System v1.0.0',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textWhite)),
                const SizedBox(height: 4),
                const Text('العملة: الجنيه المصري (EGP)',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.accentGold)),
              ]),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusCard() {
    return ValueListenableBuilder<SyncStatus>(
      valueListenable: SyncService.instance.statusNotifier,
      builder: (context, status, child) {
        return ValueListenableBuilder<int>(
          valueListenable: SyncService.instance.pendingCountNotifier,
          builder: (context, pending, child) {
            final isOffline = status == SyncStatus.offline;
            final color = status == SyncStatus.synced
                ? AppColors.incomeGreen
                : status == SyncStatus.pendingChanges
                    ? AppColors.warningAmber
                    : status == SyncStatus.syncing
                        ? AppColors.accentGold
                        : AppColors.textMuted;

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SyncStatusScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Row(children: [
                  Icon(_statusIcon(status), color: color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_statusLabel(status),
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        if (pending > 0)
                          Text('$pending عملية في الانتظار',
                              style: const TextStyle(
                                  color: AppColors.warningAmber,
                                  fontSize: 12)),
                        if (isOffline)
                          const Text('البيانات تُحفَظ محلياً',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  Row(children: [
                    TextButton(
                      onPressed: () async {
                        final ok =
                            await SyncService.instance.syncNow();
                        _showSnackBar(ok
                            ? 'تمت المزامنة بنجاح'
                            : 'تعذرت المزامنة');
                      },
                      child: const Text('مزامنة الآن',
                          style: TextStyle(
                              color: AppColors.accentGold, fontSize: 12)),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textMuted, size: 18),
                  ]),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoleAuthRow({
    required String role,
    required String label,
    String? email,
    required bool isCurrentRole,
  }) {
    final isAuthorized = email != null && email.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAuthorized
              ? AppColors.incomeGreen.withOpacity(0.4)
              : AppColors.surfaceBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAuthorized
                ? Icons.verified_user_outlined
                : Icons.device_unknown_outlined,
            color: isAuthorized ? AppColors.incomeGreen : AppColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                Text(
                  isAuthorized ? email : 'غير مفوَّض',
                  style: TextStyle(
                      color: isAuthorized
                          ? AppColors.incomeGreen
                          : AppColors.textMuted,
                      fontSize: 11),
                ),
                if (isCurrentRole && _supabaseSignedIn)
                  const Text('جلسة نشطة الآن',
                      style: TextStyle(
                          color: AppColors.accentGold, fontSize: 10)),
              ],
            ),
          ),
          if (isAuthorized)
            TextButton(
              onPressed: () => _revokeDeviceRole(role),
              child: const Text('إلغاء',
                  style: TextStyle(
                      color: AppColors.expenseRed, fontSize: 12)),
            )
          else
            TextButton(
              onPressed: () => _authorizeDevice(role),
              child: const Text('تفويض',
                  style: TextStyle(
                      color: AppColors.accentGold, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String role, String label) {
    final selected = _pinChangeRole == role;
    return GestureDetector(
      onTap: () => setState(() => _pinChangeRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentGold : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? AppColors.accentGold
                  : AppColors.surfaceBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: selected
                  ? AppColors.primaryNavy
                  : AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 20, color: AppColors.accentGold),
      const SizedBox(width: 8),
      Expanded(
        child: Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.accentGold)),
      ),
    ]);
  }

  IconData _statusIcon(SyncStatus s) {
    switch (s) {
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.synced:
        return Icons.cloud_done_outlined;
      case SyncStatus.pendingChanges:
        return Icons.cloud_upload_outlined;
      case SyncStatus.online:
        return Icons.cloud_outlined;
      case SyncStatus.offline:
        return Icons.cloud_off_outlined;
    }
  }

  String _statusLabel(SyncStatus s) {
    switch (s) {
      case SyncStatus.syncing:
        return 'جاري المزامنة...';
      case SyncStatus.synced:
        return 'مزامنة كاملة';
      case SyncStatus.pendingChanges:
        return 'تغييرات في الانتظار';
      case SyncStatus.online:
        return 'متصل';
      case SyncStatus.offline:
        return 'غير متصل';
    }
  }
}
