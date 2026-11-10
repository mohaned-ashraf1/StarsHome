import 'dart:io';
import 'package:flutter/material.dart';
import 'package:stars_home/backend/services/backup_service.dart';
import 'package:stars_home/backend/services/google_drive_service.dart';
import 'package:stars_home/backend/services/sync_service.dart';
import 'package:stars_home/frontend/constants/app_colors.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _isLoading = true;
  bool _isCreatingBackup = false;
  List<BackupRecordItem> _backups = [];
  String? _selectedSchedule = 'daily';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await GoogleDriveService.instance.init();
    final list = await BackupService.instance.listBackups();
    if (mounted) {
      setState(() {
        _backups = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCreateBackup() async {
    setState(() => _isCreatingBackup = true);
    try {
      final file = await BackupService.instance.createBackup(
        type: 'manual',
        notes: 'نسخة احتياطية يدوية تم إنشاؤها بواسطة الإدارة',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إنشاء النسخة الاحتياطية بنجاح (${file.uri.pathSegments.last})'),
            backgroundColor: AppColors.incomeGreen,
          ),
        );
      }
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل إنشاء النسخة: $e'),
            backgroundColor: AppColors.expenseRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingBackup = false);
    }
  }

  Future<void> _handleVerifyBackup(BackupRecordItem item) async {
    if (item.filePath == null) return;
    final file = File(item.filePath!);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.accentGold)),
    );

    try {
      final result = await BackupService.instance.verifyBackup(file);
      if (mounted) Navigator.pop(context); // Close loader

      final metadata = result['metadata'] as Map<String, dynamic>;
      final sha = result['sha256'] as String;

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Row(
            children: [
              Icon(Icons.verified_rounded, color: AppColors.incomeGreen),
              SizedBox(width: 8),
              Text('النسخة سليمة ومعتمدة 100%',
                  style: TextStyle(color: AppColors.textWhite, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الملف: ${item.filename}',
                  style: const TextStyle(color: AppColors.accentGold, fontSize: 12)),
              const SizedBox(height: 6),
              Text('إصدار التطبيق عند النسخ: ${metadata['app_version']}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              Text('عدد الجداول: ${metadata['tables_count']}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 10),
              const Text('بصمة التشفير الرقمية (SHA-256):',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              SelectableText(sha,
                  style: const TextStyle(color: AppColors.textWhite, fontSize: 10)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق', style: TextStyle(color: AppColors.accentGold)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل التحقق من النسخة: $e'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
    }
  }

  Future<void> _handleRestoreBackup(BackupRecordItem item) async {
    if (item.filePath == null) return;
    final file = File(item.filePath!);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.expenseRed, size: 28),
            SizedBox(width: 8),
            Text('تأكيد استرجاع البيانات',
                style: TextStyle(color: AppColors.expenseRed, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تنبيه أمان هام:\nسيتم استبدال البيانات التشغيلية الحالية بالبيانات المحفوظة داخل هذه النسخة.',
              style: TextStyle(color: AppColors.textWhite, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.incomeGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '🛡️ نظام الأمان التلقائي: سيقوم البرنامج تلقائياً بإنشاء نسخة احتياطية جديدة من بياناتك الحالية فوراً قبل البدء في الاسترجاع لحمايتك من أي فقدان غير مقصود.',
                style: TextStyle(color: AppColors.incomeGreen, fontSize: 11, height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
            Text('النسخة المراد استرجاعها: ${item.filename}',
                style: const TextStyle(color: AppColors.accentGold, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء التراجع', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نعم، استرجع النسخة الآن',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.accentGold)),
    );

    try {
      await BackupService.instance.restoreBackup(file, confirmed: true);
      if (!mounted) return;
      Navigator.pop(context); // Close loader

      await SyncService.reloadAllProviders(context);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم استرجاع البيانات بنجاح وتحديث كافة الشاشات!'),
          backgroundColor: AppColors.incomeGreen,
        ),
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل استرجاع النسخة: $e'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
    }
  }

  Future<void> _handleDeleteBackup(BackupRecordItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('حذف النسخة الاحتياطية؟',
            style: TextStyle(color: AppColors.textWhite)),
        content: Text('هل أنت متأكد من حذف الملف "${item.filename}"؟',
            style: const TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف نهائياً', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await BackupService.instance.deleteBackup(item);
    await _loadData();
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} كيلوبايت';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} ميجابايت';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('النسخ الاحتياطي والاسترجاع'),
        backgroundColor: AppColors.primaryNavy,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Google Drive Cloud Card
                  _buildGoogleDriveCard(),
                  const SizedBox(height: 18),

                  // Actions Box
                  _buildCreateBackupCard(),
                  const SizedBox(height: 24),

                  // History list
                  const Row(
                    children: [
                      Icon(Icons.history_rounded, color: AppColors.accentGold, size: 20),
                      SizedBox(width: 8),
                      Text('سجل النسخ الاحتياطية المحفوظة',
                          style: TextStyle(
                              color: AppColors.textWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_backups.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'لا توجد نسخ احتياطية مسجلة حتى الآن.\nاضغط على "إنشاء نسخة احتياطية فورية" لإنشاء أول نسخة.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _backups.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) => _buildBackupItemCard(_backups[i]),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildGoogleDriveCard() {
    final isConnected = GoogleDriveService.instance.isConnected;
    final email = GoogleDriveService.instance.connectedEmail;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isConnected ? AppColors.incomeGreen.withOpacity(0.4) : AppColors.accentGold.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_upload_rounded, color: AppColors.accentGold, size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('النسخ السحابي عبر Google Drive',
                    style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isConnected ? AppColors.incomeGreen.withOpacity(0.2) : AppColors.textMuted.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isConnected ? 'متصل وآمن' : 'غير متصل',
                  style: TextStyle(
                    color: isConnected ? AppColors.incomeGreen : AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isConnected
                ? 'مرتبط بالحساب: $email. يتم رفع النسخ الاحتياطية تلقائياً إلى مجلد STARS_HOMES_BACKUPS.'
                : 'يمكن ربط حساب Gmail الرسمي للمصنع لحفظ النسخ السحابية تلقائياً في Google Drive وحمايتها من فقدان الأجهزة.',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateBackupCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              foregroundColor: AppColors.primaryNavy,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: _isCreatingBackup
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryNavy),
                  )
                : const Icon(Icons.add_to_photos_rounded),
            label: Text(
              _isCreatingBackup ? 'جاري ضغط وإنشاء النسخة...' : 'إنشاء نسخة احتياطية فورية الآن',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            onPressed: _isCreatingBackup ? null : _handleCreateBackup,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الجدولة التلقائية:',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              DropdownButton<String>(
                value: _selectedSchedule,
                dropdownColor: AppColors.surfaceDark,
                style: const TextStyle(color: AppColors.accentGold, fontSize: 12),
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('يومياً في نهاية الدوام')),
                  DropdownMenuItem(value: 'weekly', child: Text('أسبوعياً (يوم الخميس)')),
                  DropdownMenuItem(value: 'none', child: Text('يدوي فقط')),
                ],
                onChanged: (val) {
                  setState(() => _selectedSchedule = val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackupItemCard(BackupRecordItem item) {
    Color badgeColor;
    if (item.backupType == 'before_restore') {
      badgeColor = AppColors.expenseRed;
    } else if (item.backupType == 'automatic') {
      badgeColor = AppColors.warningAmber;
    } else {
      badgeColor = AppColors.accentGold;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryNavy.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.filename,
                  style: const TextStyle(
                      color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(item.typeArabic,
                    style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('التاريخ: ${item.createdAt.toString().substring(0, 16)}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              const Spacer(),
              Text('الحجم: ${_formatBytes(item.fileSize)}',
                  style: const TextStyle(color: AppColors.accentGold, fontSize: 11)),
            ],
          ),
          const Divider(color: AppColors.backgroundDark, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentGold,
                  side: const BorderSide(color: AppColors.accentGold, width: 0.8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.verified_outlined, size: 14),
                label: const Text('فحص وسلامة', style: TextStyle(fontSize: 11)),
                onPressed: () => _handleVerifyBackup(item),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.incomeGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.restore_rounded, size: 14),
                label: const Text('استرجاع', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () => _handleRestoreBackup(item),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.expenseRed, size: 20),
                tooltip: 'حذف النسخة',
                onPressed: () => _handleDeleteBackup(item),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
