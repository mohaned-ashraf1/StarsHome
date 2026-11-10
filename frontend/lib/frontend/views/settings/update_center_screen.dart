import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stars_home/backend/services/update_service.dart';
import 'package:stars_home/frontend/constants/app_colors.dart';

class UpdateCenterScreen extends StatefulWidget {
  const UpdateCenterScreen({super.key});

  @override
  State<UpdateCenterScreen> createState() => _UpdateCenterScreenState();
}

class _UpdateCenterScreenState extends State<UpdateCenterScreen> {
  bool _isChecking = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  String? _errorMessage;
  UpdateInfo? _updateInfo;
  File? _downloadedFile;

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      final info = await UpdateService.instance.checkForUpdates();
      if (mounted) {
        setState(() {
          _updateInfo = info;
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'تعذر فحص التحديثات: $e';
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _startDownloadAndInstall() async {
    if (_updateInfo == null || _updateInfo!.downloadUrl == null) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      final file = await UpdateService.instance.downloadUpdate(
        _updateInfo!,
        onProgress: (progress, received, total) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
              _receivedBytes = received;
              _totalBytes = total;
            });
          }
        },
      );

      _downloadedFile = file;

      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }

      await _installUpdate(file);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = 'فشل تنزيل التحديث: $e';
        });
      }
    }
  }

  Future<void> _installUpdate(File file) async {
    try {
      await UpdateService.instance.installUpdate(file);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل فتح المثبت: $e';
        });
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 MB';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} ميجابايت';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('مركز التحديثات والتطوير'),
        backgroundColor: AppColors.primaryNavy,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'إعادة الفحص',
            onPressed: _isChecking || _isDownloading ? null : _checkForUpdates,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            _buildCurrentVersionCard(),
            const SizedBox(height: 18),

            if (_isChecking)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.accentGold),
                      SizedBox(height: 14),
                      Text('جاري فحص الإصدارات الجديدة عبر السحابة...',
                          style: TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              )
            else if (_errorMessage != null)
              _buildErrorCard()
            else if (_updateInfo != null)
              _buildUpdateDetailsCard(),

            const SizedBox(height: 24),
            _buildSafetyGuidelinesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentVersionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryNavy,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.system_update_alt_rounded,
                color: AppColors.accentGold, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('إصدار النظام المثبت حالياً',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  _updateInfo != null
                      ? 'الإصدار: ${_updateInfo!.currentDisplay}'
                      : 'STARS HOMES ERP v1.0.12+13',
                  style: const TextStyle(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                Text(
                  kIsWeb
                      ? 'المنصة: تطبيق الويب المتصفح'
                      : Platform.isAndroid
                          ? 'المنصة: هاتف أندرويد'
                          : 'المنصة: كمبيوتر ويندوز 11',
                  style: const TextStyle(color: AppColors.accentGold, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.expenseRed.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.expenseRed.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.expenseRed),
              const SizedBox(width: 8),
              const Text('تعذر فحص التحديثات',
                  style: TextStyle(
                      color: AppColors.expenseRed, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_errorMessage!,
              style: const TextStyle(color: AppColors.textWhite, fontSize: 12)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expenseRed, foregroundColor: Colors.white),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('إعادة المحاولة'),
            onPressed: _checkForUpdates,
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateDetailsCard() {
    final info = _updateInfo!;

    if (!info.hasUpdate) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.incomeGreen.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: AppColors.incomeGreen, size: 48),
            const SizedBox(height: 12),
            const Text('النظام محدث بالكامل!',
                style: TextStyle(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              'أنت تعمل على أحدث إصدار رسمي (${info.currentDisplay})، وكافة الميزات والتحسينات مفعلة على جهازك.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentGold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.new_releases_rounded,
                  color: AppColors.accentGold, size: 24),
              const SizedBox(width: 8),
              const Text('يتوفر إصدار رسمي جديد!',
                  style: TextStyle(
                      color: AppColors.accentGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'الإصدار المتوفر: ${info.latestDisplay}',
            style: const TextStyle(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
          if (info.assetSize > 0)
            Text(
              'حجم التحديث: ${_formatBytes(info.assetSize)}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          const SizedBox(height: 14),

          // Release Notes Box
          const Text('ما الجديد في هذا الإصدار:',
              style: TextStyle(
                  color: AppColors.accentGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              info.releaseNotes,
              style: const TextStyle(
                  color: AppColors.textWhite, fontSize: 12, height: 1.4),
            ),
          ),
          const SizedBox(height: 18),

          // Download Progress or Update Button
          if (_isDownloading)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('جاري تنزيل التحديث...',
                        style: TextStyle(
                            color: AppColors.accentGold, fontSize: 12)),
                    Text(
                      '${(_downloadProgress * 100).toStringAsFixed(0)}% (${_formatBytes(_receivedBytes)} / ${_formatBytes(_totalBytes)})',
                      style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _downloadProgress,
                    minHeight: 8,
                    backgroundColor: AppColors.backgroundDark,
                    color: AppColors.accentGold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'سيتم التحقق من بصمة SHA-256 وفتح المثبت تلقائياً فور اكتمال التنزيل.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            )
          else if (_downloadedFile != null)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.incomeGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.install_mobile_rounded, color: Colors.white),
              label: const Text('تثبيت التحديث الآن',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              onPressed: () => _installUpdate(_downloadedFile!),
            )
          else
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                foregroundColor: AppColors.primaryNavy,
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.cloud_download_rounded),
              label: const Text('تحميل وتثبيت التحديث الآن',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              onPressed: _startDownloadAndInstall,
            ),
        ],
      ),
    );
  }

  Widget _buildSafetyGuidelinesCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppColors.accentGold, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'حماية البيانات المحلية: عند التحديث، تبقى كافة بيانات المصنع المحفوظة محلياً وعمليات المزامنة المعلقة آمنة وسليمة 100%، ولا يتم حذف أي سجل من الهاتف أو الكمبيوتر.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
